# Machine Learning model deployment pipeline in GKE

_João Araujo, May 08, 2020_ 

It's important to update your model as soon as you have new data coming to your organization. Create a pipeline to update this model is not so difficult when you have full access to your data, but deploy it is not so simple. We have lot's of possibilities to do it and in this project I'll show how easy is to create a deployment pipeline in GKE using Google Cloud  Platform.

First, we need to bind a role to the Google Cloud Build service account as a Kubernetes Engine Developer. We can do this in point'n'click in the settings of Cloud Build or through terminal using [Google Cloud SDK](https://cloud.google.com/sdk/install) (local or in [cloud shell interface](https://ssh.cloud.google.com/cloudshell/)):

```bash
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='get(projectNumber)')

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member "serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com" \
  --role "roles/container.developer"
```

Be sure that you have `kubectl` installed in you machine. `kubectl`is a command line tool for controlling *Kubernetes* clusters. If you don't, please read the installation guide [[1]](#L1). I recommend you to install `kubectl`via [Homebrew](https://docs.brew.sh/Homebrew-on-Linux).

Now, we create our Kubernetes cluster in GKE using this simple command:

```bash
# define main values
_CLUSTER=ml-cluster        # name
_N_NODES=1                 # size
_ZONE=southamerica-east1-b # zonal cluster
_MACHINE_TYPE=n1-highmem-2 # 2 vCPUs and 13GB vRAM

# create a cluster with this specifications
gcloud container clusters create $_CLUSTER \
    --num-nodes $_N_NODES \
    --machine-type $_MACHINE_TYPE \
    --zone $_ZONE
```

To check if everything is up you can use the command `kubectl get all`. To be more specific, I like to use `kubectl get nodes,pods,svc`.

## Project tree

```
...
```

## Toy problem & the model entity

In this article, I used the scikit-learn [Boston data set](https://scikit-learn.org/stable/datasets/index.html#boston-house-prices-dataset) to create my ML model. It is a regression of a continuous target variable, namely, price. To make it even simpler, I trained a [Linear Regression](https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LinearRegression.html) model that also belongs to the scikit-learn package, but I could choose any other model (XGBoost, LightGBM, ...).

The folder named `train` contains a Python file, `boston_problem.py`, that loads the dataset, saves a JSON file (`example.json`) for test and saves the scikit-learn model object into a Pickle file (`ml-model.pkl`). Here is the most important part of the code: 

 ```python
X.sample(1, random_state=0).iloc[0].to_json('example.json')
model = LinearRegression()
model.fit(X, y)
with open('ml-model.pkl', 'wb') as f:
    pickle.dump(model, f)
 ```

This is a very simple example of how to train a model and make it portable through the Pickle package object serialization. Whatever you go &mdash; for cloud or other computers &mdash;, if you have the same scikit-learn and Python version, you will load this Pickle file and get the same object of when it was saved.

Notice that in the `boston_problem.py` I put a command that prints the columns of my dataset. It's important because the order of columns matter in almost every algorithm of ML. I used the output of this command in my Flask application to eliminate possible mistakes.

## Flask application

If you don't know anything about Flask, I recommend you to read the Todd Birchard articles [[2]](#L2).

The `app` folder contains two files: `ml-model.pkl`, the object that contains my exact created and trained model; and`ml-app.py`, the application itself.

In `ml-app.py` I read the `.pkl` using the Pickle package:

```python
with open('ml-model.pkl', 'rb') as f:
    MODEL = pickle.load(f)
```

After that, I created a variable that I named `app` and it's a Flask object. This object has a [decorator](https://www.datacamp.com/community/tutorials/decorators-python) called `route` that exposes my functions to the web framework in a given URL pattern, e.g., _myapp.com:8080_**/** and _myapp.com:8080_**/predict** has `"/"` and `"/predict"` as routes, respectively. This decorator gives the option to choose the request method of this route. There are two main methods that can be simply described as follows:

- GET: to retrieve an information (message);
- POST: to receive an information and return the task result (another information/message);

I created one function for each method. The first is a message to know that the application is alive:

```python
@app.route('/', methods=['GET'])
def server_check():
    return "I'M ALIVE!"
```

And the second is my model prediction function:

```python
@app.route('/predict', methods=['POST'])
def predictor():
    content = request.json
    # <...>
```

Remember that I said that for almost every algorithm the column order is important? I made a `try`/`except` to guarantee that:

```python
    try:
        features = pd.DataFrame([content])
        features = features[FEATURES_MASK]
    except:
        logging.exception("The JSON file was broke.")
        return jsonify(status='error', predict=-1)
```

The last two command lines of the `ml-app.py` file runs the application into the IP `0.0.0.0` (localhost).

```python
if __name__=='__main__':
    app.run( debug=True, host='0.0.0.0' )
```

The conditional statement `__name__=='__main__'` is because I just want to run my application if I am executing the file `ml-app.py`. 

## Dockerfile

If you don't know what is Docker or Dockerfile, I recommend you to read these articles, Docker documentation [[3]](#L3) and  my last project article section Docker & Dockerfile [[4]](#L4).

This is the Dockerfile of this project:

```dockerfile
# a small operating system
FROM python:3.6-slim-buster
# layers to install dependencies (less prone to changes)
RUN python -m pip install --upgrade pip
COPY app/requirements.txt .
RUN pip install -r requirements.txt
# layers to copy all files (more prone to changes)
COPY . /main
# change to the application directory to execute `gunicorn`
WORKDIR /main/app
# starts application with 5 workers
CMD ["gunicorn", "--bind", ":8080", "--workers", "5", "ml-app:app"]
```

I choose a small operating system to build images faster and put the less prone to changes layers in the beginning. In the `requirements.txt` have the necessary packages and its respective versions to execute my application.

`gunicorn` is a lightweight WSGI HTTP server that is commonly used in production deployments. It has the capability to do some kind of load balancing creating replicas of the application's process in the container OS. This is very useful in scenarios where we have lots of simultaneous requests or when our application may fail. In the last scenario, `gunicorn`will kill and replace the failed process.

The `--bind` argument is to set the container address of the application, in this case, in the localhost in port 8080. The `--workers` is to set the number of replicas of the application's process. A recommended number of workers is `2*cores + 1`. The `ml-app:app` means that the object of our application is in `ml-app.py` and its name is `app`.

## Continuous Integration

In my previous project in GitHub, I described how to set a Google Cloud Build trigger to a GitHub repository. Please go to Git Repo section in this project to see how to do it [[4]](#L4).

## References

<a name="L1">[1]</a> Kubernetes Documentation, ["Install and Set Up kubectl"](https://kubernetes.io/docs/tasks/tools/install-kubectl/). _(visited in May 8, 2020)_

<a name="L2">[2]</a> Todd Birchard, ["Building a Python App in Flask"](https://hackersandslackers.com/your-first-flask-application/). July, 2008. _(visited in April 20, 2020)_

<a name="L3">[3]</a> Docker Documentation, ["Docker overview"](https://docs.docker.com/get-started/overview/). _(visited in May 8, 2020)_

<a name="L4">[4]</a> João Araujo, ["Machine Learning deployment pipeline on Google Cloud Run"](https://github.com/jgvaraujo/ml-deployment-on-gcloud#docker--dockerfile). _(visited May 8, 2020)