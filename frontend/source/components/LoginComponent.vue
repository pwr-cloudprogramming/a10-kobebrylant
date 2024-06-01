<template>
  <div class="login">
    <h2>Login</h2>
    <input v-model="username" placeholder="Username" class="input"/>
    <input v-model="password" type="password" placeholder="Password" class="input"/>
    <button @click="login" class="start-button">Login</button>
    <p>Don't have an account? <span @click="switchToRegister" class="link">Register</span></p>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { signIn } from 'aws-amplify/auth';

import { fetchAuthSession } from 'aws-amplify/auth';

const session = await fetchAuthSession();

console.log("id token", session.tokens.idToken)
console.log("access token", session.tokens.accessToken)

const username = ref('');
const password = ref('');
// eslint-disable-next-line
const emit = defineEmits(['switch-view', 'login-success']);

const login = async () => {
  try {
    await signIn({
      username: username.value,
      password: password.value
    });
    localStorage.setItem('accessToken', session.tokens.accessToken);
    localStorage.setItem('idToken', session.tokens.idToken);
    alert('Login successful!');
    emit('login-success');
  } catch (error) {
    console.error('Error during login', error);
    alert('Error during login');
  }
};

const switchToRegister = () => {
  emit('switch-view', 'register');
};
</script>

<style scoped>
/* Add your styles here */
</style>
