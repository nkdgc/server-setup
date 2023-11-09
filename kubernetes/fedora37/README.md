# Fedora37 + Kubernetes + Proxy

Proxy経由でインターネット疎通できる Fedora37 の上に kubeadm で Kubernetes を構築する。 \
Proxyサーバは `192.168.13.2:8080` である前提で手順を記載するため、適宜読み替えて実施。

## Fedora 構築

- 以下の構成で Fedora を 5 台構築する。（ControlPlane: 3台, WorkerNode: 2台）
  - 仮想マシンスペック
    - CPU: 2 core
    - Mem: 4 GB
    - Disk: 80 GB
  - インストールメディア
    - Fedora-Server-dvd-x86_64-37-1.7.iso


- インストール時に以下を有効化する
  - root アカウントを有効化
  - パスワードによるroot SSHログインを許可
  - ![img](img/01_root_user.png)
  - ![img](img/02_FedoraInstallation.png)

- コンソールから root ユーザでログインし ホスト名 / IP アドレス / Gateway / DNS を変更する。本手順では以下を前提としてコマンドを記載するため、環境に応じて適宜読み替えて実施すること。

  | \# | ホスト名 | IPアドレス |
  | :---: | :---: | :---: |
  | ControlPlane#1 | k8s-cp01 | 192.168.13.21 |
  | ControlPlane#2 | k8s-cp02 | 192.168.13.22 |
  | ControlPlane#3 | k8s-cp03 | 192.168.13.23 |
  | WorkerNode#1 | k8s-worker01 | 192.168.13.24 |
  | WorkerNode#2 | k8s-worker02 | 192.168.13.25 |
  | WorkerNode#3 | k8s-worker03 | 192.168.13.26 |

  ```bash
  # コマンド例
  hostnamectl set-hostname k8s-cp01
  ip a
  nmcli connection modify ens192 ipv4.addresses 192.168.13.21/24
  nmcli connection modify ens192 ipv4.gateway 192.168.13.1
  nmcli connection modify ens192 ipv4.dns 192.168.13.2
  nmcli connection modify ens192 ipv4.method manual
  nmcli connection down ens192
  nmcli connection up ens192
  ip a
  ```

## Fedora の Proxy 設定

実施対象サーバ：5台全て

```bash
vim /etc/environment
```

```
http_proxy="http://192.168.13.2:8080/"
https_proxy="http://192.168.13.2:8080/"
HTTP_PROXY="http://192.168.13.2:8080/"
HTTPS_PROXY="http://192.168.13.2:8080/"
no_proxy="localhost,192.168.13.0/24,vip-k8s-master.home.ndeguchi.com"
NO_PROXY="localhost,192.168.13.0/24,vip-k8s-master.home.ndeguchi.com"
```

- 192.168.13.2:8080
  - Proxy サーバのIP・ポート番号を指定
- vip-k8s-master.home.ndeguchi.com
  - Kubernetes の API サーバとして指定するドメイン名を指定

## Swap Off

実施対象サーバ：5台全て

```bash
sudo dnf remove -y zram-generator-defaults
sudo swapoff -a
```

## Forwarding/Bridge 許可

実施対象サーバ：5台全て

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay 

modprobe br_netfilter

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
```

## 再起動

実施対象サーバ：5台全て

```bash
shutdown -r now
```

## 確認

実施対象サーバ：5台全て

```bash
env | grep -i proxy
```

```
<出力例>
no_proxy=localhost,192.168.13.0/24,vip-k8s-master.home.ndeguchi.com
https_proxy=http://192.168.13.2:8080/
NO_PROXY=localhost,192.168.13.0/24,vip-k8s-master.home.ndeguchi.com
HTTPS_PROXY=http://192.168.13.2:8080/
HTTP_PROXY=http://192.168.13.2:8080/
http_proxy=http://192.168.13.2:8080/
```

```
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
```

```
<出力例>
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
```


## Docker Engine Install

実施対象サーバ：5台全て

```bash
# 古いバージョンのDocker パッケージを削除
dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine

# リポジトリを追加
dnf -y install dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

# Docker Engine をインストール
dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Docker Engine を起動
systemctl start docker
systemctl enable docker
systemctl status docker 
docker ps
```

## Docker の Proxy 設定

実施対象サーバ：5台全て

```bash
# 設定
mkdir -p /etc/systemd/system/docker.service.d
vim /etc/systemd/system/docker.service.d/http-proxy.conf
```

```
[Service]
Environment="HTTP_PROXY=http://192.168.13.2:8080"
Environment="HTTPS_PROXY=http://192.168.13.2:8080"
Environment="NO_PROXY=localhost,192.168.13.0/24,vip-k8s-master.home.ndeguchi.com"
```

- 192.168.13.2:8080
  - Proxy サーバのIP・ポート番号を指定
- vip-k8s-master.home.ndeguchi.com
  - Kubernetes の API サーバとして指定するドメイン名を指定

```bash
# 反映
systemctl daemon-reload
systemctl restart docker
systemctl status docker

# 設定値確認
systemctl show --property=Environment docker
```

```
<出力例>
Environment=HTTP_PROXY=http://192.168.13.2:8080 HTTPS_PROXY=http://192.168.13.2:8080 NO_PROXY=localhost,192.168.13.0/24,vip-k8s-master.home.ndeguchi.com
```

```bash
# 動作確認
docker run --rm hello-world
```

```
<出力例>
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
719385e32844: Pull complete
Digest: sha256:88ec0acaa3ec199d3b7eaf73588f4518c25f9d34f58ce9a0df68429c5af48e8d
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/
```

## cri-dockerd のインストール

実施対象サーバ：5台全て

```bash
# 前提パッケージインストール
dnf install -y git make go

# git コマンドの proxy 設定(環境に合わせてproxyサーバのIP/PortNoを変更すること)
git config --global http.proxy http://192.168.13.2:8080

# cri-dockerd をダウンロード
git clone https://github.com/Mirantis/cri-dockerd.git

# cri-dockerd をビルド
cd cri-dockerd
make cri-dockerd

# cri-dockerd をインストール
mkdir -p /usr/local/bin
install -o root -g root -m 0755 cri-dockerd /usr/local/bin/cri-dockerd
install packaging/systemd/* /etc/systemd/system
sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
systemctl daemon-reload
systemctl enable cri-docker.service 
systemctl start  cri-docker.socket
systemctl status cri-docker.socket
```


## kubeadm, kubectl, kubelet のインストール

実施対象サーバ：5台全て

```bash
# リポジトリ追加
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
EOF

cat /etc/yum.repos.d/kubernetes.repo

# Selinux を permissive モードに変更する
getenforce
setenforce 0
getenforce

cat /etc/selinux/config
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
cat /etc/selinux/config

# Kubeadm、kubectl、kubeletをインストール
dnf install -y kubelet kubeadm kubectl
systemctl status kubelet
systemctl start kubelet
systemctl enable kubelet
systemctl status kubelet
# 起動しておらず code=exited, status=1/FAILURE のエラーが出力されているが問題無し。
```

## DNS登録

- API サーバとして使用するドメイン名とVIPをDNSサーバに登録する。本手順では以下を設定するものとして手順を記載する。
  | ドメイン名 | IPアドレス |
  | --- | --- |
  | vip-k8s-master.home.ndeguchi.com | 192.168.13.19 |


## HAProxy(LB) のインストール

実施対象サーバ：ControlPlane#1-3 の 3 台のみで実施 **(注意)**

```bash
dnf install -y haproxy keepalived
```

## HAProxy(LB) の設定・起動 - ControlPlane#1

実施対象サーバ：ControlPlane#1 のみで実施 **(注意)**

```bash
vim /etc/keepalived/check_apiserver.sh
```

```bash
#!/bin/sh
APISERVER_VIP=192.168.13.19
APISERVER_DEST_PORT=6443
errorExit() {
  echo "*** $*" 1>&2
  exit 1
}
curl --silent --max-time 2 --insecure https://localhost:${APISERVER_DEST_PORT}/ -o /dev/null || errorExit "Error GET https://localhost:${APISERVER_DEST_PORT}/"
if ip addr | grep -q ${APISERVER_VIP}; then
  curl --silent --max-time 2 --insecure https://${APISERVER_VIP}:${APISERVER_DEST_PORT}/ -o /dev/null || errorExit "Error GET https://${APISERVER_VIP}:${APISERVER_DEST_PORT}/"
fi
```

- 192.168.13.19
  - API サーバの VIP を指定

```bash
# 作成したcheck_apiserver.shファイルに実行する権限を付与する
chmod +x /etc/keepalived/check_apiserver.sh

# keepalived を設定
cp /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf-org
sh -c '> /etc/keepalived/keepalived.conf'
vim /etc/keepalived/keepalived.conf
```

```
! /etc/keepalived/keepalived.conf
! Configuration File for keepalived
global_defs {
  router_id LVS_DEVEL
}
vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 3
  weight -2
  fall 10
  rise 2
}

vrrp_instance VI_1 {
  state MASTER
  interface ens192
  virtual_router_id 151
  priority 255
  authentication {
    auth_type PASS
    auth_pass P@##D321!
  }
  virtual_ipaddress {
    192.168.13.19/24
  }
  track_script {
    check_apiserver
  }
}
```

- 192.168.13.19/24
  - API サーバの VIP/Mask を指定

```bash
# haproxy を修正する
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg-org
vim /etc/haproxy/haproxy.cfg
```

defaults セクションの1つしたのセクション以降を全て削除し、以下の内容を追記する

```
#---------------------------------------------------------------------
# apiserver frontend which proxys to the masters
#---------------------------------------------------------------------
frontend apiserver
    bind *:8443
    mode tcp
    option tcplog
    default_backend apiserver
#---------------------------------------------------------------------
# round robin balancing for apiserver
#---------------------------------------------------------------------
backend apiserver
    option httpchk GET /healthz
    http-check expect status 200
    mode tcp
    option ssl-hello-chk
    balance roundrobin
    server k8s-cp01 192.168.13.21:6443 check
    server k8s-cp02 192.168.13.22:6443 check
    server k8s-cp03 192.168.13.23:6443 check
```

- 192.168.13.21 〜 192.168.13.23
  - ControlPlane#1-3 の IP アドレスを指定


```bash
# haproxy.cfg の妥当性確認
haproxy -c -f /etc/haproxy/haproxy.cfg
# -> "Configuration file is valid" が出力されること。
#    WARNING が出力されるが問題なし。

# keepalivedとhaproxyを起動
systemctl status keepalived
systemctl start keepalived
systemctl enable keepalived
systemctl status keepalived

systemctl status haproxy
systemctl start haproxy
systemctl enable haproxy
systemctl status haproxy

# NICにVIPが設定されることを確認する
ip a
```

```
<出力例>
2: ens192: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:50:56:95:1b:e6 brd ff:ff:ff:ff:ff:ff
    altname enp11s0
    inet 192.168.13.21/24 brd 192.168.13.255 scope global noprefixroute ens192 ←ControlPlane#1 のIP★
       valid_lft forever preferred_lft forever
    inet 192.168.13.19/24 scope global secondary ens192 ←VIP★
       valid_lft forever preferred_lft forever
```


## HAProxy(LB) の設定・起動 - ControlPlane#2

実施対象サーバ：ControlPlane#2 のみで実施 **(注意)**

```bash
FIXME: SCP で CP01 からファイルを取得して一部修正する手順を書く
```

## HAProxy(LB) の設定・起動 - ControlPlane#3

実施対象サーバ：ControlPlane#3 のみで実施 **(注意)**

```bash
FIXME: SCP で CP01 からファイルを取得して一部修正する手順を書く
```

## Kubernetes クラスタの起動

実施対象サーバ：ControlPlane#1 のみで実施 **(注意)**

```
kubeadm init --control-plane-endpoint "vip-k8s-master.home.ndeguchi.com:8443" --upload-certs --pod-network-cidr 10.20.0.0/16 --cri-socket=unix:///var/run/cri-dockerd.sock --v 9
```

- vip-k8s-master.home.ndeguchi.com
  - API サーバのドメイン名を指定

```
<出力例: 上記コマンドの実行に成功すると、標準出力の末尾に以下と同様の情報が出力される>
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of the control-plane node running the following command on each as root:

  kubeadm join vip-k8s-master.home.ndeguchi.com:8443 --token hlnwdd.ekfrwnf9f37htwmr \
    --discovery-token-ca-cert-hash sha256:4bb9307b467ab7bf6ec039b1b4d4ec49ece598080b2979c4fb84e47c8f87cdc6 \
    --control-plane --certificate-key c6586d3f6e170bf8951bf2670bf56e4a4177b1047c3d5e6076406ae2c7f7ed22

Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use
"kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join vip-k8s-master.home.ndeguchi.com:8443 --token hlnwdd.ekfrwnf9f37htwmr \
  --discovery-token-ca-cert-hash sha256:4bb9307b467ab7bf6ec039b1b4d4ec49ece598080b2979c4fb84e47c8f87cdc6
```

