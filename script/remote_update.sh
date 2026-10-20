#!/bin/bash
# 服务器端更新脚本：由 CNB web_trigger_deploy_server 流水线上传并执行
# 用法：bash /opt/update_commun.sh（代码包须先上传到 /opt/commun-server.tar.gz）
set -euo pipefail

export PATH=/usr/local/bin:/usr/local/sbin:/usr/bin
OLD=/opt/commun-server
NEW=/opt/commun-server.new
BAK=/opt/commun-server.bak

echo "==> 解包新代码"
rm -rf "$NEW" /opt/commun-server.tar.gz.dir
mkdir -p "$NEW"
tar xzf /opt/commun-server.tar.gz -C "$NEW"

echo "==> 保留运行时文件（密钥 / 日志 / 存储）"
mkdir -p "$NEW/log" "$NEW/tmp" "$NEW/storage"
# master.key / credentials 不在 git 仓库中，从当前部署继承；
# 如需强制使用仓库内版本，先删除服务器上 $OLD 中对应文件
for f in config/master.key config/credentials.yml.enc; do
  if [ -f "$OLD/$f" ] && [ ! -f "$NEW/$f" ]; then
    cp -a "$OLD/$f" "$NEW/$f"
  fi
done
[ -d "$OLD/storage" ] && cp -a "$OLD/storage/." "$NEW/storage/"

echo "==> 安装依赖"
cd "$NEW"
bundle install --jobs 2 --quiet
npm install --registry=https://mirrors.tencent.com/npm/ --silent || true
npm run build --silent || true

echo "==> 数据库迁移 + 资源预编译"
set -a
[ -f /etc/commun.env ] && . /etc/commun.env
set +a
bin/rails db:migrate --quiet
bin/rails assets:precompile --quiet

echo "==> 切换目录并重启服务"
systemctl stop commun commun-worker || true
rm -rf "$BAK"
mv "$OLD" "$BAK"
mv "$NEW" "$OLD"
systemctl start commun commun-worker

echo "==> 健康检查"
sleep 8
if curl -sf -o /dev/null http://127.0.0.1:3000/topics; then
  echo "DEPLOY_OK $(date '+%F %T')"
else
  echo "健康检查失败，回滚到上一版本..."
  systemctl stop commun commun-worker || true
  rm -rf "$OLD"
  mv "$BAK" "$OLD"
  systemctl start commun commun-worker
  echo "DEPLOY_FAILED_ROLLED_BACK"
  exit 1
fi
