# Access, Scaling, Rolling Updates, and Cleanup

## Access the Application

```bash
http://<EC2_PUBLIC_IP>:30080
```

Make sure port `30080` (within the 30000-32767 NodePort range you opened in Chapter 1) is reachable in your Security Group.

---

## Scaling

```bash
kubectl scale deployment webapp -n webapp --replicas=4
```

Watch it happen:

```bash
kubectl get pods -n webapp -w
```

---

## Rolling Updates & Rollback

Build and import a new version of the image (tag it `v2`), then:

```bash
kubectl set image deployment/webapp webapp=webapp:v2 -n webapp
```

Check rollout status and history:

```bash
kubectl rollout status deployment/webapp -n webapp
kubectl rollout history deployment/webapp -n webapp
```

Roll back if something's wrong:

```bash
kubectl rollout undo deployment/webapp -n webapp
```

---

## Cleanup

```bash
kubectl delete -f k8s/
docker image rm webapp:v1
```
