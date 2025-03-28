# srcs/requirements/wordpress/Dockerfile
ARG     BASE_IMAGE
FROM    ${BASE_IMAGE}

ARG     USER_NAME=www-data
ARG     USER_UID
ARG     USER_GID

RUN     apk add --no-cache gettext

RUN     set -xeu \
            && addgroup -g ${USER_GID} -S ${USER_NAME} || true \
            && adduser -u ${USER_UID} -D -S -G ${USER_NAME} ${USER_NAME} || true

RUN         apk add --no-cache \
        php \
        php82-fpm \
        php82-mysqli \
        php82-json \
        php82-openssl \
        php82-curl \
        php82-zlib \
        php82-xml \
        php82-phar \
        php82-intl \
        php82-dom \
        php82-xmlreader \
        php82-ctype \
        php82-session \
        php82-mbstring \
        php82-gd \
        curl

RUN     mkdir -p /var/www/html

RUN     curl -o wordpress.tar.gz https://wordpress.org/latest.tar.gz && \
        tar -xzvf wordpress.tar.gz -C /var/www/html --strip-components=1 && \
        rm wordpress.tar.gz

RUN     mkdir -p /var/www/html/ \
	    && chown -R ${USER_NAME}:${USER_NAME} \
	    	/var/www/html/ \
	    	/var/log \
	    && chmod 755 \
	    	/var/www/html/ \
            usr/bin/php

RUN     curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
        chmod +x wp-cli.phar && \
        mv wp-cli.phar /usr/local/bin/wp

COPY    tools/wp-init.sh /usr/local/bin/wp-init.sh
RUN     chmod 755 /usr/local/bin/wp-init.sh

COPY    tools/test_db_connection.php /var/www/html/test_db_connection.php
RUN     chown ${USER_NAME}:${USER_NAME} /var/www/html/test_db_connection.php \
        && chmod 755 /var/www/html/test_db_connection.php

COPY    conf/php-fpm.conf /etc/php82/php-fpm.conf
RUN     chown -R ${USER_NAME}:${USER_NAME} /etc/php82/php-fpm.d
COPY    conf/www.conf.template /etc/php82/php-fpm.d/www.conf.template

WORKDIR /var/www/html

EXPOSE  9000

USER    ${USER_NAME}

ENTRYPOINT [ "sh", "/usr/local/bin/wp-init.sh" ]

CMD     ["php-fpm82", "-F"]
