<template>
  <div class="app">
    <h1>Ma Collection</h1>

    <button @click="showForm = !showForm">
      {{ showForm ? 'Fermer le formulaire' : 'Ajouter un item' }}
    </button>

    <!-- Formulaire -->
    <div v-if="showForm" class="form-container">
      <h2>Ajouter un item</h2>
      <form @submit.prevent="addItem">
        <div>
          <label>Titre :</label>
          <input v-model="newItem.title" required />
        </div>
        <div>
          <label>Auteur :</label>
          <input v-model="newItem.author" />
        </div>
        <div>
          <label>Date d'acquisition :</label>
          <input type="date" v-model="newItem.acquisition_date" />
        </div>
        <button type="submit">Ajouter</button>
      </form>
    </div>

    <!-- Liste des items -->
    <h2>Liste des items</h2>
    <ul>
      <li v-for="item in items" :key="item.id">
        <strong>{{ item.title }}</strong> - {{ item.author }} ({{ item.acquisition_date }}) 
      </li>
    </ul>
  </div>
</template>

<script>
import axios from 'axios';

export default {
  data() {
    return {
      items: [],
      showForm: false,
      newItem: {
        title: '',
        author: '',
        acquisition_date: '',
      }
    };
  },
  methods: {
    async fetchItems() {
      try {
        const res = await axios.get('http://localhost:5000/items');
        this.items = res.data;
      } catch (err) {
        console.error(err);
      }
    },
    async addItem() {
      try {
        await axios.post('http://localhost:5000/items', this.newItem);
        this.newItem = { title: '', author: '', acquisition_date: ''};
        this.showForm = false;
        this.fetchItems(); // Actualiser la liste
      } catch (err) {
        console.error(err);
      }
    }
  },
  mounted() {
    this.fetchItems(); // Charger la liste au démarrage
  }
};
</script>

<style>
form div {
  margin-bottom: 10px;
}
.form-container {
  margin: 20px 0;
  padding: 10px;
  border: 1px solid #ccc;
}
</style>
