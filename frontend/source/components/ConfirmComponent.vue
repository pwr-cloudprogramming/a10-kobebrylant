<template>
  <div class="confirm">
    <h2>Confirm Registration</h2>
    <input v-model="username" placeholder="Username" class="input"/>
    <input v-model="confirmationCode" placeholder="Confirmation Code" class="input"/>
    <button @click="confirmRegistration" class="start-button">Confirm</button>
  </div>
</template>

<script setup>
import {ref} from 'vue';
import {confirmSignUp} from 'aws-amplify/auth';

const username = ref('');
const confirmationCode = ref('');

// eslint-disable-next-line
const emit = defineEmits(['switch-view']);

const confirmRegistration = async () => {
  try {
    await confirmSignUp(
        {
          username: username.value,
          confirmationCode: confirmationCode.value
        }
    );
    alert('Confirmation successful! Please log in.');
    emit('switch-view', 'login');
  } catch (error) {
    console.error('Error during confirmation', error);
    alert('Error during confirmation');
  }
};


</script>

<style scoped>
/* Add your styles here */
</style>
