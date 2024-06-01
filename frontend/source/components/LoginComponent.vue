<template>
  <div class="login">
    <h2>Login</h2>
    <input v-model="username" placeholder="Username" class="input"/>
    <input v-model="password" type="password" placeholder="Password" class="input"/>
    <button @click="login" class="start-button">Login</button>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { signIn } from 'aws-amplify/auth';

const username = ref('');
const password = ref('');

const login = async () => {
  try {
    const user = await signIn(
        {
          username: username.value,
          password: password.value
        }
    );
    const { accessToken, refreshToken } = user.signInUserSession;
    localStorage.setItem('accessToken', accessToken.jwtToken);
    localStorage.setItem('refreshToken', refreshToken.token);
    alert('Login successful!');
    window.location.reload(); // Reload to update the state in App.vue
  } catch (error) {
    console.error('Error during login', error);
    alert('Error during login');
  }
};
</script>

<style scoped>
/* Add your styles here */
</style>
