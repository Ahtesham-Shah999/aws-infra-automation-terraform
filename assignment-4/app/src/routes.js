'use strict';

const { Router } = require('express');
const router = Router();

// GET /health
router.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', uptime: process.uptime() });
});

// GET /
router.get('/', (req, res) => {
  res.status(200).json({ message: 'DevOps Assignment 4 - CI/CD Pipeline' });
});

// GET /api/greet/:name
router.get('/api/greet/:name', (req, res) => {
  const { name } = req.params;
  if (!name || name.trim() === '') {
    return res.status(400).json({ error: 'Name is required' });
  }
  return res.status(200).json({ greeting: `Hello, ${name}!` });
});

// POST /api/add
router.post('/api/add', (req, res) => {
  const { a, b } = req.body;
  if (typeof a !== 'number' || typeof b !== 'number') {
    return res.status(400).json({ error: 'a and b must be numbers' });
  }
  return res.status(200).json({ result: a + b });
});

module.exports = { router };
