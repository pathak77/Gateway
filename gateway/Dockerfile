FROM openresty/openresty:alpine-fat

RUN luarocks install lua-resty-jwt

COPY ./conf/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

COPY ./scripts/ /usr/local/openresty/nginx/lua/

EXPOSE 8080

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]