import express from 'express';
import path from 'path';
import { config } from './config';

const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, '..', '..', 'web')));

app.post('/login', (req, res) => {
  const header = req.headers.authorization ?? '';
  const token = header.replace(/^Bearer\s+/i, '').trim();
  if (token !== config.apiKey) {
    console.warn('auth: API key mismatch');
    return res.status(401).json({ error: 'authentication failed' });
  }
  res.json({ ok: true, message: 'logged in' });
});

app.listen(config.port, () => {
  console.log(`server listening on :${config.port}`);
});
