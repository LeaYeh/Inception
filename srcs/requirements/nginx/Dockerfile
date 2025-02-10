# services/nginx/Dockerfile
ARG     BASE_IMAGE
FROM    ${BASE_IMAGE}

RUN     apk add --no-cache nginx openssl
RUN     mkdir -p /run/nginx
RUN     mkdir -p /etc/nginx/ssl

COPY    tools/generate-ssl.sh /etc/nginx/ssl/generate-ssl.sh
RUN     chmod +x /etc/nginx/ssl/generate-ssl.sh
RUN     /etc/nginx/ssl/generate-ssl.sh && rm /etc/nginx/ssl/generate-ssl.sh

COPY    conf/nginx.conf /etc/nginx/nginx.conf

ENTRYPOINT ["nginx", "-g", "daemon off;"]