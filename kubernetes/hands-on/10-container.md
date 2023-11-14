# Hands-on 10-1 : nginx を実行

```bash
# nginx を起動
docker run -d -p <MyPortNo>:80 --name ${USER}-nginx nginx

# 起動しているか確認
docker ps | grep -e "CONTAINER ID" -e ${USER}-nginx
  # -> CONTAINER ID   IMAGE  COMMAND                   CREATED          STATUS          PORTS                                   NAMES
  #    55aa89290826   nginx  "/docker-entrypoint.…"   38 seconds ago   Up 38 seconds   0.0.0.0:8080->80/tcp, :::8080->80/tcp   ndeguchi-nginx

# アクセス
curl localhost:<MyPortNo>

# ログ確認
docker logs ${USER}-nginx

# 停止
docker stop ${USER}-nginx

# 停止したことを確認
docker ps -a | grep -e "CONTAINER ID" -e ${USER}-nginx
  # -> STATUS が Exited であること

# 削除
docker rm ${USER}-nginx

# 削除されていることを確認
docker ps -a | grep -e "CONTAINER ID" -e ${USER}-nginx
  # -> 存在しないこと
```

# Hands-on 10-2 : コンテナイメージを build しこれを実行

```bash
mkdir ~/myapp
cd ~/myapp
vim Dockerfile
```
```text
FROM nginx:latest
COPY ./index.html /usr/share/nginx/html
```
```bash
cat <<EOF > index.html
${USER}'s Nginx Page
EOF

cat index.html

docker build -t ${USER}-nginx:0.1 .

docker images | grep -e "REPOSITORY" -e "${USER}-nginx"
  # -> REPOSITORY      TAG     IMAGE ID       CREATED          SIZE
  #    ndeguchi-nginx  latest  a86e6cafd966   38 seconds ago   187MB

# 起動
docker run -d -p <MyPortNo>:80 --name ${USER}-nginx ${USER}-nginx:0.1

# 起動しているか確認
docker ps | grep -e "CONTAINER ID" -e ${USER}-nginx

# アクセス
curl localhost:<MyPortNo>

# 停止
docker stop ${USER}-nginx

# 停止したことを確認
docker ps -a | grep -e "CONTAINER ID" -e ${USER}-nginx
  # -> STATUS が Exited であること

# 削除
docker rm ${USER}-nginx

# 削除されていることを確認
docker ps -a | grep -e "CONTAINER ID" -e ${USER}-nginx
  # -> 存在しないこと
```
  
# Hands-on 10-3 : Harbor へ格納しこれを起動

- Harbor に Web ブラウザでアクセスし `admin` ユーザでログイン
- [NEW PROJECT] ボタンから新規プロジェクトを作成
  - Project Name: <ユーザ名>
  - Access Level: Public にチェックを入れる

```bash
# Harbor にログイン
docker login <Harbor FQDN>

# タグ付与
docker images | grep -e "REPOSITORY" -e "${USER}-nginx"
docker tag ${USER}-nginx:0.1 <Harbor FQDN>/${USER}/${USER}-nginx:0.1
docker images | grep -e "REPOSITORY" -e "${USER}-nginx"

# Harbor へ Push
docker push <Harbor FQDN>/${USER}/${USER}-nginx:0.1
```

- ブラウザでHarborにアクセスし格納できていることを確認

```bash
# ローカル環境からコンテナイメージを削除
docker images | grep -e "REPOSITORY" -e "${USER}-nginx"

docker rmi ${USER}-nginx:0.1 <Harbor FQDN>/${USER}/${USER}-nginx:0.1

docker images | grep -e "REPOSITORY" -e "${USER}-nginx"
  # -> 存在しないことを確認

# Harbor から pull
docker pull <Harbor FQDN>/${USER}/${USER}-nginx:0.1

# pull できていることを確認
docker images | grep -e "REPOSITORY" -e "${USER}-nginx"
  
# 起動
docker run -d -p <MyPortNo>:80 --name ${USER}-nginx <Harbor FQDN>/${USER}/${USER}-nginx

# 起動しているか確認
docker ps | grep -e "CONTAINER ID" -e ${USER}-nginx

# アクセス
curl localhost:<MyPortNo>

# 停止
docker stop ${USER}-nginx

# 停止したことを確認
docker ps -a | grep -e "CONTAINER ID" -e ${USER}-nginx
  # -> STATUS が Exited であること

# 削除
docker rm ${USER}-nginx

# 削除されていることを確認
docker ps -a | grep -e "CONTAINER ID" -e ${USER}-nginx
  # -> 存在しないこと
```

