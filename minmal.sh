#!/bin/bash

#环境设置:u 不存在的变量报错;e 发生错误退出;pipefail 管道有错退出
set -euo pipefail

yum group install -y "Development Tools"
yum install -y perl zlib-devel openssl-devel ncurses-devel ncurses bzip2-devel unzip
yum install -y wget  epel-release lrzsz screen

echo "#########时间同步#######"
if [ ! -f "/usr/sbin/ntpdate" ]; then
    yum install  -y ntp
    chkconfig ntpd on
fi

rm -f /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

ntpdate ntp1.aliyun.com
hwclock --systohc

echo "1 */6 * * * ntpdate ntp1.aliyun.com > /dev/null 2>&1" >> /var/spool/cron/root
echo "#########时间同步完成#######"

echo "#########关闭selinux#######"
grep 'SELINUX=disabled' /etc/selinux/config && ISSET="true" || ISSET="false"
if [ "$ISSET" == "false" ]; then
    echo "#########关闭selinux#########"
    sed -i 's;SELINUX=enforcing;SELINUX=disabled;'  /etc/selinux/config
    setenforce 0
else
    echo "#########selinux 已关闭#########"
fi
