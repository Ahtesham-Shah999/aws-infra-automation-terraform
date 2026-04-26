'use strict';

const { router } = require('../../src/routes');
const express = require('express');

// Helper to build a mini express app for unit testing just the logic
const buildApp = () => {
  const app = express();
  app.use(express.json());
  app.use('/', router);
  return app;
};

describe('Unit – Routes logic', () => {
  let app;
  beforeAll(() => { app = buildApp(); });

  test('GET /health returns 200 with status ok', async () => {
    const supertest = require('supertest');
    const res = await supertest(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });

  test('GET / returns 200 with message', async () => {
    const supertest = require('supertest');
    const res = await supertest(app).get('/');
    expect(res.status).toBe(200);
    expect(res.body.message).toBeDefined();
  });

  test('GET /api/greet/Alice returns greeting', async () => {
    const supertest = require('supertest');
    const res = await supertest(app).get('/api/greet/Alice');
    expect(res.status).toBe(200);
    expect(res.body.greeting).toBe('Hello, Alice!');
  });

  test('POST /api/add returns correct sum', async () => {
    const supertest = require('supertest');
    const res = await supertest(app).post('/api/add').send({ a: 3, b: 7 });
    expect(res.status).toBe(200);
    expect(res.body.result).toBe(10);
  });

  test('POST /api/add with invalid input returns 400', async () => {
    const supertest = require('supertest');
    const res = await supertest(app).post('/api/add').send({ a: 'x', b: 7 });
    expect(res.status).toBe(400);
    expect(res.body.error).toBeDefined();
  });

  test('POST /api/add with missing body returns 400', async () => {
    const supertest = require('supertest');
    const res = await supertest(app).post('/api/add').send({});
    expect(res.status).toBe(400);
  });
});
