# services/nginx/Dockerfile
# ARG     BASE_IMAGE
# FROM    ${BASE_IMAGE}
FROM    alpine:3.19
ARG     DOMAIN_NAME

RUN     apk update && apk upgrade && apk add --no-cache bash curl

RUN     apk add --no-cache nginx openssl
RUN     mkdir -p /run/nginx
RUN     mkdir -p /etc/nginx/ssl

COPY    tools/generate-ssl.sh /etc/nginx/ssl/generate-ssl.sh
RUN     chmod +x /etc/nginx/ssl/generate-ssl.sh
RUN     /etc/nginx/ssl/generate-ssl.sh && rm /etc/nginx/ssl/generate-ssl.sh

CMD ["nginx", "-g", "daemon off;"]
