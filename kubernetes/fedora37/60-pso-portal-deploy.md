# PSO Portal Deploy

## Harbor 自動起動設定

作業実施サーバ: Harbor

```bash
cat <<EOF > /etc/rc.local
#!/usr/bin/bash
cd /root/harbor
docker compose up -d
EOF

chmod 755 /etc/rc.local
ll /etc/rc.local

/etc/rc.local

ll /etc/systemd/system/rc-local.service
  # -> ファイルが存在しないこと

cat <<EOF > /etc/systemd/system/rc-local.service
[Unit]
Description=/etc/rc.local

[Service]
ExecStart=/etc/rc.local
Restart=no
Type=simple

[Install]
WantedBy=multi-user.target
EOF

systemctl enable rc-local.service

shutdown -r now
```

再起動後、Harborが起動することを確認する

```bash
docker ps
```

```text
<出力例>
CONTAINER ID   IMAGE                                COMMAND                   CREATED          STATUS                        PORTS                                                                            NAMES
a4539b6437ec   goharbor/harbor-jobservice:v2.9.1    "/harbor/entrypoint.…"   18 minutes ago   Up 56 seconds (healthy)                                                                                        harbor-jobservice
0e3f59a0efe2   goharbor/nginx-photon:v2.9.1         "nginx -g 'daemon of…"   18 minutes ago   Up About a minute (healthy)   0.0.0.0:80->8080/tcp, :::80->8080/tcp, 0.0.0.0:443->8443/tcp, :::443->8443/tcp   nginx
d0f2f33e445a   goharbor/harbor-core:v2.9.1          "/harbor/entrypoint.…"   18 minutes ago   Up About a minute (healthy)                                                                                    harbor-core
d4b58b1f8f77   goharbor/redis-photon:v2.9.1         "redis-server /etc/r…"   18 minutes ago   Up About a minute (healthy)                                                                                    redis
2f8051939aea   goharbor/registry-photon:v2.9.1      "/home/harbor/entryp…"   18 minutes ago   Up About a minute (healthy)                                                                                    registry
5926aa4ee847   goharbor/harbor-db:v2.9.1            "/docker-entrypoint.…"   18 minutes ago   Up About a minute (healthy)                                                                                    harbor-db
a36086a6d834   goharbor/harbor-registryctl:v2.9.1   "/home/harbor/start.…"   18 minutes ago   Up About a minute (healthy)                                                                                    registryctl
5654ef2e9293   goharbor/harbor-portal:v2.9.1        "nginx -g 'daemon of…"   18 minutes ago   Up About a minute (healthy)                                                                                    harbor-portal
b43ff5244909   goharbor/harbor-log:v2.9.1           "/bin/sh -c /usr/loc…"   18 minutes ago   Up About a minute (healthy)   127.0.0.1:1514->10514/tcp                                                        harbor-log
```

## Harbor GC/LogRotate 設定

- Harbor に Web ブラウザでログイン
- GC 設定
  - `Administration` -> `Clean Up` -> `Garbage Collection`
  - `Schedule to GC` を設定
- Log Rotation
  - `Administration` -> `Clean Up` -> `Log Rotation`
  - `Schedule to purge` と `Keep records in` を設定

## Harbor のサーバ上に NFS サーバを構築

作業実施サーバ: Harbor

```bash
dnf -y install nfs-utils

cat <<EOF > /etc/exports
/nfsshare 192.168.0.0/16(rw,no_root_squash)
EOF
```

- 192.168.0.0/16
  - NFS サーバを公開するネットワークアドレス

```bash
cat /etc/exports

mkdir -p /nfsshare/vmw-pso-portal-postgres

systemctl status rpcbind nfs-server
systemctl enable --now rpcbind nfs-server
systemctl status rpcbind nfs-server
```

## dockerhub から共通 Container Image を取得し Harbor へpush

作業実施サーバ: 管理クライアント

```bash
echo ${HARBOR_FQDN}
  # -> Harbor の FQDN が設定されていること

docker pull postgres:13.10
docker pull openresty/openresty:latest
docker pull curlimages/curl:latest

docker images postgres:13.10
docker images openresty/openresty:latest
docker images curlimages/curl:latest

docker tag postgres:13.10             ${HARBOR_FQDN}/library/postgres:13.10
docker tag openresty/openresty:latest ${HARBOR_FQDN}/library/openresty:latest
docker tag curlimages/curl:latest     ${HARBOR_FQDN}/library/curl:latest

docker images ${HARBOR_FQDN}/library/postgres:13.10
docker images ${HARBOR_FQDN}/library/openresty:latest
docker images ${HARBOR_FQDN}/library/curl:latest

docker push ${HARBOR_FQDN}/library/postgres:13.10
docker push ${HARBOR_FQDN}/library/openresty:latest
docker push ${HARBOR_FQDN}/library/curl:latest
```

## Harbor でプロジェクト作成

作業実施サーバ: 管理クライアント

- 管理クライアントに GUI でログイン
- Firefox を起動し Harbor にアクセス
- Harbor で新規プロジェクトを作成
  - Project Name
    - vmw-pso-portal
  - Access Level
    - Public にチェック
  - Project quota limits
    - -1
  - Proxy Cache
    - Off

## dockerhub から PSO-Portal の Image を取得し Harbor へ push

作業実施サーバ: 管理クライアント

```bash
# 環境変数に Harbor の プロジェクト名と DockerHub の ID を設定
cat <<EOF >> ~/.bashrc
export HARBOR_PJNAME=vmw-pso-portal
export DOCKERHUB_USERNAME=nkdgc
EOF
```

- vmw-pso-portal
  - Harbor で作成したプロジェクト名
- nkdgc
  - PSO-Portal のイメージを格納している DockerHub の ID

```bash
source ~/.bashrc
echo ${HARBOR_PJNAME}
  # -> 上で指定した値が出力されること
echo ${DOCKERHUB_USERNAME}
  # -> 上で指定した値が出力されること

# DockerHub にログイン
docker login -u ${DOCKERHUB_USERNAME}
dckr_pat_xxxxxxxxxxxxxxxxxxxxxxxxxxx (DockerHub Token)

# コマンド実行に失敗したことを検知するための関数定義
function check_status(){
  if [ $? -ne 0 ]; then
    echo ""
    echo "================================================"
    echo "ERROR: $1"
    echo "================================================"
    echo ""
    sleep infinity
  fi
}

# Remove Images
images=("be-history" "be-inventory" "be-notice" "be-nsx_lb" "be-portal_auth" "be-portal_auth_seed" "be-vcenter_vm" "bff" "fe")

docker images | sort

for image in ${images[@]}; do
  echo "=== docker rmi ${image}"
  docker rmi ${DOCKERHUB_USERNAME}/vmw-pso-portal-${image}:latest
  docker rmi ${HARBOR_FQDN}/${HARBOR_PJNAME}/${image}:latest
  echo ""
done

docker images

# Pull images from Dockerhub
for image in ${images[@]}; do
  echo "=== docker pull ${DOCKERHUB_USERNAME}/${HARBOR_PJNAME}-${image}:latest"
  docker pull ${DOCKERHUB_USERNAME}/vmw-pso-portal-${image}:latest
  check_status "failed to docker pull"
  echo ""
done
docker images

# Tagging
for image in ${images[@]}; do
  echo "=== docker tag ${DOCKERHUB_USERNAME}/${HARBOR_PJNAME}-${image}:latest ${HARBOR_FQDN}/${HARBOR_PJNAME}/${image}:latest"
  docker tag ${DOCKERHUB_USERNAME}/vmw-pso-portal-${image}:latest ${HARBOR_FQDN}/${HARBOR_PJNAME}/${image}:latest
  check_status "failed to docker tag"
done
docker images | sort

# Push
for image in ${images[@]}; do
  echo "=== docker push ${HARBOR_FQDN}/${HARBOR_PJNAME}/${image}:latest"
  docker push ${HARBOR_FQDN}/${HARBOR_PJNAME}/${image}:latest
  check_status "failed to docker push"
  echo ""
done
```

## Manifest ファイルを取得

作業実施サーバ: 管理クライアント

```bash
# run manifests container
docker rmi ${DOCKERHUB_USERNAME}/vmw-pso-portal-manifests:latest
docker pull ${DOCKERHUB_USERNAME}/vmw-pso-portal-manifests:latest
docker run --rm --name manifests -it -d ${DOCKERHUB_USERNAME}/vmw-pso-portal-manifests:latest sleep infinity
docker ps
  # -> manifests コンテナが起動していること

# get manifests file
docker exec -it manifests ls -l /cloud-hub-manifests.tar.gz
cd; rm -rf cloud-hub-manifests*
docker cp manifests:/cloud-hub-manifests.tar.gz .
ll cloud-hub-manifests.tar.gz
tar zxvf cloud-hub-manifests.tar.gz
ll cloud-hub-manifests

# stop container
docker stop manifests
docker ps -a
  # -> container が起動していないことを確認

# Logout
docker logout
cat ~/.docker/config.json
```

## Manifest ファイル修正 (Harbor, Envoy)

作業実施サーバ: 管理クライアント

```bash
# Backup
cd
ll -d cloud-hub-manifests*
cp -pr cloud-hub-manifests cloud-hub-manifests.bak
ll -d cloud-hub-manifests*
cd cloud-hub-manifests

# Harbor の FQDN 変更
echo ${HARBOR_FQDN}
  # -> 値が設定されていること

for yaml in $(find . -type f -name "*.yaml"); do
  echo "=== ${yaml}"
  sed -i -e "s/harbor2.home.ndeguchi.com/${HARBOR_FQDN}/g" ${yaml}
done

# Envoy の FQDN 変更
echo ${ENVOY_FQDN}
  # -> 値が設定されていること

for yaml in $(find . -type f -name "*.yaml"); do
  echo "=== ${yaml}"
  sed -i -e "s/vmw-portal.home.ndeguchi.com/${ENVOY_FQDN}/g" ${yaml}
done

# diff
diff -ru ../cloud-hub-manifests.bak .
```

## VMRC 用ユーザ作成

vCenter サーバで VMRC 接続用ユーザを作成する

- ユーザ作成
  - ![img](img/50_vmrc_add_user.png)
- ロール作成
  - `仮想マシン` -> `相互作用` -> `コンソールとの相互作用` の権限を付与
  - ![img](img/51_vmrc_add_role.png)
- ユーザに権限付与 
  - 「子へ伝達」にチェックを入れること
  - ![img](img/52_vmrc_role_bind.png)

## VMRC 用ユーザ情報を設定

```bash
# 上で作成した VMRC 用ユーザの Username と Password を設定
vmrc_username=pso-portal-vmrc@vsphere.local
vmrc_password=VMware1!

# base64 encode
vmrc_username_enc=$(echo -n ${vmrc_username} | base64)
vmrc_password_enc=$(echo -n ${vmrc_password} | base64)

echo ${vmrc_username_enc}
echo ${vmrc_password_enc}

echo ${vmrc_username_enc} | base64 -d
echo ${vmrc_password_enc} | base64 -d

# replace
sed -i -e "s/VCENTER_USER_FOR_VMRC: .*$/VCENTER_USER_FOR_VMRC: \"${vmrc_username_enc}\"/g" be-vcenter-vm.yaml
sed -i -e "s/VCENTER_PASSWORD_FOR_VMRC: .*$/VCENTER_PASSWORD_FOR_VMRC: \"${vmrc_password_enc}\"/g" be-vcenter-vm.yaml

# diff
diff -u ../cloud-hub-manifests.bak/be-vcenter-vm.yaml ./be-vcenter-vm.yaml
```

## Generate a Certificate Authority Certificate

```bash
cd /root/cloud-hub-manifests/
mkdir cert
cd cert
echo ${ENVOY_FQDN}
  # -> 値が設定されていること

# 1. Generate a CA certificate private key.
openssl genrsa -out ca.key 4096

ll ca.key
  # -> ファイルが存在することを確認

# 2. Generate the CA certificate.
openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/C=/ST=/L=/O=/OU=/CN=${ENVOY_FQDN}" \
 -key ca.key \
 -out ca.crt
  
  # -> 以下のログが複数行出力されるが問題無し
  #    "req: No value provided for subject name attribute "XXX", skipped"

ll ca.crt
  # -> ファイルが存在することを確認
```


## Generate a Server Certificate

```bash
# 1. Generate a private key.
openssl genrsa -out ${ENVOY_FQDN}.key 4096

ll ${ENVOY_FQDN}.key
  # -> ファイルが存在することを確認

# 2. Generate a certificate signing request (CSR).
openssl req -sha512 -new \
    -subj "/C=/ST=/L=/O=/OU=/CN=${ENVOY_FQDN}" \
    -key ${ENVOY_FQDN}.key \
    -out ${ENVOY_FQDN}.csr

  # -> 以下のログが複数行出力されるが問題無し
  #    "req: No value provided for subject name attribute "XXX", skipped"

ll ${ENVOY_FQDN}.csr
  # -> ファイルが存在することを確認

# 3. Generate an x509 v3 extension file.
cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=${ENVOY_FQDN}
EOF

cat v3.ext

# 4. Use the v3.ext file to generate a certificate
openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -in  ${ENVOY_FQDN}.csr \
    -out ${ENVOY_FQDN}.crt

ll ${ENVOY_FQDN}.crt
  # -> ファイルが存在することを確認

openssl x509 -text -noout -in ${ENVOY_FQDN}.crt
openssl x509 -text -noout -in ${ENVOY_FQDN}.crt | grep -e "Issuer:" -e "Subject:"
```

v3.ext に設定した SAN が設定されていることを確認

```text
<出力例>
        Issuer: CN = vmw-portal.home.ndeguchi.com
        Subject: CN = vmw-portal.home.ndeguchi.com
```

```bash
openssl x509 -text -noout -in ${ENVOY_FQDN}.crt | grep -A 1 "Subject Alternative Name"
```

v3.ext に設定した SAN が設定されていることを確認

```text
            X509v3 Subject Alternative Name:
                DNS:vmw-portal.home.ndeguchi.com
```

## CA 証明書を Trust Anchor に登録

```bash
# get list before update
trust list > trust_list_before.txt
ll trust_list_before.txt
cat trust_list_before.txt

# update
cp ca.crt /etc/pki/ca-trust/source/anchors/ca-envoy.crt
update-ca-trust

# get list after update
trust list > trust_list_after.txt
ll trust_list_after.txt
cat trust_list_after.txt

# diff
diff trust_list_before.txt trust_list_after.txt
```

Envoy の CA 証明書が差分として出力されること

```text
<出力例>
6a7,12
> pkcs11:id=%44%5A%7F%11%89%02%DB%44%1A%5A%9D%B2%28%DA%51%EF%0B%DD%71%28;type=cert
>     type: certificate
>     label: vmw-portal.home.ndeguchi.com
>     trust: anchor
>     category: authority
>
```

## Manifest ファイル修正 (TLS)

```bash
cd /root/cloud-hub-manifests
ll cert/${ENVOY_FQDN}*

cat cert/${ENVOY_FQDN}.crt | base64 | sed -e "s/^/    /g" >> httpproxy.yaml
echo "- - - - - - - - - - - - - - - - - - - - - - - - - " >> httpproxy.yaml
cat cert/${ENVOY_FQDN}.key | base64 | sed -e "s/^/    /g" >> httpproxy.yaml

vim httpproxy.yaml
```

追記した証明書を以下フォーマットになるよう修正

```text
<フォーマット>
---
apiVersion: v1
kind: Secret
metadata:
  namespace: vmw-pso-portal
  name: envoy-tls
type: kubernetes.io/tls
data:
  tls.crt: |
    (${ENVOY_FQDN}.crtの中身)
  tls.key: |
    (${ENVOY_FQDN}.keyの中身)
```

```bash
# 差分確認
diff -u ../cloud-hub-manifests.bak/httpproxy.yaml httpproxy.yaml

# cat
cat httpproxy.yaml
```

## デプロイ

作業実施サーバ: 管理クライアント

```bash
# 動作確認用リソース削除
kubectl get all
kubectl delete -f ~/httpproxy-test.yaml
kubectl delete deployment nginx
kubectl delete service nginx
kubectl get all

# 差分確認
diff -ru ../cloud-hub-manifests.bak .

# 適用する yaml ファイルを cat
for yaml in $(find . -name "*.yaml"); do
  echo "========== ${yaml} =========="
  cat ${yaml}
  echo ""
done

# namespace 作成
k apply -f ns-vmw-pso-portal.yaml

# PostgreSQL デプロイ
kubectl apply -f postgres.yaml
watch kubectl get pv,pvc,pod,svc -n vmw-pso-portal

# 適用する yaml の配列作成
yamls=("be-history.yaml" "be-inventory.yaml" "be-notice.yaml" "be-nsx-lb.yaml" \
       "be-portal-auth.yaml" "be-vcenter-vm.yaml" "bff.yaml" "fe.yaml" \
       "be-console-openresty.yaml" "httpproxy.yaml")

# 適用
for yaml in ${yamls[@]}; do
  echo "----- ${yaml} -----"
  k apply -f ${yaml}
  echo ""
done

watch kubectl get deploy,po,svc,httpproxy -n vmw-pso-portal

# cronjob
kubectl apply -f cronjob.yaml
kubectl get cronjob -n vmw-pso-portal
watch kubectl get pod -n vmw-pso-portal

kubectl get pod -n vmw-pso-portal
kubectl logs $(kubectl get pod -n vmw-pso-portal | awk '{ print $1 }' | grep be-history-detect-system-errors | tail -n 1) -n vmw-pso-portal
  # -> 204 NoContent が応答されていること
kubectl logs $(kubectl get pod -n vmw-pso-portal | awk '{ print $1 }' | grep vm-refresh | tail -n 1) -n vmw-pso-portal
  # -> 200 OK が応答されていること
```

## Seed データ投入

作業実施サーバ: 管理クライアント

```bash
kubectl apply -f seed/be-portal-auth-seed.yaml
kubectl get pod -n vmw-pso-portal -w | grep seed
kubectl logs $(kubectl get pod -n vmw-pso-portal | awk '{ print $1 }' | grep be-portal-auth-seed | tail -n 1) -n vmw-pso-portal
```

以下ログが出力されていること

```text
Start generate seeds
End generate seeds
```

```bash
kubectl delete -f seed/be-portal-auth-seed.yaml
```

## GUI ログイン

作業実施サーバ: 管理クライアント

- 管理クライアントの Firefox から Envoy の FQDN にアクセスし ID: `system_admin`, PW: `system_admin` でログインできることを確認する。
- パスワードを変更する

## 自動復旧確認

作業実施サーバ: 管理クライアント

```bash
kubectl get pod -n vmw-pso-portal
kubectl delete pod --all -n vmw-pso-portal
watch kubectl get pod -n vmw-pso-portal
```

Firefoxで一度ログアウトし再度ログインする。
この時、変更したパスワードでログインできることを確認する。（DBデータの永続性確認）


## fluentbit インストール

作業実施サーバ: 管理クライアント

```bash
# Helm コマンドインストール
cd
curl -O https://get.helm.sh/helm-v3.13.2-linux-amd64.tar.gz
tar -zxvf helm-v3.13.2-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/
helm version

# FluentBit インストール
helm repo list
helm repo add fluent https://fluent.github.io/helm-charts
  # -> "fluent" has been added to your repositories

helm show values fluent/fluent-bit > fluent-bit-values.yaml
cp -p fluent-bit-values.yaml fluent-bit-values.yaml.org
vim fluent-bit-values.yaml
```

```text
   inputs: |
     [INPUT]
         Name tail
-        Path /var/log/containers/*.log
+        Path /var/log/containers/*_vmw-pso-portal_*.log
         multiline.parser docker, cri
         Tag kube.*
         Mem_Buf_Limit 5MB
         Skip_Long_Lines On

-    [INPUT]
-        Name systemd
-        Tag host.*
-        Systemd_Filter _SYSTEMD_UNIT=kubelet.service
-        Read_From_Tail On
-
   ## https://docs.fluentbit.io/manual/pipeline/filters
   filters: |
     [FILTER]
@@ -387,23 +381,24 @@
         Keep_Log Off
         K8S-Logging.Parser On
         K8S-Logging.Exclude On
+    [FILTER]
+        name       nest
+        match      kube.*
+        operation  lift
+        nest_under kubernetes
+        add_prefix kubernetes_
+

   ## https://docs.fluentbit.io/manual/pipeline/outputs
   outputs: |
     [OUTPUT]
-        Name es
-        Match kube.*
-        Host elasticsearch-master
-        Logstash_Format On
-        Retry_Limit False
-
-    [OUTPUT]
-        Name es
-        Match host.*
-        Host elasticsearch-master
-        Logstash_Format On
-        Logstash_Prefix node
-        Retry_Limit False
+        name                 syslog
+        match                kube.*
+        host                 192.168.12.4
+        syslog_message_key   log
+        syslog_hostname_key  kubernetes_namespace_name
+        syslog_appname_key   kubernetes_pod_name
+        syslog_procid_key    kubernetes_container_name

   ## https://docs.fluentbit.io/manual/administration/configuring-fluent-bit/classic-mode/upstream-servers
   ## This configuration is deprecated, please use `extraFiles` instead.
```

```bash
diff -u fluent-bit-values.yaml.org fluent-bit-values.yaml

kubectl create ns fluent-bit
helm install fluent-bit fluent/fluent-bit -f fluent-bit-values.yaml -n fluent-bit
watch kubectl get pod -n fluent-bit
```

fluent-bit の pod が起動するまで待機する。

```text
<出力例>
NAME               READY   STATUS    RESTARTS   AGE
fluent-bit-vf2wn   1/1     Running   0          50s
fluent-bit-z5bln   1/1     Running   0          50s
```

