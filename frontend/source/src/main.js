import { createApp } from 'vue';
import App from './App.vue';

const wsProtocol = window.location.protocol === 'https:' ? 'wss' : 'ws';

const apiUrl = process.env.VUE_APP_API_URL || 'http://localhost:8080';
const wsUrl = `${wsProtocol}://${apiUrl.split('//')[1]}`;

const socket = new WebSocket(wsUrl);

console.log('Cognito User Pool ID:', process.env.VUE_APP_COGNITO_USER_POOL_ID);
console.log('Cognito Client ID:', process.env.VUE_APP_COGNITO_CLIENT_ID);
console.log('Cognito Region:', process.env.VUE_APP_COGNITO_REGION);
console.log('API URL:', process.env.VUE_APP_API_URL);

socket.onopen = () => {
    console.log('WebSocket Connection Opened');
    socket.send('Hello Server!');
};

socket.onerror = (error) => {
    console.error('WebSocket Error:', error);
};

socket.onmessage = (event) => {
    console.log('WebSocket Message:', event.data);
};

const app = createApp(App);

app.provide('socket', socket);

app.mount('#app');
