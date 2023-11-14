# Hands-on 40-1 : Cronjob 実行

```bash
vim cronjob.yaml
```

```test
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cronjob-test-01
spec:
  schedule: "* * * * *"
  concurrencyPolicy: Forbid
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
            - "echo $(date) Cronjob start; sleep 5; echo $(date) Cronjob end"
```

```bash
cat cronjob.yaml
kubectl apply -f cronjob.yaml

kubectl get cronjob

# 以下コマンドを実行したうえで待機し、1分間隔で処理が起動することを確認
kubectl get pod -w

kubectl logs <直近起動したPodのPod名>

# 削除
kubectl delete cronjob cronjob-test-01
kubectl get cronjob
```

