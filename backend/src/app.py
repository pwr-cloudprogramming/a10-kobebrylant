from flask import Flask, request, jsonify
from flask_cors import CORS
import random
import boto3
from jose import jwt, JWTError
import os
import requests
from functools import wraps
from jose.backends.rsa_backend import RSAKey


app = Flask(__name__)
CORS(app, supports_credentials=True, allow_headers=[
    'Content-Type', 'Authorization', 'X-Requested-With', 'Origin'])

# Configurations
COGNITO_REGION = os.getenv('COGNITO_REGION', 'us-east-1')
USER_POOL_ID = os.getenv('COGNITO_USER_POOL_ID', 'not-set')
APP_CLIENT_ID = os.getenv('COGNITO_CLIENT_ID', 'not-set')

# AWS Cognito client
cognito_client = boto3.client('cognito-idp', region_name=COGNITO_REGION)

# Games data store
games = {}

# Utility function to check the winner
def check_winner(board, usernames):
    winning_combinations = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],
        [0, 3, 6], [1, 4, 7], [2, 5, 8],
        [0, 4, 8], [2, 4, 6]
    ]
    for combo in winning_combinations:
        if board[combo[0]] and board[combo[0]] == board[combo[1]] == board[combo[2]]:
            return board[combo[0]]
    return None

def authenticate_token(token):
    try:
        # Decode JWT token
        print(f"Token: {token}")
        print(f"Region: {COGNITO_REGION}")
        print(f"User Pool ID: {USER_POOL_ID}")
        print(f"Client ID: {APP_CLIENT_ID}")
        header = jwt.get_unverified_headers(token)
        kid = header['kid']
        keys_url = f'https://cognito-idp.{COGNITO_REGION}.amazonaws.com/{USER_POOL_ID}/.well-known/jwks.json'
        response = requests.get(keys_url)
        keys = response.json()['keys']

        # Find the key that matches the kid
        key = next(k for k in keys if k['kid'] == kid)

        # Convert JWK to PEM format key
        public_key = RSAKey(key, algorithm='RS256')

        # Decode the token using the public key
        claims = jwt.decode(token, public_key, algorithms=['RS256'], audience=APP_CLIENT_ID)
        return claims
    except JWTError as e:
        print(f"JWTError: {e}")
        return None
    except Exception as e:
        print(f"Error: {e}")
        return None

# Decorator to require authentication
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        token = request.headers.get('Authorization')
        print(f"Token login: {token}")
        if token:
            token = token.replace('Bearer ', '')
            claims = authenticate_token(token)
            print(f"Claims: {claims}")
            if claims:
                request.user = claims
                return f(*args, **kwargs)
        return jsonify({'error': 'Unauthorized'}), 401
    return decorated_function

@app.route('/protected', methods=['GET'])
@login_required
def protected():
    return jsonify({'message': f'Hello, {request.user["username"]}! You are authenticated.'})

@app.route('/start', methods=['POST'])
@login_required
def start_game():
    data = request.get_json()
    username = data.get('username')
    game_id = str(random.randint(1000, 9999))
    games[game_id] = {
        'board': [None] * 9,
        'currentPlayer': 'X',
        'winner': None,
        'usernames': {'X': username, 'O': None},
        'game_id': game_id,
        'gameEnded': False
    }
    return jsonify({
        'message': 'Game started, waiting for Player2 to join',
        'game_id': game_id
    })

@app.route('/join', methods=['POST'])
@login_required
def join_game():
    data = request.get_json()
    game_id = data['game_id']
    username = data['username']
    if game_id in games and not games[game_id]['usernames']['O']:
        games[game_id]['usernames']['O'] = username
        return jsonify({
            'message': 'Player2 joined the game',
            'game_id': game_id
        })
    else:
        return jsonify({'error': 'Game not found or already full'}), 404

@app.route('/game/<game_id>', methods=['GET'])
@login_required
def get_game_state(game_id):
    game = games.get(game_id)
    if game is None:
        return jsonify({'error': 'Game not found'}), 404
    return jsonify({
        'board': game['board'],
        'currentPlayer': game['currentPlayer'],
        'winner': game['winner'],
        'game_id': game_id,
        'usernames': game['usernames'],
        'gameEnded': game['gameEnded']
    })

@app.route('/play', methods=['POST'])
@login_required
def play():
    data = request.get_json()
    username = data['username']
    game_id = data['game_id']
    move = data['move']

    if game_id not in games:
        return jsonify({'error': 'Game not found'}), 404

    game = games[game_id]
    if None in game['usernames'].values():
        return jsonify({'error': 'Waiting for all players to join'}), 403

    if username != game['usernames'][game['currentPlayer']]:
        return jsonify({'error': 'Not your turn'}), 403

    board = game['board']
    if board[move] is None:
        board[move] = game['currentPlayer']
        game['currentPlayer'] = 'O' if game['currentPlayer'] == 'X' else 'X'
        winner = check_winner(board, game['usernames'])
        if winner:
            game['winner'] = game['usernames'][winner]
            game['gameEnded'] = True
        return jsonify({'board': board, 'winner': game['winner'], 'currentPlayer': game['currentPlayer'], 'game_id': game_id})

    else:
        return jsonify({'error': 'Invalid move'}), 400

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8080)
