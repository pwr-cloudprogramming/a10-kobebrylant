<template>
  <div>
    <h2>Login</h2>
    <form @submit.prevent="login">
      <input v-model="username" placeholder="Username" required />
      <input v-model="password" type="password" placeholder="Password" required />
      <button type="submit">Login</button>
    </form>
  </div>
</template>

<script>
import { Auth } from 'aws-amplify';

export default {
  data() {
    return {
      username: '',
      password: ''
    };
  },
  methods: {
    async login() {
      try {
        const user = await Auth.signIn(this.username, this.password);
        const tokens = user.signInUserSession;
        localStorage.setItem('accessToken', tokens.accessToken.jwtToken);
        localStorage.setItem('refreshToken', tokens.refreshToken.token);
        this.$emit('login', tokens.accessToken.jwtToken);
      } catch (error) {
        console.error('Error during login:', error);
        alert('Error during login. Please try again.');
      }
    }
  }
};
</script>
