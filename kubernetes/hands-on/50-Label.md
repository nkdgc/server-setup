# Hands-on 50-1 : Label付与, 取得

```bash
# Label を付与した Pod を作成
kubectl run my-nginx1 --image=${harbor_fqdn}/${USER}/${USER}-nginx:0.1 -l key1=value1
kubectl run my-nginx2 --image=${harbor_fqdn}/${USER}/${USER}-nginx:0.1 -l key1=value2


# 起動確認
kubectl get pod

# Label確認
kubectl get pod --show-labels

# Label を用いた Pod 取得
kubectl get pod -l key1=value1
kubectl get pod -l key1=value2

# Label を用いたログ取得
kubectl logs -l key1=value1
kubectl logs -l key1=value2

# 削除
kubectl get pod
kubectl delete pod my-nginx1
kubectl delete pod my-nginx2
kubectl get pod
```

