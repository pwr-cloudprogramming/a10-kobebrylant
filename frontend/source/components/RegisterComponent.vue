<template>
  <div class="register">
    <h2>Register</h2>
    <input v-model="username" placeholder="Username" class="input"/>
    <input v-model="email" type="email" placeholder="Email" class="input"/>
    <input v-model="password" type="password" placeholder="Password" class="input"/>
    <button @click="register" class="start-button">Register</button>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { signUp } from "aws-amplify/auth"

const username = ref('');
const email = ref('');
const password = ref('');

const register = async () => {
  try {
    await signUp({
      username: username.value,
      password: password.value,
      attributes: {
        email: email.value,
      },
    });
    alert('Registration successful! Please check your email to confirm your account.');
  } catch (error) {
    console.error('Error during registration', error);
    alert('Error during registration');
  }
};
</script>

<style scoped>
/* Add your styles here */
</style>
