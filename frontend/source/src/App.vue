<template>
  <div class="app">
    <div v-if="!accessToken" class="auth-forms">
      <register-component @registered="handleRegistration" />
      <login-component @login="handleLogin" />
    </div>

    <div v-if="accessToken && !gameId" class="username">
      <h1>Tic Tac Toe</h1>
      <input v-model="username" class="input" placeholder="Enter your username" />
      <div @click="createGame" class="start-button">Create Game</div>
      <input v-model="joiningGameId" class="input" placeholder="Enter game ID to join" />
      <div @click="joinGame" class="start-button">Join Game</div>
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

<script>
import axios from 'axios';
import RegisterComponent from './components/Register.vue';
import LoginComponent from './components/Login.vue';

export default {
  components: {
    'register-component': RegisterComponent,
    'login-component': LoginComponent
  },
  data() {
    return {
      accessToken: localStorage.getItem('accessToken') || null,
      username: '',
      gameId: null,
      joiningGameId: '',
      board: Array(9).fill(null),
      winner: null,
      currentPlayer: '',
      currentSign: 'X',
      hoverIndex: null,
      bothPlayersJoined: false,
      apiUrl: process.env.VUE_APP_API_URL || 'http://localhost:8080',
    };
  },
  methods: {
    handleLogin(token) {
      this.accessToken = token;
    },
    handleRegistration() {
      alert('Registration successful! Please login to continue.');
    },
    async fetchGameState() {
      if (!this.gameId) return;
      try {
        const response = await axios.get(`${this.apiUrl}/game/${this.gameId}`, {
          headers: {
            Authorization: `Bearer ${this.accessToken}`
          }
        });
        this.board = response.data.board;
        this.currentPlayer = response.data.usernames[response.data.currentPlayer];
        this.currentSign = response.data.currentPlayer === 'X' ? 'X' : 'O';
        this.bothPlayersJoined = response.data.usernames['X'] && response.data.usernames['O'];
        this.winner = response.data.winner;

        if (response.data.gameEnded) {
          if (this.gameStateInterval) {
            clearInterval(this.gameStateInterval);
            this.gameStateInterval = null;
          }
        }
      } catch (error) {
        console.error(error);
      }
    },
    async createGame() {
      try {
        const response = await axios.post(`${this.apiUrl}/start`, {
          username: this.username
        }, {
          headers: {
            Authorization: `Bearer ${this.accessToken}`
          }
        });
        this.gameId = response.data.game_id;
        this.fetchGameState();
      } catch (error) {
        console.error(error);
      }
    },
    async joinGame() {
      try {
        await axios.post(`${this.apiUrl}/join`, {
          game_id: this.joiningGameId,
          username: this.username
        }, {
          headers: {
            Authorization: `Bearer ${this.accessToken}`
          }
        });
        this.gameId = this.joiningGameId;
        this.fetchGameState();
      } catch (error) {
        console.error(error);
      }
    },
    async makeMove(index) {
      if (this.username === this.currentPlayer && !this.board[index] && !this.winner) {
        try {
          const response = await axios.post(`${this.apiUrl}/play`, {
            game_id: this.gameId,
            move: index,
            username: this.username,
          }, {
            headers: {
              Authorization: `Bearer ${this.accessToken}`
            }
          });
          this.board = response.data.board;
          this.winner = response.data.winner;
          this.currentPlayer = response.data.usernames[response.data.currentPlayer];
        } catch (error) {
          console.error(error);
        }
      }
    },
    resetGame() {
      this.username = '';
      this.gameId = null;
      this.joiningGameId = '';
      this.board = Array(9).fill(null);
      this.winner = null;
      this.currentPlayer = '';
      this.currentSign = 'X';
      this.bothPlayersJoined = false;

      if (this.gameStateInterval) {
        clearInterval(this.gameStateInterval);
      }
      this.gameStateInterval = setInterval(this.fetchGameState, 1000);
    },

    hoverCell(index) {
      if (!this.winner) {
        this.hoverIndex = index;
      }
    },
  },
  mounted() {
    this.fetchGameState();
    this.gameStateInterval = setInterval(this.fetchGameState, 200);
  },

  beforeUnmount() {
    if (this.gameStateInterval) {
      clearInterval(this.gameStateInterval);
    }
  },
};
</script>

<style>
.html, body {
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
</style>
