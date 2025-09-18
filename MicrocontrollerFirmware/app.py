from flask import Flask, jsonify
import os
app = Flask(__name__)
PORT = int(os.getenv('MC_FW_PORT', '5000'))
@app.route('/')
def index():
    return jsonify({"status":"ok","port":PORT})
if __name__ == '__main__':
    # bind 0.0.0.0 so service is reachable inside container; tests poll 127.0.0.1
    app.run(host='0.0.0.0', port=PORT)
