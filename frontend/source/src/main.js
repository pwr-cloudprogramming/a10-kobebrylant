import { createApp } from 'vue';
import App from './App.vue';
import Amplify from 'aws-amplify';

Amplify.configure({
    Auth: {
        region: process.env.VUE_APP_COGNITO_REGION,
        userPoolId: process.env.VUE_APP_USER_POOL_ID,
        userPoolWebClientId: process.env.VUE_APP_USER_POOL_CLIENT_ID,
    }
});

const wsProtocol = window.location.protocol === 'https:' ? 'wss' : 'ws';
const apiUrl = process.env.VUE_APP_API_URL || 'http://localhost:8080';
const wsUrl = `${wsProtocol}://${apiUrl.split('//')[1]}`;
const socket = new WebSocket(wsUrl);

const app = createApp(App);

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

app.provide('socket', socket);
app.mount('#app');
