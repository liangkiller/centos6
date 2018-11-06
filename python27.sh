#!/bin/bash
#python2.7,setuptools,pip

#环境设置:u 不存在的变量报错;e 发生错误退出;pipefail 管道有错退出
set -euo pipefail

echo "==========PATH 设置=========="
if [ ! -f "/etc/profile.d/path.sh" ]; then
cat > /etc/profile.d/path.sh <<EOF
export PATH=\$PATH
export TMOUT=1800
if [[ -n "\$SSH_CLIENT"  ]] || [[ -n "\$SSH_CONNECTION" ]]; then
        export TMOUT=3600
fi
EOF
fi

echo "==========依赖包安装=========="
if [ ! -f "/usr/include/tk-private/generic/tk.h" ]; then
    yum install -y zlib-devel openssl-devel ncurses-devel ncurses sqlite-devel readline-devel bzip2-devel tk-devel gdbm-devel xz-devel unzip
fi

echo "==========PYTHON,SETUPTOOLS,PIP,安装=========="
cd /var/tmp
if [ ! -f "/usr/local/python27/bin/python2.7" ]; then
    wget --no-check-certificate https://www.python.org/ftp/python/2.7.15/Python-2.7.15.tgz
    wget --no-check-certificate https://files.pythonhosted.org/packages/ef/1d/201c13e353956a1c840f5d0fbf0461bd45bbd678ea4843ebf25924e8984c/setuptools-40.2.0.zip
    wget --no-check-certificate https://files.pythonhosted.org/packages/ae/e8/2340d46ecadb1692a1e455f13f75e596d4eab3d11a57446f08259dee8f02/pip-10.0.1.tar.gz
    rm -rf Python-2.7.15
    tar -zxf Python-2.7.15.tgz
    cd Python-2.7.15
    ./configure --prefix=/usr/local/python27 --enable-optimizations
    make && make install
fi
echo "==========设置PYTHON环境变量=========="

`grep "PYTHONHOME" /etc/profile.d/path.sh` && ISSET="true" || ISSET="false"
if [  "$ISSET" == "false" ]; then
    sed -i 's#PATH=#PATH=/usr/local/python27/bin:#' /etc/profile.d/path.sh
    source /etc/profile.d/path.sh
fi


echo "==========setuptools安装=========="
cd /var/tmp
rm -rf setuptools-40.2.0
unzip setuptools-40.2.0.zip
cd setuptools-40.2.0
python setup.py install

echo "==========PIP安装=========="
cd /var/tmp
rm -rf  pip-10.0.1
tar -zxf pip-10.0.1.tar.gz
cd  pip-10.0.1
python setup.py install

echo "==========PIP设置=========="
mkdir $HOME/.pip/
cat > $HOME/.pip/pip.conf  <<EOF
[global]
index-url = https://mirrors.aliyun.com/pypi/simple/
[install]
trusted-host=mirrors.aliyun.com
[list]
format=columns
EOF

python -V
pip install --upgrade pip

###支持crontab
grep "PATH" /var/spool/cron/root  && ISSET="true" || ISSET="false"
if [  "$ISSET" == "false" ]; then
    sed -i '1i\SHELL=/bin/bash\nPATH=/sbin:/bin:/usr/sbin:/usr/bin\nMAILTO=root\nHOME=/\n' /var/spool/cron/root
    ln -s /usr/local/python27/bin/python2.7 /usr/sbin/python
fi

source /etc/profile
