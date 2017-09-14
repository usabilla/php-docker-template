#!/bin/sh

set -xe

docker-nginx-source extract

cd /usr/src/nginx

export NGINX_CONFIG=" --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/usr/lib/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
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
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_stub_status_module \
    --with-http_auth_request_module \
    --with-http_xslt_module=dynamic \
    --with-http_image_filter_module=dynamic \
    --with-http_geoip_module=dynamic \
    --with-threads \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-stream_realip_module \
    --with-stream_geoip_module=dynamic \
    --with-http_slice_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-compat \
    --with-file-aio \
    --with-http_v2_module"

./configure $NGINX_CONFIG --with-debug

make -j "$(nproc)"

mv objs/nginx objs/nginx-debug
mv objs/ngx_http_xslt_filter_module.so objs/ngx_http_xslt_filter_module-debug.so
mv objs/ngx_http_image_filter_module.so objs/ngx_http_image_filter_module-debug.so
mv objs/ngx_http_geoip_module.so objs/ngx_http_geoip_module-debug.so
mv objs/ngx_stream_geoip_module.so objs/ngx_stream_geoip_module-debug.so

./configure $NGINX_CONFIG

make -j "$(nproc)"
make install

rm -rf /etc/nginx/html/
mkdir /etc/nginx/conf.d/
mkdir -p /usr/share/nginx/html/
install -m644 html/index.html /usr/share/nginx/html/
install -m644 html/50x.html /usr/share/nginx/html/
install -m755 objs/nginx-debug /usr/sbin/nginx-debug
install -m755 objs/ngx_http_xslt_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_xslt_filter_module-debug.so
install -m755 objs/ngx_http_image_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_image_filter_module-debug.so
install -m755 objs/ngx_http_geoip_module-debug.so /usr/lib/nginx/modules/ngx_http_geoip_module-debug.so
install -m755 objs/ngx_stream_geoip_module-debug.so /usr/lib/nginx/modules/ngx_stream_geoip_module-debug.so
ln -s ../../usr/lib/nginx/modules /etc/nginx/modules
strip /usr/sbin/nginx*
strip /usr/lib/nginx/modules/*.so

cd /
docker-nginx-source delete

# Bring in gettext so we can get `envsubst`, then throw
# the rest away. To do this, we need to install `gettext`
# then move `envsubst` out of the way so `gettext` can
# be deleted completely, then move `envsubst` back.

apk add --no-cache --virtual .gettext gettext
mv /usr/bin/envsubst /tmp/

runDeps="$( \
    scanelf --needed --nobanner /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
    | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
    | sort -u \
    | xargs -r apk info --installed \
    | sort -u \
)" \
    && apk add --no-cache --virtual .nginx-rundeps $runDeps

apk del .gettext
mv /tmp/envsubst /usr/local/bin/
