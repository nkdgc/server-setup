# Hands-on 70-1 : 環境変数

```bash
# 環境変数を指定して Pod を作成
cd
kubectl run testpod --image=busybox --env="PING=PONG" --command sleep 900 --dry-run=client -o yaml > testpod.yaml
cat testpod.yaml
  # 環境変数（PING=PONG）がどのように定義されているのか確認しましょう

kubectl apply -f testpod.yaml

# Pod 起動確認
kubectl get pods

# 環境変数が設定されていることを確認
kubectl exec -it testpod -- sh
echo $PING
  # -> 環境変数に値が格納されていることを確認

exit

# 削除
kubectl get pod
kubectl delete pod testpod
kubectl get pod
```

# Hands-on 70-2 : ConfigMap 作成

```bash
# ConfigMap を作成
kubectl create configmap cm-1 --from-literal=hoge=HOGE --from-literal=fuga=FUGA --from-literal=piyo=PIYO

# ConfigMap をリスト表示
kubectl get configmap

# ConfigMap の内容を表示（get）
kubectl get configmap cm-1 -o yaml

# ConfigMap の内容を表示（describe）
kubectl describe configmap cm-1
```

# Hands-on 70-3 : ConfigMap を ファイルとして Pod にマウント

```bash
cd
kubectl create deployment testpod --image=busybox --dry-run=client -o yaml > testpod.yaml -- /bin/sh -c 'sleep 900'
vim testpod.yaml
  # -> 以下 + で始まる行を追記する
  #    |      spec:
  #    |        containers:
  #    |        - command:
  #    |          - /bin/sh
  #    |          - -c
  #    |          - sleep 900
  #    |          image: busybox
  #    |          name: busybox
  #    |          resources: {}
  #    | +        volumeMounts:
  #    | +        - name: vol
  #    | +          mountPath: /data
  #    | +      volumes:
  #    | +      - name: vol
  #    | +        configMap:
  #    | +          name: cm-1

kubectl apply -f testpod.yaml

# Pod 起動確認
kubectl get deployment
kubectl get pod
  # -> Pod の NAME を確認

# マウントされている ConfigMap を確認
kubectl exec -it <Pod の NAME> -- sh
PS1="\n$PS1"
cat /data/hoge
cat /data/fuga
cat /data/piyo
exit

kubectl get deployment
kubectl delete deployment testpod
kubectl get deployment
```

# Hands-on 70-4 : ConfigMap を 環境変数として Pod にマウント

```bash
cd
kubectl create deployment testpod --image=busybox --dry-run=client -o yaml > testpod.yaml -- /bin/sh -c 'sleep 900'
vim testpod.yaml
  # -> 以下 + で始まる行を追記する
  #    |      spec:
  #    |        containers:
  #    |        - command:
  #    |          - /bin/sh
  #    |          - -c
  #    |          - sleep 900
  #    |          image: busybox
  #    |          name: busybox
  #    |          resources: {}
  #    | +        envFrom:
  #    | +        - configMapRef:
  #    | +            name: cm-1

kubectl apply -f testpod.yaml

# Pod 起動確認
kubectl get deployment
kubectl get pod
  # -> Pod の NAME を確認

# 環境変数に設定されている ConfigMap を確認
kubectl exec -it <Pod の NAME> -- sh
echo ${hoge}
echo ${fuga}
echo ${piyo}
exit

kubectl get deployment
kubectl delete deployment testpod
kubectl get deployment
```

# Hands-on 70-5 : Secret 作成

```bash
# Secret に登録するファイルを作成
cat <<EOF > db-cred.txt
db_user=postgres
db_password=VMware1!
EOF

cat db-cred.txt

# Secret 作成
kubectl create secret generic --save-config db-cred --from-env-file=db-cred.txt

kubectl get secret

kubectl get secret db-cred -o yaml

# Secret 内容確認
echo "Vk13YXJlMSE=" | base64 -d
echo "cG9zdGdyZXM=" | base64 -d
```

# Hands-on 70-5 : Secret を環境変数に指定

```bash
cd
kubectl create deployment testpod --image=busybox --dry-run=client -o yaml > testpod.yaml -- /bin/sh -c 'sleep 900'
vim testpod.yaml
  # -> 以下 + で始まる行を追記する
  #     |      spec:
  #     |        containers:
  #     |        - command:
  #     |          - /bin/sh
  #     |          - -c
  #     |          - sleep 900
  #     |          image: busybox
  #     |          name: busybox
  #     |          resources: {}
  #     | +        envFrom:
  #     | +        - secretRef:
  #     | +            name: db-cred

kubectl apply -f testpod.yaml

# Pod 起動確認
kubectl get deployment
kubectl get pod
  # -> Pod の NAME を確認

# 環境変数に設定されている ConfigMap を確認
kubectl exec -it <Pod の NAME> -- sh
echo ${db_user}
echo ${db_password}
exit

kubectl get deployment
kubectl delete deployment testpod
kubectl get deployment
```

