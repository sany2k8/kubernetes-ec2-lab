# Chapter 9 — Dockerize the App

**`app/Dockerfile`**

```dockerfile
FROM node:20-alpine

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install --production

COPY . .

EXPOSE 3000

CMD ["node", "server.js"]
```

Build the image:

```bash
docker build -t webapp:v1 .
```

Run it standalone to sanity-check it before Kubernetes gets involved:

```bash
docker run -d -p 3000:3000 --name webapp-test webapp:v1
docker ps
curl localhost:3000/api/health
docker stop webapp-test && docker rm webapp-test
```

> **Note on images and kubeadm:** since this is a single-node cluster using containerd, the image built with `docker build` needs to be visible to containerd. The simplest path for a learning setup is to import it directly:
> ```bash
> docker save webapp:v1 -o webapp.tar
> sudo ctr -n=k8s.io images import webapp.tar
> ```
> In production you'd instead push to a registry (Docker Hub, ECR, GHCR) and reference it by tag in your Deployment — this is listed as a bonus exercise below.
