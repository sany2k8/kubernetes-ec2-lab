# Chapter 4 — Install Docker

```bash
sudo apt install docker.io -y
```

Enable Docker to start on boot and start it now:

```bash
sudo systemctl enable docker
sudo systemctl start docker
```

Verify:

```bash
docker version
docker ps
```

Add your user to the `docker` group so you don't need `sudo` for every docker command (log out/in or run `newgrp docker` afterwards):

```bash
sudo usermod -aG docker $USER
newgrp docker
```
