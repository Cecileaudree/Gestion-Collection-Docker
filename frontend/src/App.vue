<template>
  <div>
    <h1>Collection App</h1>
    <button @click="checkBackend">Tester Backend</button>
    <p>{{ message }}</p>

    <h2>Items</h2>
    <ul>
      <li v-for="item in items" :key="item.id">
        {{ item.title }} - {{ item.author }}
      </li>
    </ul>
  </div>
</template>

<script>
import axios from 'axios'

export default {
  data() {
    return {
      message: '',
      items: []
    }
  },
  methods: {
    async checkBackend() {
      try {
        const res = await axios.get('http://localhost:5000/');
        this.message = res.data;
        const itemsRes = await axios.get('http://localhost:5000/items');
        this.items = itemsRes.data;
      } catch (err) {
        this.message = 'Erreur backend';
      }
    }
  }
}
</script>
