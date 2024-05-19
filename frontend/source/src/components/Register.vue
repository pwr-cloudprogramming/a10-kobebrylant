<template>
  <div>
    <h2>Register</h2>
    <form @submit.prevent="register">
      <input v-model="username" placeholder="Username" required />
      <input v-model="email" type="email" placeholder="Email" required />
      <input v-model="password" type="password" placeholder="Password" required />
      <button type="submit">Register</button>
    </form>
  </div>
</template>

<script>
import { Auth } from 'aws-amplify';

export default {
  data() {
    return {
      username: '',
      email: '',
      password: ''
    };
  },
  methods: {
    async register() {
      try {
        await Auth.signUp({
          username: this.username,
          password: this.password,
          attributes: {
            email: this.email
          }
        });
        alert('Registration successful! Please check your email to verify your account.');
      } catch (error) {
        console.error('Error during registration:', error);
        alert('Error during registration. Please try again.');
      }
    }
  }
};
</script>
