from flask import Flask, request, jsonify
from flask_cors import CORS
import random
import boto3
from botocore.exceptions import ClientError
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity
import os

app = Flask(__name__)
CORS(app)

# Configure JWT
app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'default_jwt_secret')
jwt = JWTManager(app)

# Cognito configuration
USER_POOL_ID = os.getenv('USER_POOL_ID')
APP_CLIENT_ID = os.getenv('APP_CLIENT_ID')
COGNITO_REGION = os.getenv('COGNITO_REGION', 'us-east-1')

cognito_client = boto3.client('cognito-idp', region_name=COGNITO_REGION)

games = {}

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

@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    username = data['username']
    password = data['password']
    email = data['email']

    try:
        response = cognito_client.sign_up(
            ClientId=APP_CLIENT_ID,
            Username=username,
            Password=password,
            UserAttributes=[
                {'Name': 'email', 'Value': email}
            ]
        )
        return jsonify({'message': 'User registered successfully'}), 200
    except ClientError as e:
        return jsonify({'error': str(e)}), 400

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data['username']
    password = data['password']

    try:
        response = cognito_client.initiate_auth(
            ClientId=APP_CLIENT_ID,
            AuthFlow='USER_PASSWORD_AUTH',
            AuthParameters={
                'USERNAME': username,
                'PASSWORD': password,
            }
        )
        access_token = response['AuthenticationResult']['AccessToken']
        return jsonify(access_token=access_token), 200
    except ClientError as e:
        return jsonify({'error': str(e)}), 400

@app.route('/start', methods=['POST'])
@jwt_required()
def start_game():
    current_user = get_jwt_identity()
    game_id = str(random.randint(1000, 9999))
    games[game_id] = {
        'board': [None] * 9,
        'currentPlayer': 'X',
        'winner': None,
        'usernames': {'X': current_user, 'O': None},
        'game_id': game_id,
        'gameEnded': False
    }
    return jsonify({
        'message': 'Game started, waiting for Player2 to join',
        'game_id': game_id
    })

@app.route('/join', methods=['POST'])
@jwt_required()
def join_game():
    current_user = get_jwt_identity()
    data = request.get_json()
    game_id = data['game_id']
    
    if game_id in games and not games[game_id]['usernames']['O']:
        games[game_id]['usernames']['O'] = current_user
        return jsonify({
            'message': 'Player2 joined the game',
            'game_id': game_id
        })
    else:
        return jsonify({'error': 'Game not found or already full'}), 404

@app.route('/game/<game_id>', methods=['GET'])
@jwt_required()
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
@jwt_required()
def play():
    current_user = get_jwt_identity()
    data = request.get_json()
    game_id = data['game_id']
    move = data['move']

    if game_id not in games:
        return jsonify({'error': 'Game not found'}), 404

    game = games[game_id]
    if None in game['usernames'].values():
        return jsonify({'error': 'Waiting for all players to join'}), 403

    if current_user != game['usernames'][game['currentPlayer']]:
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
