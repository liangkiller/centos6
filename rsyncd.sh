#!/bin/bash
#rsync

#环境设置:u 不存在的变量报错;e 发生错误退出;pipefail 管道有错退出
set -euo pipefail

#########要更改变的变量#######
###安装类型:server,client
TYPE=""

DIR="/opt/scripts"
SERVER_PASS_FILE="$DIR/rsyncd.secrets"
CLIENT_PASS_FILE="$DIR/rsync_client.pwd"
USER=""
PASS=""

MODULE_NAME="mysql"
MODULE_UID="mysql"
MODULE_GID="mysql"

CLIENT_IP=""
##############################

if [ ! -f "/usr/sbin/xinetd" ]; then
    yum install -y xinetd
fi

if [ ! -f "/etc/xinetd.d/rsync" ]; then
    yum install -y rsync
fi

rm -f /etc/rsync*
if [ ! -d "$DIR" ]; then
    mkdir -p  $DIR
fi

if [ "$TYPE" == 'server' ]; then
cat > /etc/rsyncd.conf << EOF
uid=root
gid=root
use chroot=no
max connections=10
timeout=600
strict modes=yes
port=873
pid file=/var/run/rsyncd.pid
lock file=/var/run/rsyncd.lock
log file=/var/log/rsyncd.log
[$MODULE_NAME]
path=/tmp/rsync_bak2
comment=rsync test logs
auth users=$USER
uid=${MODULE_UID}
gid=${MODULE_GID}
secrets file=${SERVER_PASS_FILE}
read only=no
list=no
hosts allow=$CLIENT_IP
hosts deny=0.0.0.0/32
EOF

echo "$USER:$PASS" > /opt/scripts/rsyncd.secrets
chmod 600 /opt/scripts/rsyncd.secrets


sed -i "s/log_on_success/#log_on_success/g" /etc/xinetd.conf
sed -i "s/yes/no/g" /etc/xinetd.d/rsync

service xinetd restart
fi

if [ "$TYPE" == 'client' ]; then
    echo "$PASS" > /opt/scripts/rsync_client.pwd
    chmod 600 /opt/scripts/rsync_client.pwd
fi
