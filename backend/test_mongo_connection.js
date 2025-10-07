const { MongoClient } = require('mongodb');

const uri = "mongodb+srv://fugaxpro:abhinav@123@fuga.pvjwlwc.mongodb.net/?retryWrites=true&w=majority";

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
