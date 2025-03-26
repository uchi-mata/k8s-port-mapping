# k8s-port-mapping

Container to create Kubernetes port-pod-pid mapping.

Results are written to stdout and can be retrieved via logs:
```
kc logs job/podenumeration
```

# Build

```
docker buildx build . -t  uchimata/pods-pids-ports --platform linux/amd64,linux/arm64
docker push uchimata/pods-pids-ports
```