# srcs/requirements/wordpress/Dockerfile
ARG     BASE_IMAGE
FROM    ${BASE_IMAGE}

RUN     set -x \
            && addgroup -g 82 -S www-data || true \
            && adduser -u 82 -D -S -G www-data www-data || true

RUN apk add --no-cache \
    php82 \
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

RUN mkdir -p /var/www/html

RUN curl -o wordpress.tar.gz https://wordpress.org/latest.tar.gz && \
            tar -xzvf wordpress.tar.gz && \
            rm wordpress.tar.gz && \
            mv wordpress /var/www/html/wordpress

RUN chown -R www-data:www-data /var/www/html

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

COPY tools/wp-init.sh /usr/local/bin/wp-init.sh
RUN chmod +x /usr/local/bin/wp-init.sh

WORKDIR /var/www/html

EXPOSE 9000

# USER www-data

CMD ["wp-init.sh"]
