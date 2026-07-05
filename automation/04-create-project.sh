#!/usr/bin/env bash
set -euo pipefail

echo ">> Scaffolding app directory..."
mkdir -p app/public

cat > app/package.json <<'EOF'
{
  "name": "k8s-ec2-webapp",
  "version": "1.0.0",
  "description": "Simple Node.js app for learning Kubernetes on EC2",
  "main": "server.js",
  "scripts": { "start": "node server.js" },
  "dependencies": { "express": "^4.19.2" }
}
EOF

cat > app/server.js <<'EOF'
const express = require('express');
const path = require('path');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.static(path.join(__dirname, 'public')));

app.get('/api/health', (req, res) => res.json({ status: 'ok' }));
app.get('/api/info', (req, res) => res.json({
  hostname: os.hostname(),
  platform: os.platform(),
  uptime: os.uptime(),
}));

app.listen(PORT, '0.0.0.0', () => console.log(`Server running on port ${PORT}`));
EOF

cat > app/public/index.html <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8" /><title>Kubernetes EC2 Web App</title></head>
<body style="font-family:sans-serif;text-align:center;margin-top:10%;background:#0f172a;color:#e2e8f0;">
  <h1 style="color:#38bdf8;">🚀 Hello from Kubernetes on EC2!</h1>
  <p id="hostname">Loading pod hostname...</p>
  <script>
    fetch('/api/info').then(r => r.json()).then(d =>
      document.getElementById('hostname').innerText = 'Served by pod: ' + d.hostname);
  </script>
</body>
</html>
EOF

cat > app/Dockerfile <<'EOF'
FROM node:20-alpine
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
EOF

mkdir -p k8s

cat > k8s/namespace.yaml <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: webapp
EOF

cat > k8s/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: webapp
  labels:
    app: webapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
        - name: webapp
          image: webapp:v1
          imagePullPolicy: Never
          ports:
            - containerPort: 3000
          readinessProbe:
            httpGet: { path: /api/health, port: 3000 }
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet: { path: /api/health, port: 3000 }
            initialDelaySeconds: 10
            periodSeconds: 15
          resources:
            requests: { cpu: "100m", memory: "128Mi" }
            limits: { cpu: "250m", memory: "256Mi" }
EOF

cat > k8s/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
  namespace: webapp
spec:
  type: NodePort
  selector:
    app: webapp
  ports:
    - port: 80
      targetPort: 3000
      nodePort: 30080
EOF

echo ">> Project files created under app/ and k8s/."
