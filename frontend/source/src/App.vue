<template>
  <div class="app">
    <div v-if="!accessToken" class="auth-forms">
      <RegisterComponent />
      <LoginComponent />
    </div>
    <div v-if="accessToken && !gameId" class="username">
      <h1>Tic Tac Toe</h1>
      <input v-model="username" class="input" placeholder="Enter your username" />
      <div @click="createGame" class="start-button">Create Game</div>
      <input v-model="joiningGameId" class="input" placeholder="Enter game ID to join" />
      <div @click="joinGame" class="start-button">Join Game</div>
      <button @click="logout" class="logout-button">Logout</button>
    </div>
    <div v-if="gameId && !bothPlayersJoined" class="waiting">
      Waiting for another player to join...
      Game ID: {{ gameId }}
    </div>
    <div v-else-if="gameId && bothPlayersJoined" class="game">
      <div class="player-turn">{{ currentPlayer }}'s turn</div>
      <div class="game-info">
        Game ID: {{ gameId }} (Share this ID with another player to join)
      </div>
      <div class="board">
        <div
            class="cell"
            v-for="(cell, index) in board"
            :key="index"
            @click="makeMove(index)"
            @mouseover="hoverCell(index)"
        >
          {{ cell ? cell : hoverIndex === index ? currentSign : '' }}
        </div>
      </div>
      <div v-if="winner" class="winner">
        Winner: {{ winner }}
        <div @click="resetGame" class="start-button">Play Again</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue';
import axios from 'axios';
import RegisterComponent from '../components/RegisterComponent.vue';
import LoginComponent from '../components/LoginComponent.vue';
import { fetchAuthSession, signOut } from 'aws-amplify/auth';

const accessToken = ref(localStorage.getItem('accessToken') || null);
const refreshToken = ref(localStorage.getItem('refreshToken') || null);
const username = ref('');
const gameId = ref(null);
const joiningGameId = ref('');
const board = ref(Array(9).fill(null));
const winner = ref(null);
const currentPlayer = ref('');
const currentSign = ref('X');
const hoverIndex = ref(null);
const bothPlayersJoined = ref(false);
const apiUrl = process.env.VUE_APP_API_URL || 'http://localhost:8080';

let gameStateInterval = null;

const fetchGameState = async () => {
  if (!gameId.value) return;
  try {
    const response = await axios.get(`${apiUrl}/game/${gameId.value}`, {
      headers: {
        Authorization: `Bearer ${accessToken.value}`
      }
    });
    board.value = response.data.board;
    currentPlayer.value = response.data.usernames[response.data.currentPlayer];
    currentSign.value = response.data.currentPlayer === 'X' ? 'X' : 'O';
    bothPlayersJoined.value = response.data.usernames['X'] && response.data.usernames['O'];
    winner.value = response.data.winner;

    if (response.data.gameEnded) {
      if (gameStateInterval) {
        clearInterval(gameStateInterval);
        gameStateInterval = null;
      }
    }
  } catch (error) {
    console.error(error);
  }
};

const createGame = async () => {
  try {
    const response = await axios.post(`${apiUrl}/start`, {
      username: username.value
    }, {
      headers: {
        Authorization: `Bearer ${accessToken.value}`
      }
    });
    gameId.value = response.data.game_id;
    fetchGameState();
  } catch (error) {
    console.error(error);
  }
};

const joinGame = async () => {
  try {
    await axios.post(`${apiUrl}/join`, {
      game_id: joiningGameId.value,
      username: username.value
    }, {
      headers: {
        Authorization: `Bearer ${accessToken.value}`
      }
    });
    gameId.value = joiningGameId.value;
    fetchGameState();
  } catch (error) {
    console.error(error);
  }
};

const makeMove = async (index) => {
  if (username.value === currentPlayer.value && !board.value[index] && !winner.value) {
    try {
      const response = await axios.post(`${apiUrl}/play`, {
        game_id: gameId.value,
        move: index,
        username: username.value,
      }, {
        headers: {
          Authorization: `Bearer ${accessToken.value}`
        }
      });
      board.value = response.data.board;
      winner.value = response.data.winner;
      currentPlayer.value = response.data.usernames[response.data.currentPlayer];
    } catch (error) {
      console.error(error);
    }
  }
};

const resetGame = () => {
  username.value = '';
  gameId.value = null;
  joiningGameId.value = '';
  board.value = Array(9).fill(null);
  winner.value = null;
  currentPlayer.value = '';
  currentSign.value = 'X';
  bothPlayersJoined.value = false;

  if (gameStateInterval) {
    clearInterval(gameStateInterval);
  }
  gameStateInterval = setInterval(fetchGameState, 1000);
};

const hoverCell = (index) => {
  if (!winner.value) {
    hoverIndex.value = index;
  }
};

const refreshAccessToken = async () => {
  try {
    const session = await fetchAuthSession();
    const newAccessToken = session.tokens.accessToken;
    accessToken.value = newAccessToken;
    localStorage.setItem('accessToken', newAccessToken);
  } catch (error) {
    console.error('Error refreshing access token', error);
  }
};

const logout = () => {
    signOut().then(() => {
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    accessToken.value = null;
    refreshToken.value = null;
    alert('Logged out successfully!');
    window.location.reload(); // Reload to update the state in App.vue
  }).catch(error => {
    console.error('Error during logout', error);
  });
};

onMounted(async () => {
  if (refreshToken.value) {
    await refreshAccessToken();
  }
  fetchGameState();
  gameStateInterval = setInterval(fetchGameState, 200);
});

onBeforeUnmount(() => {
  if (gameStateInterval) {
    clearInterval(gameStateInterval);
  }
});
</script>

<style>
html, body {
  margin: 0;
  padding: 0;
  font-family: Arial, sans-serif;
  color: #D0BDF4;
}

.app {
  background-color: #494D5F;
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 0;
  margin: 0;
  width: 100vw;
  height: 100vh;
}

.auth-forms {
  display: flex;
  flex-direction: column;
  gap: 20px;
  align-items: center;
}

.username {
  margin-bottom: 10px;
  display: flex;
  flex-direction: column;
  gap: 20px;
  width: 15vw;
  justify-content: center;
  align-items: center;
}

.board {
  display: grid;
  grid-template-columns: repeat(3, 100px);
  grid-template-rows: repeat(3, 100px);
  gap: 10px;
  justify-content: center;
  margin: auto;
}

.cell {
  width: 100px;
  height: 100px;
  background-color: #f0f0f0;
  display: flex;
  justify-content: center;
  align-items: center;
  font-size: 2em;
  cursor: pointer;
}

.player-turn {
  margin-bottom: 30px;
  font-size: 1.5em;
}

.winner {
  margin-top: 10px;
  font-size: 1.5em;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
}

.game {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-top: 30px;
  margin-bottom: 30px;
}

.input {
  width: 100%;
  padding: 10px;
  font-size: 1em;
  border: none;
  border-radius: 5px;
  background-color: #f0f0f0;
  color: #494D5F;
  width: 100%;
}

.start-button {
  width: 15vw;
  padding: 10px;
  background-color: #A0D2EB;
  border-radius: 10px;
  text-align: center;
  color: #494D5F;
  margin-top: 15px;
}

.logout-button {
  margin-top: 20px;
  padding: 10px;
  background-color: #ff6f61;
  border-radius: 10px;
  text-align: center;
  color: #fff;
  cursor: pointer;
}
</style>
