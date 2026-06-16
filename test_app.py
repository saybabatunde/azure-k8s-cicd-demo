import pytest
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_index(client):
    response = client.get('/')
    assert response.status_code == 200
    assert 'message' in response.json
    assert response.json['message'] == 'Welcome to Azure K8s CI/CD Demo'

def test_health(client):
    response = client.get('/health')
    assert response.status_code == 200
    assert response.json['status'] == 'healthy'
    assert 'timestamp' in response.json

def test_readiness(client):
    response = client.get('/readiness')
    assert response.status_code == 200
    assert response.json['ready'] == True

def test_status(client):
    response = client.get('/api/v1/status')
    assert response.status_code == 200
    assert response.json['service'] == 'Azure K8s CI/CD Demo'
    assert response.json['status'] == 'running'
