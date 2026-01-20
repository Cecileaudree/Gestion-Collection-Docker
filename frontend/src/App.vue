<template>
  <div>
    <h1>Collection App</h1>
    <button @click="checkBackend">Tester Backend</button>
    <p>{{ message }}</p>
  </div>
</template>

<script setup>
import { ref } from "vue";

const message = ref("");

const checkBackend = async () => {
  try {
    const res = await fetch(`${import.meta.env.VITE_API_URL}/health`);
    const data = await res.json();
    message.value = JSON.stringify(data);
  } catch (err) {
    message.value = "Erreur backend";
  }
};
</script>
