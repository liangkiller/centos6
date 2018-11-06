#!/bin/bash
#php,nginx

#环境设置:u 不存在的变量报错;e 发生错误退出;pipefail 管道有错退出
set -euo pipefail

#########要更改变的变量#######
###安装路径
INSTALL_DIR="/usr/local"

###PHP版本
PHP_VERSION="5.6.38"
###NGINX版本
NG_VERION="1.12.0"
###web目录
WEB_DIR="/cache3/web"

###用户
WEB_USER="www"

###是否安装composer
IS_COMPOSER="false"

###是否安装EPEL源
IS_EPEL="true"
###是否清华源
IS_TUNA="true"
###是否安装PHP
IS_PHP="true"
IS_NG="true"

###下载地址
DOWN_URL=""

if [ -n "${DOWN_URL}" ]; then
    PHP_URL="${DOWN_URL}/php-${PHP_VERSION}.tar.gz"
    NG_URL="${DOWN_URL}/nginx-${NG_VERION}.tar.gz"
    COMPOSER_URL="${DOWN_URL}/composer.phar"
else
    PHP_URL="http://mirrors.sohu.com/php/php-${PHP_VERSION}.tar.gz"
    NG_URL="http://mirrors.sohu.com/nginx/nginx-${NG_VERION}.tar.gz"
    COMPOSER_URL="https://dl.laravel-china.org/composer.phar"
fi

##############################
if [ "${IS_EPEL}" == "true" ]; then
    echo "=========EPEL源=========="
    wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
fi

if [ "${IS_TUNA}" == "true" ]; then
    echo "=========清华源=========="
cat > /etc/yum.repos.d/tuna.repo <<EOF
[base]
name=CentOS-\$releasever - Base
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/\$releasever/os/\$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=\$releasever&arch=\$basearch&repo=os
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6

#released updates
[updates]
name=CentOS-\$releasever - Updates
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/\$releasever/updates/\$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=\$releasever&arch=\$basearch&repo=updates
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6

#additional packages that may be useful
[extras]
name=CentOS-\$releasever - Extras
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/\$releasever/extras/\$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=\$releasever&arch=\$basearch&repo=extras
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-\$releasever - Plus
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/\$releasever/centosplus/\$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=\$releasever&arch=\$basearch&repo=centosplus
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6

#contrib - packages by Centos Users
[contrib]
name=CentOS-\$releasever - Contrib
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/\$releasever/contrib/\$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=\$releasever&arch=\$basearch&repo=contrib
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
EOF
fi

###更新软件包缓存
yum makecache

if [ ! -d "${WEB_DIR}" ]; then
    mkdir -p ${WEB_DIR}
fi

grep "${WEB_USER}" /etc/passwd  && ISSET="true" || ISSET="false"
if [  "$ISSET" == "false" ]; then
    groupadd ${WEB_USER}
    useradd -M -s /sbin/nologin -g ${WEB_USER} ${WEB_USER}
fi


echo "=========依赖包=========="
if [ ! -f "/usr/bin/icu-config" ]; then
    yum install -y gcc gcc-c++ autoconf wget make libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel libidn libidn-devel curl libcurl
    yum install -y libcurl-devel 
    yum install -y openssl openssl-devel openldap openldap-devel nss_ldap openldap-clients openldap-servers  libicu-devel pcre* libmcrypt libmcrypt-devel libxslt libxslt-devel automake icu libicu libicu-devel
fi


echo "=========php-${PHP_VERSION}编译安装=========="
cd /var/tmp
if [ "${IS_PHP}" == "true" ]; then

if [ ! -f "php-${PHP_VERSION}.tar.gz" ]
then
    wget ${PHP_URL}
fi
if [ ! -d "${INSTALL_DIR}/php" ]; then
    tar -zxf php-${PHP_VERSION}.tar.gz
    cd php-${PHP_VERSION}
    ./configure --prefix=${INSTALL_DIR}/php --with-config-file-path=${INSTALL_DIR}/php/etc --with-config-file-scan-dir=${INSTALL_DIR}/php/conf.d --enable-fpm --with-fpm-user=${WEB_USER} --with-fpm-group=${WEB_USER} --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=${INSTALL_DIR}/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext --disable-fileinfo --enable-opcache --enable-intl --with-xsl --enable-mysqlnd

    make && make install
else
    echo "${INSTALL_DIR}/php 安装目录已存在"
fi

echo "=========php配置=========="
mkdir -p ${INSTALL_DIR}/php/{etc,conf.d}
rm -f ${INSTALL_DIR}/php/conf.d/*
cat > ${INSTALL_DIR}/php/etc/php.ini <<EOF
[PHP]
engine = On
short_open_tag = On
asp_tags = Off
precision = 14
output_buffering = 4096
zlib.output_compression = Off
implicit_flush = Off
unserialize_callback_func =
serialize_precision = 17
disable_functions = passthru,exec,system,chroot,scandir,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server
disable_classes =
zend.enable_gc = On
expose_php = Off
max_execution_time = 300
max_input_time = 60
memory_limit = 128M
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
display_errors = Off
display_startup_errors = Off
log_errors = On
log_errors_max_len = 1024
ignore_repeated_errors = Off
ignore_repeated_source = Off
report_memleaks = On
track_errors = Off
html_errors = On
variables_order = "GPCS"
request_order = "GP"
register_argc_argv = Off
auto_globals_jit = On
post_max_size = 50M
auto_prepend_file =
auto_append_file =
default_mimetype = "text/html"
default_charset = "UTF-8"
doc_root =
user_dir =
enable_dl = Off
file_uploads = On
upload_max_filesize = 50M
max_file_uploads = 20
allow_url_fopen = On
allow_url_include = Off
default_socket_timeout = 60
[CLI Server]
cli_server.color = On
[Date]
date.timezone = PRC
[filter]
[iconv]
[intl]
[sqlite]
[sqlite3]
[Pcre]
[Pdo]
[Pdo_mysql]
pdo_mysql.cache_size = 2000
pdo_mysql.default_socket=
[Phar]
[mail function]
SMTP = localhost
smtp_port = 25
mail.add_x_header = On
[SQL]
sql.safe_mode = Off
[ODBC]
odbc.allow_persistent = On
odbc.check_persistent = On
odbc.max_persistent = -1
odbc.max_links = -1
odbc.defaultlrl = 4096
odbc.defaultbinmode = 1
[Interbase]
ibase.allow_persistent = 1
ibase.max_persistent = -1
ibase.max_links = -1
ibase.timestampformat = "%Y-%m-%d %H:%M:%S"
ibase.dateformat = "%Y-%m-%d"
ibase.timeformat = "%H:%M:%S"
[MySQL]
mysql.allow_local_infile = On
mysql.allow_persistent = On
mysql.cache_size = 2000
mysql.max_persistent = -1
mysql.max_links = -1
mysql.default_port =
mysql.default_socket =
mysql.default_host =
mysql.default_user =
mysql.default_password =
mysql.connect_timeout = 60
mysql.trace_mode = Off
[MySQLi]
mysqli.max_persistent = -1
mysqli.allow_persistent = On
mysqli.max_links = -1
mysqli.cache_size = 2000
mysqli.default_port = 3306
mysqli.default_socket =
mysqli.default_host =
mysqli.default_user =
mysqli.default_pw =
mysqli.reconnect = Off
[mysqlnd]
mysqlnd.collect_statistics = On
mysqlnd.collect_memory_statistics = Off
[OCI8]
[PostgreSQL]
pgsql.allow_persistent = On
pgsql.auto_reset_persistent = Off
pgsql.max_persistent = -1
pgsql.max_links = -1
pgsql.ignore_notice = 0
pgsql.log_notice = 0
[Sybase-CT]
sybct.allow_persistent = On
sybct.max_persistent = -1
sybct.max_links = -1
sybct.min_server_severity = 10
sybct.min_client_severity = 10
[bcmath]
bcmath.scale = 0
[browscap]
[Session]
session.save_handler = files
session.use_strict_mode = 0
session.use_cookies = 1
session.use_only_cookies = 1
session.name = PHPSESSID
session.auto_start = 0
session.cookie_lifetime = 0
session.cookie_path = /
session.cookie_domain =
session.cookie_httponly =
session.serialize_handler = php
session.gc_probability = 1
session.gc_divisor = 1000
session.gc_maxlifetime = 1440
session.referer_check =
session.cache_limiter = nocache
session.cache_expire = 180
session.use_trans_sid = 0
session.hash_function = 0
session.hash_bits_per_character = 5
url_rewriter.tags = "a=href,area=href,frame=src,input=src,form=fakeentry"
[MSSQL]
mssql.allow_persistent = On
mssql.max_persistent = -1
mssql.max_links = -1
mssql.min_error_severity = 10
mssql.min_message_severity = 10
mssql.compatibility_mode = Off
mssql.secure_connection = Off
[Assertion]
[COM]
[mbstring]
[gd]
[exif]
[Tidy]
tidy.clean_output = Off
[soap]
soap.wsdl_cache_enabled=1
soap.wsdl_cache_dir="/tmp"
soap.wsdl_cache_ttl=86400
soap.wsdl_cache_limit = 5
[sysvshm]
[ldap]
ldap.max_links = -1
[mcrypt]
[dba]
[opcache]
[curl]
[openssl]
EOF

if [ ! -L "/usr/bin/php-fpm" ]; then
set +e
    ln -sf ${INSTALL_DIR}/php/bin/php /usr/bin/php
    ln -sf ${INSTALL_DIR}/php/bin/phpize /usr/bin/phpize
    ln -sf ${INSTALL_DIR}/php/bin/pear /usr/bin/pear
    ln -sf ${INSTALL_DIR}/php/bin/pecl /usr/bin/pecl
    ln -sf ${INSTALL_DIR}/php/sbin/php-fpm /usr/bin/php-fpm
set -e
fi

pear config-set php_ini ${INSTALL_DIR}/php/etc/php.ini
pecl config-set php_ini ${INSTALL_DIR}/php/etc/php.ini

if [ "${IS_COMPOSER}" == "true" ]; then
    echo "=========composer.phar安装=========="
    #curl -s http://getcomposer.org/installer | php
    wget ${COMPOSER_URL} -O /usr/local/bin/composer
    chmod a+x /usr/local/bin/composer
    #alias composer='/usr/local/bin/composer.phar'
    composer config -g repo.packagist composer https://packagist.laravel-china.org
fi


cat > ${INSTALL_DIR}/php/etc/php-fpm.conf <<EOF
[global]
pid = ${INSTALL_DIR}/php/var/run/php-fpm.pid
error_log = ${INSTALL_DIR}/php/var/log/php-fpm.log
log_level = notice

[www]
listen = ${INSTALL_DIR}/php/var/run/php-cgi.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = ${WEB_USER}
listen.group = ${WEB_USER}
listen.mode = 0666
user = ${WEB_USER}
group = ${WEB_USER}
pm = dynamic
pm.max_children = 20
pm.start_servers = 10
pm.min_spare_servers = 10
pm.max_spare_servers = 20
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = ${INSTALL_DIR}/php/var/log/slow.log
EOF

cat > /etc/init.d/php-fpm << EOF
#! /bin/sh
# chkconfig:   2345 15 95
# description:  PHP-FPM (FastCGI Process Manager) is an alternative PHP FastCGI implementation \
# with some additional features useful for sites of any size, especially busier sites.

prefix=${INSTALL_DIR}/php
exec_prefix=\${prefix}
php_fpm_BIN=\${exec_prefix}/sbin/php-fpm
php_fpm_CONF=\${prefix}/etc/php-fpm.conf
php_fpm_PID=\${prefix}/var/run/php-fpm.pid

php_opts="--fpm-config \$php_fpm_CONF --pid \$php_fpm_PID"

wait_for_pid () {
    try=0
    while test \$try -lt 35 ; do
        case "\$1" in
            'created')
                if [ -f "\$2" ] ; then
                    try=''
                    break
                fi
                ;;
            'removed')
                if [ ! -f "\$2" ] ; then
                    try=''
                    break
                fi
                ;;
        esac
        echo -n .
        try=\`expr \$try + 1\`
        sleep 1
    done
}

case "\$1" in
    start)
        echo -n "Starting php-fpm "
        \$php_fpm_BIN --daemonize \$php_opts

        if [ "\$?" != 0 ] ; then
            echo " failed"
            exit 1
        fi
        wait_for_pid created \$php_fpm_PID
        if [ -n "\$try" ] ; then
            echo " failed"
            exit 1
        else
            echo " done"
        fi
    ;;

    stop)
        echo -n "Gracefully shutting down php-fpm "
        if [ ! -r \$php_fpm_PID ] ; then
            echo "warning, no pid file found - php-fpm is not running ?"
            exit 1
        fi
        kill -QUIT \`cat \$php_fpm_PID\`
        wait_for_pid removed \$php_fpm_PID
        if [ -n "\$try" ] ; then
            echo " failed. Use force-quit"
            exit 1
        else
            echo " done"
        fi
    ;;

    status)
        if [ ! -r \$php_fpm_PID ] ; then
            echo "php-fpm is stopped"
            exit 0
        fi
        PID=\`cat \$php_fpm_PID\`
        if ps -p \$PID | grep -q \$PID; then
            echo "php-fpm (pid \$PID) is running..."
        else
            echo "php-fpm dead but pid file exists"
        fi
    ;;

    force-quit)
        echo -n "Terminating php-fpm "
        if [ ! -r \$php_fpm_PID ] ; then
            echo "warning, no pid file found - php-fpm is not running ?"
            exit 1
        fi
        kill -TERM \`cat \$php_fpm_PID\`
        wait_for_pid removed \$php_fpm_PID
        if [ -n "\$try" ] ; then
            echo " failed"
            exit 1
        else
            echo " done"
        fi
    ;;

    restart)
        \$0 stop
        \$0 start
    ;;

    reload)
        echo -n "Reload service php-fpm "
        if [ ! -r \$php_fpm_PID ] ; then
            echo "warning, no pid file found - php-fpm is not running ?"
            exit 1
        fi
        kill -USR2 \`cat \$php_fpm_PID\`
        echo " done"
    ;;

    *)
        echo "Usage: \$0 {start|stop|force-quit|restart|reload|status}"
        exit 1
    ;;

esac
EOF

chmod +x /etc/init.d/php-fpm
chkconfig --add  php-fpm

echo "=========ini文件路径=========="
#php -i |grep configure
php --ini

echo "=========phpinfo.php设置=========="
cat >${WEB_DIR}/phpinfo.php<<EOF
<?php
phpinfo();
?>
EOF
echo "========PHP 安装完成========"
echo "========启动服务========"
service php-fpm start

fi

if [ "${IS_NG}" == "true" ]; then

echo "=========nginx${NG_VERION}编译安装=========="
cd /var/tmp
if [ ! -f "nginx-${NG_VERION}.tar.gz" ]
then
    wget ${NG_URL}
fi
if [ ! -d "${INSTALL_DIR}/nginx" ]; then
    tar -zxf nginx-${NG_VERION}.tar.gz
    cd nginx-${NG_VERION}

    ./configure --user=${WEB_USER} --group=${WEB_USER} --prefix=${INSTALL_DIR}/nginx --with-http_stub_status_module --with-http_ssl_module  --with-http_gzip_static_module  --with-http_sub_module

    make  && make install
else
    echo "${INSTALL_DIR}/nginx 已存在"
fi

if [ ! -L "/usr/bin/nginx" ]; then
    ln -sf ${INSTALL_DIR}/nginx/sbin/nginx /usr/bin/nginx
fi

set +e
rm -f ${INSTALL_DIR}/nginx/conf/nginx.conf
mkdir -p /var/log/nginx/
mkdir ${INSTALL_DIR}/nginx/conf/vhost
set -e

cat > ${INSTALL_DIR}/nginx/conf/nginx.conf <<EOF
user  ${WEB_USER} ${WEB_USER};
worker_processes auto;
error_log  /var/log/nginx/error.log warn;
pid        /usr/local/nginx/logs/nginx.pid;
worker_rlimit_nofile 51200;
events
    {
        use epoll;
        worker_connections 51200;
        multi_accept on;
    }
http
    {
        include       mime.types;
        default_type  application/octet-stream;
        server_names_hash_bucket_size 128;
        client_header_buffer_size 32k;
        large_client_header_buffers 4 32k;
        client_max_body_size 50m;
        sendfile   on;
        tcp_nopush on;
        keepalive_timeout 60;
        tcp_nodelay on;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        fastcgi_buffer_size 64k;
        fastcgi_buffers 4 64k;
        fastcgi_busy_buffers_size 128k;
        fastcgi_temp_file_write_size 256k;
        gzip on;
        gzip_min_length  1k;
        gzip_buffers     4 16k;
        gzip_http_version 1.1;
        gzip_comp_level 2;
        gzip_types     text/plain application/javascript application/x-javascript text/javascript text/css application/xml application/xml+rss;
        gzip_vary on;
        gzip_proxied   expired no-cache no-store private auth;
        gzip_disable   "MSIE [1-6]\.";
        server_tokens off;
        access_log off;
server
    {
        listen 80 default_server;
        server_name _;
        index index.html index.htm index.php;
	    root ${WEB_DIR};
        include enable-php-pathinfo.conf;
	    include thinkphp.conf;
        location /nginx_status
        {
            stub_status on;
            access_log   off;
        }
        location ~ .*\.(gif|jpg|jpeg|png|bmp|swf)\$
        {
            expires      30d;
        }
        location ~ .*\.(js|css)?\$
        {
            expires      12h;
        }
        location ~ /.well-known {
            allow all;
        }
        location ~ /\.
        {
            deny all;
        }
        if (\$request_method !~* GET|POST|HEAD) {
            return 403;
        }
        access_log  /var/log/nginx/access.log;
    }
include vhost/*.conf;
}
EOF

cat > ${INSTALL_DIR}/nginx/conf/enable-php-pathinfo.conf <<EOF
        location ~ [^/]\.php(/|\$)
        {
            fastcgi_pass  unix:${INSTALL_DIR}/php/var/run/php-cgi.sock;
            fastcgi_index index.php;
            include fastcgi.conf;
            include pathinfo.conf;
        }

EOF

cat > ${INSTALL_DIR}/nginx/conf/thinkphp.conf <<EOF
        location / {
            if (!-e \$request_filename) {
                rewrite ^(.*)\$ /index.php?s=/\$1 last;
                break;
            }
        }
EOF
cat > ${INSTALL_DIR}/nginx/conf/pathinfo.conf <<EOF
fastcgi_split_path_info ^(.+?\.php)(/.*)\$;
set \$path_info \$fastcgi_path_info;
fastcgi_param PATH_INFO       \$path_info;
try_files \$fastcgi_script_name =404;
EOF

cat > ${INSTALL_DIR}/nginx/conf/fastcgi.conf <<EOF
fastcgi_param  SCRIPT_FILENAME    \$document_root\$fastcgi_script_name;
fastcgi_param  QUERY_STRING       \$query_string;
fastcgi_param  REQUEST_METHOD     \$request_method;
fastcgi_param  CONTENT_TYPE       \$content_type;
fastcgi_param  CONTENT_LENGTH     \$content_length;
fastcgi_param  SCRIPT_NAME        \$fastcgi_script_name;
fastcgi_param  REQUEST_URI        \$request_uri;
fastcgi_param  DOCUMENT_URI       \$document_uri;
fastcgi_param  DOCUMENT_ROOT      \$document_root;
fastcgi_param  SERVER_PROTOCOL    \$server_protocol;
fastcgi_param  HTTPS              \$https if_not_empty;
fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
fastcgi_param  SERVER_SOFTWARE    nginx/\$nginx_version;
fastcgi_param  REMOTE_ADDR        \$remote_addr;
fastcgi_param  REMOTE_PORT        \$remote_port;
fastcgi_param  SERVER_ADDR        \$server_addr;
fastcgi_param  SERVER_PORT        \$server_port;
fastcgi_param  SERVER_NAME        \$server_name;
fastcgi_param  REDIRECT_STATUS    200;
EOF

cat > /etc/init.d/nginx <<EOF
#! /bin/sh
# chkconfig: - 85 15
# description: nginx is a World Wide Web server. It is used to serve

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
NAME=nginx
PRE=${INSTALL_DIR}/nginx
NGINX_BIN=\$PRE/sbin/\$NAME
CONFIGFILE=\$PRE/conf/\$NAME.conf
PIDFILE=\$PRE/logs/\$NAME.pid
if [ -s /bin/ss ]; then
    StatBin=/bin/ss
else
    StatBin=/bin/netstat
fi

case "\$1" in
    start)
        echo -n "Starting \$NAME... "

        if \$StatBin -tnpl | grep -q nginx;then
            echo "\$NAME (pid \`pidof \$NAME\`) already running."
            exit 1
        fi
        \$NGINX_BIN -c \$CONFIGFILE

        if [ "\$?" != 0 ] ; then
            echo " failed"
            exit 1
        else
            echo " done"
        fi
        ;;
    stop)
        echo -n "Stoping \$NAME... "
        if ! \$StatBin -tnpl | grep -q nginx; then
            echo "\$NAME is not running."
            exit 1
        fi
        \$NGINX_BIN -s stop
        if [ "\$?" != 0 ] ; then
            echo " failed. Use force-quit"
            exit 1
        else
            echo " done"
        fi
        ;;
    status)
        if \$StatBin -tnpl | grep -q nginx; then
            PID=\`pidof nginx\`
            echo "\$NAME (pid \$PID) is running..."
        else
            echo "\$NAME is stopped."
            exit 0
        fi
        ;;
    force-quit|kill)
        echo -n "Terminating \$NAME... "
        if ! \$StatBin -tnpl | grep -q nginx; then
            echo "\$NAME is is stopped."
            exit 1
        fi
        kill \`pidof \$NAME\`
        if [ "\$?" != 0 ] ; then
            echo " failed"
            exit 1
        else
            echo " done"
        fi
        ;;
    restart)
        \$0 stop
        sleep 1
        \$0 start
        ;;
    reload)
        echo -n "Reload service \$NAME... "
        if \$StatBin -tnpl | grep -q nginx; then
            \$NGINX_BIN -s reload
            echo " done"
        else
            echo "\$NAME is not running, can't reload."
            exit 1
        fi
        ;;
    configtest)
        echo -n "Test \$NAME configure files... "
        \$NGINX_BIN -t
        ;;
    *)
        echo "Usage: \$0 {start|stop|restart|reload|status|configtest|force-quit|kill}"
        exit 1
        ;;
esac
EOF

chmod +x /etc/init.d/nginx
chkconfig --add nginx

echo "========nginx 安装完成========"

echo "========启动服务========"
service nginx start

fi

