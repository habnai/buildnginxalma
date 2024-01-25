#!/bin/bash
# Check if user is root
if [ "$(id -u)" != "0" ]; then
    echo "Error: You must be root to run this script, please use the root user to install the software."
    exit 1
fi
# exit when any command fails
set -e

clear
 #Installing building tools
dnf update
dnf install git gcc cmake make gcc-c++ gd gd-devel mercurial zlib zlib-devel perl libxml2 libxslt pcre pcre-devel pcre2 pcre2-devel  libmaxminddb-devel libxml2-devel libxslt-devel -y;
#Cleaning old sources
git clone --recurse-submodules -j8 https://github.com/habnai/ngxqb.git
cd ngxqb/ngx_brotli/deps/brotli && mkdir out && cd out
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_CXX_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_INSTALL_PREFIX=./installed ..
cmake --build . --config Release --target brotlienc
cd ../../../../nginx
export OPENSSL_CONF=../openssl/apps/openssl.cnf
sudo groupadd nginx
sudo useradd -m -g nginx -s /bin/bash nginx
./auto/configure \
--prefix=/etc/nginx \
--sbin-path=/usr/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--modules-path=/etc/nginx/modules \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--pid-path=/var/run/nginx.pid \
--lock-path=/var/run/nginx.lock \
--http-client-body-temp-path=/var/cache/nginx/client_temp \
--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
--user=nginx \
--group=nginx \
--with-debug \
--with-compat \
--with-file-aio \
--with-threads \
--with-http_auth_request_module \
--with-http_dav_module \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_mp4_module \
--with-http_image_filter_module \
--with-http_realip_module \
--with-http_ssl_module \
--with-http_stub_status_module \
--with-http_v2_module \
--with-http_v3_module \
--with-http_dav_module \
--with-http_stub_status_module \
--with-http_slice_module \
--with-mail \
--with-mail_ssl_module \
--with-stream \
--with-stream_realip_module \
--with-stream_ssl_module \
--with-stream_ssl_preread_module \
--with-pcre \
--with-openssl=../openssl \
--with-openssl-opt=enable-ktls \
--with-openssl-opt=enable-fips \
--add-module=../ngx_brotli \
--add-module=../ngx_devel_kit \
--add-module=../set-misc-nginx-module \
--add-module=../njs/nginx \
--with-cc-opt='-m64 -march=native -mtune=native -Ofast -flto -funroll-loops -ffunction-sections -fdata-sections -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wl,--gc-sections -Wp,-D_FORTIFY_SOURCE=2 -fPIC -fPIE' \
--with-ld-opt='-m64 -Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie -Wl,-s -Wl,--gc-sections -L/usr/lib64 -lz'
make
mkdir -p /etc/nginx/{dh,modules,sites-available,sites-enabled,sites-disabled,conf.d,html} /var/cache/nginx/{client_temp,proxy_temp,fastcgi_temp,uwsgi_temp,scgi_temp} /var/log/nginx /var/www/html
cp -r conf/. /etc/nginx/; cp -r docs/html/. /var/www/html/; cp -r docs/html/. /etc/nginx/html/; cp objs/nginx /usr/sbin/nginx;
chmod 755 /usr/sbin/nginx
chown nginx:adm /var/log/nginx
chmod 755 /var/log/nginx
find /var/cache/nginx -type d -print0 | xargs -0 chown nginx:root
find /var/cache/nginx -type d -exec chmod 755 {} +
/usr/bin/touch /etc/systemd/system/nginx.service
/usr/bin/cat <<EOF >/etc/systemd/system/nginx.service
[Unit]
Description=NGINX web server
Documentation=https://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target
[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf
ExecReload=/bin/sh -c "/bin/kill -s HUP $(/bin/cat /var/run/nginx.pid)"
ExecStop=/bin/sh -c "/bin/kill -s TERM $(/bin/cat /var/run/nginx.pid)"
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload; systemctl enable nginx
systemctl restart nginx

