'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const zlib = require('node:zlib');
const { serveStatic } = require('./static-files');

test('SPA deep links, MIME, gzip, HEAD and path limits', async () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'ghost-static-'));
  fs.writeFileSync(path.join(root, 'index.html'), '<html>Ghost</html>');
  fs.writeFileSync(path.join(root, 'main.js'), 'console.log("ghost")');
  fs.writeFileSync(path.join(root, 'main.js.gz'), zlib.gzipSync('console.log("ghost")'));
  const server = http.createServer((req, res) => serveStatic(req, res, root));
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  const base = `http://127.0.0.1:${server.address().port}`;
  try {
    for (const route of ['/', '/albums/12', '/concerts/new', '/login?from=/albums']) {
      const res = await fetch(base + route); assert.equal(res.status, 200);
      assert.match(await res.text(), /Ghost/);
    }
    const js = await fetch(base + '/main.js');
    assert.match(js.headers.get('content-type'), /javascript/);
    assert.equal(js.headers.get('content-encoding'), 'gzip');
    assert.match(await js.text(), /ghost/);
    assert.equal((await fetch(base + '/missing.js')).status, 404);
    assert.equal((await fetch(base + '/main.js', { method: 'HEAD' })).headers.get('content-type'), 'text/javascript; charset=utf-8');
    assert.equal((await fetch(base + '/albums', { method: 'POST' })).status, 405);
    assert.equal((await fetch(base + '/%00secret')).status, 403);
    assert.equal(js.headers.get('cross-origin-embedder-policy'), 'credentialless');
  } finally {
    await new Promise(r => server.close(r));
    fs.rmSync(root, { recursive: true, force: true });
  }
});
