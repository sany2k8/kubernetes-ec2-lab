# Chapter 10 — Kubernetes Manifests

Core concepts before the YAML:

- **Pod** — the smallest deployable unit; one or more containers sharing network/storage.
- **ReplicaSet** — ensures a specified number of identical Pods are running at all times.
- **Deployment** — manages ReplicaSets for you, and enables rolling updates/rollbacks.
- **Service** — a stable network endpoint that load-balances traffic across a set of Pods.
- **Selector / Labels** — how Services and Deployments find the Pods they manage (key/value tags matched between the Pod template and the selector).
- **Namespace** — a virtual cluster-within-a-cluster used to group and isolate resources.

**`k8s/namespace.yaml`**

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: webapp
```

**`k8s/deployment.yaml`**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: webapp
  labels:
    app: webapp
spec:
  replicas: 1
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
            httpGet:
              path: /api/health
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /api/health
              port: 3000
            initialDelaySeconds: 10
            periodSeconds: 15
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "250m"
              memory: "256Mi"
```

**`k8s/service.yaml`**

```yaml
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
```

**`k8s/ingress.yaml`** (optional bonus)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
  namespace: webapp
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: webapp-service
                port:
                  number: 80
```

Apply everything (in order — namespace first):

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

Verify:

```bash
kubectl get all -n webapp
kubectl get pods -n webapp
kubectl describe pod <pod-name> -n webapp
kubectl logs <pod-name> -n webapp
```
