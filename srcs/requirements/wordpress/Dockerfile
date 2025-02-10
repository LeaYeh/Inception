# srcs/requirements/wordpress/Dockerfile
ARG     BASE_IMAGE
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

RUN     chown -R www-data:www-data /var/www/html/wordpress

COPY    conf/wp-config.php /var/www/html/wordpress/wp-config.php

COPY    tools/wp-init.sh /usr/local/bin/wp-init.sh
RUN     chmod +x /usr/local/bin/wp-init.sh

USER    www-data

CMD     ["wp-init.sh"]
