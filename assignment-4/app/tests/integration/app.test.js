'use strict';

const supertest = require('supertest');
const app = require('../../src/app');

describe('Integration – Full Express App', () => {
  let server;
  let request;

  beforeAll((done) => {
    server = app.listen(0, done); // port 0 = random free port
    request = supertest(server);
  });

  afterAll((done) => {
    server.close(done);
  });

  test('GET /health returns 200 and correct shape', async () => {
    const res = await request.get('/health');
    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('status', 'ok');
    expect(res.body).toHaveProperty('uptime');
    expect(typeof res.body.uptime).toBe('number');
  });

  test('Full add flow: POST /api/add then verify result', async () => {
    const res = await request.post('/api/add').send({ a: 100, b: 200 });
    expect(res.status).toBe(200);
    expect(res.body.result).toBe(300);
  });
});
