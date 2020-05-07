FROM python:3.6-slim-buster

RUN python -m pip install --upgrade pip
COPY app/requirements.txt .
RUN pip install -r requirements.txt

COPY . /main
WORKDIR /main/app

CMD ["gunicorn", "--bind", ":8080", "--workers", "5", "ml-app:app"]