#!/bin/bash
#azkaban安装

#环境设置:u 不存在的变量报错;e 发生错误退出;pipefail 管道有错退出
set -euo pipefail

#########要更改变的变量#######
###安装类型,可输入server,client.默认client
TYPE=${1:-"client"}
###服务端;备份机
SERVER_IP=""
###客户端;源机
CLIENT_IP=""

###服务端共享的目录
SERVERM_DIR="/cache1/web"
DIR_OWNER="www"
UID=`id -u ${DIR_OWNER}`
GID=`id -g ${DIR_OWNER}`
###客户端挂载目录
CLIENT_MOUNT_DIR="/webbackup"
###要备份的目录
BACKUP_DIR="/home"


##############################
if [ ! -f "/usr/sbin/showmount" ]; then
    yum install nfs-utils
fi

if [ "$TYPE" == 'server' ]; then
    echo "#########HOST设置#######"
    HOSTNAME=`hostname`
    IP=``
    echo "#########NFS服务端设置#######"
    echo "设置/etc/exports 完成"
cat > /etc/exports <<EOF
${SERVERM_DIR} ${CLIENT_IP}(rw,sync,anonuid=$UID,anongid=$GID)
EOF
    chown -R ${DIR_OWNER}:${DIR_OWNER} ${SERVERM_DIR} 
    echo "#########启动NFS服务#######"
    chkconfig rpcbind on
    chkconfig nfs on
    service rpcbind start
    service nfs start
    echo "#########服务启动信息#######"
    rpcinfo -p
    echo "#########配置信息#######"
    exportfs -rv
    showmount -e

fi

if [ "$TYPE" == 'client' ]; then
    if [ ! -d "${CLIENT_MOUNT_DIR}" ]; then
        mkdir -p ${CLIENT_MOUNT_DIR}
    fi
    echo "#########启动rpcbind服务#######"
    chkconfig rpcbind on
    service rpcbind start
    echo "#########查看服务端共享目录#######"
    showmount -e ${SERVER_IP}
    echo "########挂载目录#######"
    df -h | grep "${CLIENT_MOUNT_DIR}"  && ISSET="true" || ISSET="false"
    if [  "$ISSET" == "false" ]; then
        echo "mount -t nfs4 ${SERVER_IP}:${SERVERM_DIR} ${CLIENT_MOUNT_DIR}"
        mount -t nfs4 ${SERVER_IP}:${SERVERM_DIR} ${CLIENT_MOUNT_DIR}
        df -h
    else
        df -h
    fi
 
    echo "########安装rsync用来本地复制#######"
    if [ ! -f "/etc/xinetd.d/rsync" ]; then
        yum install -y rsync
        rm -f /etc/rsync*
    fi
    #-a 同rlptgoD;-r 所有子目录;-l 软链接;-p 保留权限;-t保留时间;-g 组信息;-o 用户信息;-D 设备信息
    #-v 详细输出;-u 仅仅进行更新;-z 传输时压缩;-P --partial 保留那些因故没有完全传输的文件，以是加快随后的再次传输
    rsync -rltuvP ${BACKUP_DIR} ${CLIENT_MOUNT_DIR}
fi
