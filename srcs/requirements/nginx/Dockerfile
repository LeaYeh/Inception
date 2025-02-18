# services/nginx/Dockerfile
ARG     BASE_IMAGE
FROM    ${BASE_IMAGE}

ARG     DOMAIN_NAME

RUN     apk add --no-cache nginx openssl gettext \
        && mkdir -p /run/nginx /etc/nginx/ssl

COPY    tools/generate-ssl.sh /etc/nginx/ssl/generate-ssl.sh
RUN     chmod +x /etc/nginx/ssl/generate-ssl.sh
RUN     /etc/nginx/ssl/generate-ssl.sh && rm /etc/nginx/ssl/generate-ssl.sh

COPY    tools/setup_config.sh /etc/nginx/setup_config.sh
RUN     chmod +x /etc/nginx/setup_config.sh

ENTRYPOINT [ "sh", "/etc/nginx/setup_config.sh" ]

CMD ["nginx", "-g", "daemon off;"]
