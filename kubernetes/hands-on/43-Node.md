# Hands-on 43-1 : Node 情報取得

```bash
# Node 一覧取得
kubectl get node
  # -> クラスタに登録されているマシンの台数は何台か確認しましょう
  #    control-plane, node はそれぞれ何台か確認しましょう

# Node 一覧取得(wide)
kubectl get node -o wide
  # -> (ControlPlaneではなく）Node の Name を確認（複数存在するうちの何れでも構いません）

# Node 詳細情報取得
kubectl get node <Node の Name> -o yaml
  # -> CPU/Memory の容量を確認しましょう(status.capacity)
  #    Node の CPU アーキテクチャを確認しましょう(status.nodeInfo.architecture)
  #    Node の OS を確認しましょう(status.nodeInfo.osImage)
  #    Node内で保持しているコンテナイメージのリストを確認しましょう(status.images)
```


