import { createApp } from 'vue';
import App from './App.vue';
import { Amplify } from 'aws-amplify';
// import awsExports  from "../aws-exports";


// Amplify.configure(awsExports);

Amplify.configure({
    Auth: {
        Cognito: {
            userPoolClientId: process.env.VUE_APP_COGNITO_CLIENT_ID,
            userPoolId: process.env.VUE_APP_COGNITO_USER_POOL_ID,
            region: process.env.VUE_APP_COGNITO_REGION,
        }
    }
});
const wsProtocol = window.location.protocol === 'https:' ? 'wss' : 'ws';

const apiUrl = process.env.VUE_APP_API_URL || 'http://localhost:8080';
const wsUrl = `${wsProtocol}://${apiUrl.split('//')[1]}`;

const socket = new WebSocket(wsUrl);


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
