ARG     BASE_IMAGE=inception/base:latest
FROM    ${BASE_IMAGE}

RUN     set -x \
            && addgroup -g 82 -S www-data || true \
            && adduser -u 82 -D -S -G www-data www-data || true

RUN     apk add --no-cache curl \
            php-fpm \
            php-xml

RUN     mkdir -p /var/www/html

RUN     curl -o wordpress.tar.gz https://wordpress.org/latest.tar.gz && \
            tar -xzvf wordpress.tar.gz && \
            rm wordpress.tar.gz && \
            ls -la && \
            mv wordpress /var/www/html/wordpress

RUN chown -R www-data:www-data /var/www/html/wordpress

CMD ["php-fpm7", "-F"]
