from flask import Flask, request, jsonify

import pandas as pd
import pickle
import logging
from datetime import datetime

with open('ml-model.pkl', 'rb') as f:
    MODEL = pickle.load(f)

FEATURES_MASK = ['CRIM', 'ZN', 'INDUS', 'CHAS', 'NOX', 'RM', 'AGE', 'DIS',
                 'RAD', 'TAX', 'PTRATIO', 'B', 'LSTAT']

app = Flask(__name__)


@app.route('/check', methods=['GET'])
def server_check():
    now = datetime.now().strftime('%d/%b/%Y - %H:%M:%S.%f\n')
    return "I'M ALIVE! - " + now.upper()


@app.route('/predict', methods=['POST'])
def predictor():
    content = request.json

    try:
        features = pd.DataFrame([content])
        features = features[FEATURES_MASK]
    except:
        logging.exception("The JSON file was broke.")
        return jsonify(status='error', predict=-1)

    pred = MODEL.predict(features)[0]

    return jsonify(status='ok', predict=pred)


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
