from flask import Flask, jsonify
import os
from datetime import datetime

app = Flask(__name__)

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint for Kubernetes liveness probe"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'version': '1.0.0'
    }), 200

@app.route('/readiness', methods=['GET'])
def readiness():
    """Readiness check endpoint for Kubernetes readiness probe"""
    return jsonify({
        'ready': True,
        'timestamp': datetime.utcnow().isoformat()
    }), 200

@app.route('/api/v1/status', methods=['GET'])
def status():
    """API endpoint returning system status"""
    return jsonify({
        'service': 'Azure K8s CI/CD Demo',
        'status': 'running',
        'environment': os.getenv('ENVIRONMENT', 'development'),
        'timestamp': datetime.utcnow().isoformat(),
        'version': '1.0.0'
    }), 200

@app.route('/', methods=['GET'])
def index():
    """Welcome endpoint"""
    return jsonify({
        'message': 'Welcome to Azure K8s CI/CD Demo',
        'description': 'A simple Flask app deployed via CI/CD pipeline to Kubernetes',
        'endpoints': {
            'health': '/health',
            'readiness': '/readiness',
            'status': '/api/v1/status'
        }
    }), 200

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
