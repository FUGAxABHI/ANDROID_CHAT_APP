require('dotenv').config();
const { MongoClient } = require('mongodb');

const uri = process.env.MONGO_URI;

if (!uri) {
  console.error("MONGO_URI not found in .env file. Please add it.");
  process.exit(1);
}

console.log("Attempting to connect to MongoDB with the provided URI...");

const client = new MongoClient(uri);

async function testConnection() {
  try {
    await client.connect();
    console.log("Connection successful!");
    await client.close();
  } catch (error) {
    console.error("Connection failed with error:");
    console.error(error);
  }
}

testConnection();
