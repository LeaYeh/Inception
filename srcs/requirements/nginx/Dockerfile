# services/nginx/Dockerfile
ARG     BASE_IMAGE
FROM    ${BASE_IMAGE}

ARG     USER_NAME=www-data
ARG     USER_UID
ARG     USER_GID

ARG     DOMAIN_NAME

RUN     set -eux \
            && addgroup -g ${USER_GID} -S ${USER_NAME} || true \
            && adduser -u ${USER_UID} -D -S -G ${USER_NAME} ${USER_NAME} || true

RUN     apk add --no-cache nginx openssl gettext \
        && mkdir -p /run/nginx /etc/nginx/ssl

RUN mkdir -p \
		/var/www/html/ \
		/var/cache/nginx \
		/var/log/nginx \
		/var/lib/nginx \
		/etc/nginx/ \
	&& chown -R ${USER_NAME}:${USER_NAME} \
		/var/www/html/ \
		/var/cache/nginx/ \
		/var/log/nginx/ \
		/var/lib/nginx \
		/etc/nginx/ \
	&& chmod -R 1755 /etc/nginx \
	&& touch /run/nginx.pid \
	&& chown -R ${USER_NAME}:${USER_NAME} /run/nginx.pid

COPY    tools/generate-ssl.sh /etc/nginx/ssl/generate-ssl.sh
RUN     chmod +x /etc/nginx/ssl/generate-ssl.sh
RUN     /etc/nginx/ssl/generate-ssl.sh && rm /etc/nginx/ssl/generate-ssl.sh

COPY    tools/setup_config.sh /etc/nginx/setup_config.sh
RUN     chmod +x /etc/nginx/setup_config.sh

USER ${USER_NAME}

ENTRYPOINT [ "sh", "/etc/nginx/setup_config.sh" ]

CMD ["nginx", "-g", "daemon off;"]
