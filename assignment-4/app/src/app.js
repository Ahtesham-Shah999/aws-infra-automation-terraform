'use strict';

const express = require('express');
const { router: appRouter } = require('./routes');

const app = express();
app.use(express.json());
app.use('/', appRouter);

module.exports = app;
