# Hands-on 20-1 : nginx を実行(generator)

```bash
# nginx を起動
kubectl run my-nginx --image=<Harbor FQDN>/${USER}/${USER}-nginx:0.1

# 起動確認
kubectl get pod -o wide
  # -> Pod に割り当てられている IP アドレスを確認する

# アクセス確認のためテスト用Podを起動
kubectl run testpod --image=busybox --command sleep 900

# 起動確認
kubectl get pod

# アクセス確認
kubectl exec -it testpod -- wget http://<my-nginx の IP> -q -O -
  # -> nginx のページが取得できることを確認

# ログ確認
kubectl logs -f my-nginx

# もう1枚ターミナルを開き nginx にアクセス
kubectl exec -it testpod -- wget http://<my-nginx の IP> -q -O -
  # アクセスと同時にログが出力されることを確認

# pod 削除
kubectl get pod
kubectl delete pod my-nginx
kubectl delete pod testpod
kubectl get pod
```

# Hands-on 20-2 : nginx を実行(manifest)

```bash
# yaml作成
cd
kubectl run my-nginx --image=<Harbor FQDN>/${USER}/${USER}-nginx:0.1 --dry-run=client -o yaml > my-nginx.yaml
cat my-nginx.yaml

# yaml適用
kubectl apply -f my-nginx.yaml

# 起動確認
kubectl get pod

# pod 削除
kubectl get pod
kubectl delete pod my-nginx
kubectl get pod
```

