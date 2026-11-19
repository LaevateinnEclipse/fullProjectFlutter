const { spawn } = require('node:child_process');
const http = require('node:http');

const port = 8097;
const child = spawn(process.execPath, ['server/mock-server.js', '--port', String(port), '--ephemeral'], {
  cwd: require('node:path').join(__dirname, '..'),
  stdio: 'ignore',
});

function request(method, path, { token, body } = {}) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const req = http.request({
      hostname: '127.0.0.1',
      port,
      path,
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {}),
      },
    }, (res) => {
      const chunks = [];
      res.on('data', (chunk) => chunks.push(chunk));
      res.on('end', () => {
        const text = Buffer.concat(chunks).toString('utf8');
        let json = null;
        try { json = text ? JSON.parse(text) : null; } catch { json = text; }
        resolve({ status: res.statusCode, json });
      });
    });
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

async function login(username, password) {
  const result = await request('POST', '/api/auth/login', { body: { username, password } });
  if (result.status !== 200) throw new Error(`${username}: ${result.status} ${JSON.stringify(result.json)}`);
  return result.json.accessToken;
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

(async () => {
  await new Promise((resolve) => setTimeout(resolve, 400));
  const open = await request('GET', '/api/albums');
  assert(open.status === 401, `каталог без токена должен быть 401, получен ${open.status}`);

  const fan = await login('fan', 'fan123');
  const ghoul = await login('ghoul', 'ghoul123');
  const manager = await login('manager', 'manager123');
  const admin = await login('admin', 'admin123');

  const bad = await request('POST', '/api/auth/login', { body: { username: 'fan', password: 'wrong' } });
  assert(bad.status === 401, 'неверный пароль');

  const fanWrite = await request('POST', '/api/albums', { token: fan, body: { title: 'X' } });
  assert(fanWrite.status === 422 || fanWrite.status === 403, `фанат не создаёт альбом, получен ${fanWrite.status}`);

  const ghoulConcert = await request('POST', '/api/concerts/1/claim', { token: ghoul });
  assert(ghoulConcert.status === 403, 'гуль не берёт билет');

  const managerAlbum = await request('DELETE', '/api/albums/1', { token: manager });
  assert(managerAlbum.status === 403, 'менеджер не удаляет альбом');

  const claim = await request('POST', '/api/concerts/1/claim', { token: fan });
  assert(claim.status === 200, `фанат берёт билет, получен ${claim.status}`);

  const foreign = await request('POST', '/api/concerts/1/release', { token: ghoul });
  assert(foreign.status === 403, 'гуль не возвращает билет');

  const returned = await request('POST', '/api/concerts/1/release', { token: fan });
  assert(returned.status === 200 && !returned.json.ownerUserId, 'фанат возвращает свой билет');

  const users = await request('GET', '/api/users', { token: manager });
  assert(users.status === 403, 'менеджер не видит пользователей');

  const stats = await request('GET', '/api/admin/statistics', { token: admin });
  assert(stats.status === 200 && stats.json.albums > 0, 'статистика администратора');

  console.log('server role checks passed');
  child.kill();
  process.exit(0);
})().catch((error) => {
  console.error(error);
  child.kill();
  process.exit(1);
});
