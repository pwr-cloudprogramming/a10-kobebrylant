<template>
  <div class="register">
    <h2>Register</h2>
    <input v-model="username" placeholder="Username" class="input"/>
    <input v-model="email" type="email" placeholder="Email" class="input"/>
    <input v-model="password" type="password" placeholder="Password" class="input"/>
    <input v-model="repeatPassword" type="password" placeholder="Repeat Password" class="input"/>
    <button @click="register" class="start-button">Register</button>
    <p>Already have an account? <span @click="switchToLogin" class="link">Login</span></p>
  </div>
</template>

<script setup>
import {ref} from 'vue';
import {signUp} from "aws-amplify/auth";

// eslint-disable-next-line
const emit = defineEmits(['switch-view']);

const username = ref('');
const email = ref('');
const password = ref('');
const repeatPassword = ref('');

const register = async () => {
  if (password.value !== repeatPassword.value) {
    alert('Passwords do not match');
    return;
  }
  try {
    await signUp({
      username: username.value,
      password: password.value,
      options: {
        userAttributes: {
          email: email.value
        },
      }
    });
    alert('Registration successful! Please check your email to confirm your account.');
    emit('switch-view', 'confirm');
  } catch (error) {
    console.error('Error during registration', error);
    alert('Error during registration');
  }
};

const switchToLogin = () => {
  emit('switch-view', 'login');
};
</script>

<style scoped>
.register {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  gap: 20px;
}
</style>
