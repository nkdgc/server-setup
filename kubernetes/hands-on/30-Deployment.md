# Hands-on 30-1 : deployment で nginx を実行 -> Pod 削除確認

```bash
# nginx の deployment を作成
kubectl create deployment my-nginx --image=<Harbor FQDN>/${USER}/${USER}-nginx:0.1

# deployment を確認
kubectl get deployment

# Pod 起動確認
kubectl get pod -o wide
  # -> NAME と IP を確認する

# アクセス確認のためテスト用Podを起動
kubectl run testpod --image=busybox --command sleep 900

# 起動確認
kubectl get pod

# アクセス確認
kubectl exec -it testpod -- wget http://<my-nginx の IP> -q -O -
  # -> nginx のページが取得できることを確認

# ログ確認
kubectl logs -f <PodのName>

# Pod を削除し何が起きるか確認しましょう
kubectl get pod
kubectl delete pod <my-nginxのPod名。例：my-nginx-7d8d786556-chrrm>
kubectl get pod

# 削除
kubectl get deployment
kubectl get pod

kubectl delete deployment my-nginx
kubectl delete pod testpod

kubectl get deployment
kubectl get pod
```

# Hands-on 30-2 : nginx をdeploymentで実行 -> スケールアウト

```bash
# nginx の deployment を作成
cd
kubectl create deployment my-nginx --image=<Harbor FQDN>/${USER}/${USER}-nginx:0.1 --dry-run=client -o yaml > my-nginx-deployment.yaml 
cat my-nginx-deployment.yaml 
kubectl apply -f my-nginx-deployment.yaml 

# deployment を確認
kubectl get deployment

# Pod 起動確認
kubectl get pod
  # -> Pod が何個起動しているか確認

# Replicasを変更
vim my-nginx-deployment.yaml
  # replicas を 1 から 3 に変更
  # (変更前) replicas: 1
  # (変更後) replicas: 3

# 適用
kubectl apply -f my-nginx-deployment.yaml

# deployment を確認
kubectl get deployment
  # 適用前に確認した時との差分を確認

# Pod 起動確認
kubectl get pod
  # -> Pod が何個起動しているか確認
```

# Hands-on 30-3 : アップデートを確認するため新規コンテナイメージを build, Push

```bash
cd ~/myapp

# index.html を変更
cat <<EOF > index.html
${USER}'s Nginx Page v0.2
EOF

cat index.html

docker build -t <Harbor FQDN>/${USER}/${USER}-nginx:0.2 .

docker images | grep -e "REPOSITORY" -e "${USER}-nginx"

docker push <Harbor FQDN>/${USER}/${USER}-nginx:0.2
```


# Hands-on 30-2 : nginx をdeploymentで実行 -> アップデート

```bash
cd
vim my-nginx-deployment.yaml
  # image の tag を 0.1 から 0.2 に変更
  # (変更前) - image: <Harbor FQDN>/ndeguchi/ndeguchi-nginx:0.1
  # (変更後) - image: <Harbor FQDN>/ndeguchi/ndeguchi-nginx:0.2

kubectl apply -f my-nginx-deployment.yaml
kubectl get deployment
kubectl get pod
  # -> AGE 列の時間から再作成されていることを確認

kubectl describe pod <Pod の NAME。例：my-nginx-64c65c48f6-lngbr>
  # -> Image が 0.1 ではなく 0.2 になっていることを確認

# アクセス確認のためテスト用Podを起動
kubectl run testpod --image=busybox --command sleep 900

# 起動確認
kubectl get pod

# Pod 起動確認
kubectl get pod -o wide
  # -> my-nginx の NAME と IP を確認する

# アクセス確認
kubectl exec -it testpod -- wget http://<my-nginx の IP> -q -O -
  # -> v0.2 のページが取得できることを確認

# 削除
kubectl get deployment
kubectl get pod

kubectl delete deployment my-nginx
kubectl delete pod testpod

kubectl get deployment
kubectl get pod
```

