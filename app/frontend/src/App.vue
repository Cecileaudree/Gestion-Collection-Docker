<template>
  <div class="app">
    <header class="header">
      <h1>📚 Ma Collection</h1>
      <p>Gérez facilement vos objets de collection</p>
    </header>

    <div class="actions">
      <button class="btn primary" @click="showForm = !showForm">
        {{ showForm ? '✖ Fermer' : '➕ Ajouter un item' }}
      </button>
    </div>

    <!-- Formulaire -->
    <div v-if="showForm" class="card">
      <h2>Ajouter un item</h2>
      <form @submit.prevent="addItem">
        <div class="field">
          <label>Titre</label>
          <input v-model="newItem.title" required />
        </div>

        <div class="field">
          <label>Auteur</label>
          <input v-model="newItem.author" />
        </div>

        <div class="field">
          <label>Date d'acquisition</label>
          <input type="date" v-model="newItem.acquisition_date" />
        </div>

        <button class="btn success" type="submit">Enregistrer</button>
      </form>
    </div>

    <!-- Liste -->
    <div class="card">
      <h2>Liste des items</h2>

      <p v-if="items.length === 0" class="empty">
        Aucun item enregistré.
      </p>

      <ul class="items">
        <li v-for="item in items" :key="item.id" class="item">
          <div>
            <strong>{{ item.title }}</strong>
            <small>{{ item.author || 'Auteur inconnu' }}</small>
          </div>
          <span class="date">{{ item.acquisition_date }}</span>
        </li>
      </ul>
    </div>
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
        const res = await axios.get('/api/items');
        this.items = res.data;
      } catch (err) {
        console.error(err);
      }
    },
    async addItem() {
      try {
        await axios.post('/api/items', this.newItem);
        this.newItem = { title: '', author: '', acquisition_date: '' };
        this.showForm = false;
        this.fetchItems();
      } catch (err) {
        console.error(err);
      }
    }
  },
  mounted() {
    this.fetchItems();
  }
};
</script>

<style>
/* RESET SIMPLE */
* {
  box-sizing: border-box;
  font-family: Arial, Helvetica, sans-serif;
}

/* LAYOUT */
.app {
  max-width: 700px;
  margin: auto;
  padding: 20px;
}

.header {
  text-align: center;
  margin-bottom: 30px;
}

.header h1 {
  margin-bottom: 5px;
}

.actions {
  text-align: center;
  margin-bottom: 20px;
}

/* CARTES */
.card {
  background: #fff;
  border-radius: 8px;
  padding: 20px;
  margin-bottom: 25px;
  box-shadow: 0 4px 10px rgba(0,0,0,0.08);
}

/* FORM */
.field {
  margin-bottom: 15px;
}

label {
  display: block;
  font-weight: bold;
  margin-bottom: 5px;
}

input {
  width: 100%;
  padding: 8px;
  border-radius: 4px;
  border: 1px solid #ccc;
}

/* BOUTONS */
.btn {
  padding: 10px 15px;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  font-size: 14px;
}

.btn.primary {
  background: #007bff;
  color: white;
}

.btn.success {
  background: #28a745;
  color: white;
}

/* LISTE */
.items {
  list-style: none;
  padding: 0;
}

.item {
  display: flex;
  justify-content: space-between;
  padding: 10px;
  border-bottom: 1px solid #eee;
}

.item small {
  display: block;
  color: #666;
}

.date {
  color: #999;
  font-size: 14px;
}

.empty {
  text-align: center;
  color: #888;
}
</style>
