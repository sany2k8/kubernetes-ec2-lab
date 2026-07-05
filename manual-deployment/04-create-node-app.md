# Chapter 7 — Create the Node.js App

```bash
mkdir -p app/public
cd app
```

**`app/package.json`**

```json
{
  "name": "k8s-ec2-webapp",
  "version": "1.0.0",
  "description": "Simple Node.js app for learning Kubernetes on EC2",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.19.2"
  }
}
```

**`app/server.js`**

```javascript
const express = require('express');
const path = require('path');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.static(path.join(__dirname, 'public')));

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.get('/api/info', (req, res) => {
  res.json({
    hostname: os.hostname(),
    platform: os.platform(),
    uptime: os.uptime(),
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
```

**`app/public/index.html`**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Kubernetes EC2 Web App</title>
  <style>
    body { font-family: sans-serif; text-align: center; margin-top: 10%; background: #0f172a; color: #e2e8f0; }
    h1 { color: #38bdf8; }
  </style>
</head>
<body>
  <h1>🚀 Hello from Kubernetes on EC2!</h1>
  <p>This page is served by a pod running inside a kubeadm cluster.</p>
  <p id="hostname">Loading pod hostname...</p>
  <script>
    fetch('/api/info')
      .then(r => r.json())
      .then(d => document.getElementById('hostname').innerText = 'Served by pod: ' + d.hostname);
  </script>
</body>
</html>
```

---

## Chapter 8 — Run the App Locally

```bash
npm install
node server.js
```

Open in your browser:

```
http://<EC2_PUBLIC_IP>:3000
```

(Make sure port 3000 is open in the Security Group temporarily, or just test with `curl localhost:3000` on the box.)
