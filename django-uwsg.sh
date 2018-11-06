pip install Django==1.8.5 django-oauth2-provider==0.2.6.1 django-rest-swagger==0.3.5  djangorestframework==2.4.2 python-dateutil==2.6.1 python-openid==2.2.5 python-social-auth==0.1.23 uwsgi==2.0.15 matplotlib==2.1.0 MySQL-python wheel SQLAlchemy 


cat >> /etc/uwsgi.ini <<EOF
[uwsgi]
socket = 127.0.0.1:9090
master = true
vhost = true
no-site = true
workers = 1
reload-mercy = 10
vacuum = true
max-requests = 1000
buffer-size = 30000
pidfile = /var/run/uwsgi.pid
daemonize = /var/log/nginx/uwsgi.log
EOF

cat > /usr/local/nginx/conf/nginx.conf <<EOF
user  www www;
worker_processes auto;
 
pid        /var/run/nginx.pid;
 
#Specifies the value for maximum file descriptors that can be opened by this process.
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
 
        fastcgi_connect_timeout 3000;
        fastcgi_send_timeout 3000;
        fastcgi_read_timeout 3000;
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
        include vhost/*.conf;
}
EOF

cat > /usr/local/nginx/conf/vhost/default.conf <<EOF
error_log  /var/log/nginx/error.log warn;
server {
        listen       80;
        server_name  _;
        charset UTF-8;
        access_log      /var/log/nginx/mysite_access.log;
        error_log       /var/log/nginx/mysite_error.log;
 
        location / {            
            include  uwsgi_params;
            uwsgi_pass  127.0.0.1:9090;
            uwsgi_param UWSGI_SCRIPT my_site.wsgi;
            uwsgi_param UWSGI_CHDIR /home/deeplearn/mysite;
            index  index.html index.htm;
            client_max_body_size 35m;
        }
 
        location /static {
            expires 30d;
            autoindex on;
            add_header Cache-Control private;
            alias /home/deeplearn/mysite/static/;
        }
}
EOF

service nginx restart

cat > /etc/init.d/uwsgi <<EOF
#!/bin/bash
# uwsgi script
# it is v.0.0.1 version.
# chkconfig: - 89 19
# description: uwsgi script
# processname: uwsgi
 
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
NAME='uwsgi'
uwsgi_config=/etc/\$NAME.ini
PIDFILE=/var/run/\$NAME.pid
uwsgi=/usr/local/python27/bin/\$NAME
 
uwsgi_pn=`ps aux|grep -v "grep"|grep -c "uwsgi"`
uwsgi_pid=`ps -eo pid,comm|grep uwsgi|sed -n 1p|awk '{print \$1}'`
 
RETVAL=0
prog="uwsgi"
# Source function library.
.  /etc/rc.d/init.d/functions
 
      
if [ \$(id -u) != "0" ]; then
    printf "Error: You must be root to run this script!\n"
    exit 1
fi
      
      
# Start uwsgi daemons functions.
start() {
        if [ -f \$PIDFILE ];then
            echo "\$NAME (pid `cat \$PIDFILE`) already running."
            exit 1
        fi
 
        daemon \$uwsgi --ini \${uwsgi_config}
        if [ "\$?" != 0 ] ; then
            echo "start \$NAME failed"
            exit 1
        else
            if [ -n \${uwsgi_pid} ];then
                echo "start \$NAME done"
            else
                rm -f \$PIDFILE
                echo "start \$NAME failed"
            fi
        fi
}
 
# Stop nginx daemons functions.
stop() {

        if [ -f \$PIDFILE ];then
            echo "stop form the pidfile"
            kill -9 `cat \$PIDFILE`
            rm -f \$PIDFILE
        else
            echo "stop form the ps"
            if [ -n \${uwsgi_pid} ];then
               echo "\$NAME not running."
            else
               kill -9 \${uwsgi_pid}
            fi
        fi
 
        if [ "\$?" != 0 ] ; then
            echo "stop \$NAME failed."
            exit 1
        else
            echo "stop \$NAME done"
        fi
}
      
# See how we were called.
case "\$1" in
start)
        start
        ;;
stop)
        stop
        ;;
reload)
        reload
        ;;
restart)
        stop
        sleep 3
        start
        ;;
*)
        echo \$"Usage: \$prog {start|stop|restart}"
        exit 1
esac
exit \$RETVAL
EOF

chmod +x /etc/init.d/uwsgi
chkconfig --add uwsgi
service uwsgi  restart
