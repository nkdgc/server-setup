# Hands-on 60-1 : Service - ClusterIP

```bash
# Deployment 作成
kubectl create deployment my-nginx --image=<Harbor FQDN>/${USER}/${USER}-nginx:0.1
kubectl get deployment

# Pod 確認
kubectl get pod

# Service - ClusterIP 作成
kubectl expose deployment/my-nginx --port 80
kubectl get service
  # -> CLUSTER-IP の IP アドレスを確認

# アクセス確認のためテスト用Podを起動
kubectl run testpod --image=busybox --command sleep infinity

# 起動確認
kubectl get pod

# アクセス確認
kubectl exec -it testpod -- wget http://<CLUSTER-IP の IP アドレス> -q -O -
  # -> ClusterIP の Service 経由で nginx のページを取得できることを確認

# 削除
kubectl get deployment
kubectl delete deployment my-nginx
kubectl get deployment

kubectl get pod
kubectl delete pod testpod
kubectl get pod

kubectl get service
kubectl delete service my-nginx
kubectl get service
```

# Hands-on 60-2 : Service - NodePort

```bash
# Deployment 作成
kubectl create deployment my-nginx --image=<Harbor FQDN>/${USER}/${USER}-nginx:0.1
kubectl get deployment

# Pod 確認
kubectl get pod

# Service - NodePort 作成
kubectl expose deployment/my-nginx --type="NodePort" --port 80
kubectl get service
  # -> NodePortで公開されているポート番号を確認
  #    NAME       TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
  #    my-nginx   NodePort   100.66.30.149   <none>        80:31807/TCP   8s
  #                                                           ^^^^^

# WorkerNode の IP アドレスを確認
kubectl get node -o wide
  # -> node の EXTERNAL-IP を確認(どのNodeのIPでも構いません)

# Service にアクセス
curl http://<EXTERNAL-IP>:<PORT>
  # -> NodePort で公開されている Service 経由で nginx のページを取得できることを確認

# 削除
kubectl get deployment
kubectl delete deployment my-nginx
kubectl get deployment

kubectl get service
kubectl delete service my-nginx
kubectl get service
```

# Hands-on 60-3 : Service - LoadBalancer

```bash
# Deployment 作成
kubectl create deployment my-nginx --image=<Harbor FQDN>/${USER}/${USER}-nginx:0.1
kubectl get deployment

# Pod 確認
kubectl get pod

# Service - LoadBalancer 作成
kubectl expose deployment/my-nginx --type="LoadBalancer" --port 80
kubectl get service
  # -> LoadBalancerで公開されているIPアドレス(EXTERNAL-IP)を確認
  #    NAME       TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)        AGE
  #    my-nginx   LoadBalancer   100.67.107.89   192.168.12.173   80:31638/TCP   5s
  #                                              ^^^^^^^^^^^^^^

# Service にアクセス
curl http://<EXTERNAL-IP>
  # -> LoadBalancer で公開されている Service 経由で nginx のページを取得できることを確認

# 削除
kubectl get deployment
kubectl delete deployment my-nginx
kubectl get deployment

kubectl get service
kubectl delete service my-nginx
kubectl get service
```

