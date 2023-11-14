# Hands-on 47-1 : Namespace 一覧取得

```bash
# Namespace 一覧取得
kubectl get namespace
```

# Hands-on 47-2 : Namespace 作成

```bash
# namespace 作成
kubectl create namespace ${USER}2

# 作成できたことを確認
kubectl get namespace
```

# Hands-on 47-3 : 作成した Namespace に Pod を deploy

```bash
# 作成した Namespace に Pod を deploy
kubectl run my-nginx --image=<Harbor FQDN>/${USER}/${USER}-nginx:0.1 -n ${USER}2

# pod 一覧表示
kubectl get pod
  # -> 異なる namespace に作成したため、作成した pod が見えない

# pod 一覧表示
kubectl get pod -n ${USER}2
  # -> 作成した pod が見えること

# 削除
kubectl delete pod my-nginx -n ${USER}2
kubectl get pod -n ${USER}2

kubectl delete namespace ${USER}2
kubectl get namespace
```




