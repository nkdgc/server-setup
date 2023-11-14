# Hands-on 40-1 : Cronjob 実行事前準備

```bash
# Krew インストール
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)

cat <<EOF >> ~/.bashrc
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
EOF

source ~/.bashrc

# kubectl の plugin: stern をインストール
kubectl krew install stern
kubectl stern --help
```

# Hands-on 40-2 : Cronjob 実行 (concurrencyPolicy=Allow)

```bash
cd
vim cronjob.yaml
```

```test
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cronjob-test-01
spec:
  schedule: "* * * * *"
  concurrencyPolicy: Allow
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
          - name: busybox
            image: busybox
            args:
            - /bin/sh
            - "-c"
            - "echo $(date) Cronjob start; sleep 90; echo $(date) Cronjob end"
```

```bash
cat cronjob.yaml
kubectl apply -f cronjob.yaml

kubectl get cronjob

# 以下コマンドを実行したうえで待機し、1分間隔で処理が起動することを確認
watch kubectl get pod
  # -> concurrencyPolicy: Allow のポリシーに従い多重実行されることを確認

# 以下コマンドを実行したうえで待機し、1分間隔で処理が起動することを確認
kubectl stern cronjob-test-01
```

# Hands-on 40-3 : Cronjob 実行 (concurrencyPolicy=Forbid)

```bash
# manifest修正
vim cronjob.yaml
  # -> 以下の通り変更する
  #    (変更前) concurrencyPolicy: Allow
  #    (変更後) concurrencyPolicy: Forbid

# 適用
kubectl apply -f cronjob.yaml

# 以下コマンドを実行したうえで待機し多重実行されないことを確認
kubectl stern cronjob-test-01
```

# Hands-on 40-4 : Cronjob 実行 (concurrencyPolicy=Replace)

```bash
# manifest修正
vim cronjob.yaml
  # -> 以下の通り変更する
  #    (変更前) concurrencyPolicy: Forbid
  #    (変更後) concurrencyPolicy: Replace

# 適用
kubectl apply -f cronjob.yaml

# 以下コマンドを実行したうえで待機し Start のログしか出力されなくなったことを確認
kubectl stern cronjob-test-01

# 削除
kubectl delete cronjob cronjob-test-01
kubectl get cronjob
watch kubectl get pod
```

