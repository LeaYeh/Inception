# srcs/requirements/mariadb/Dockerfile
ARG     BASE_IMAGE
FROM    ${BASE_IMAGE}

ARG     USER_NAME=mysql

RUN     set -x \
            && addgroup -g 82 -S ${USER_NAME} || true \
            && adduser -u 82 -D -S -G ${USER_NAME} ${USER_NAME} || true

RUN     apk add --no-cache mariadb mariadb-client

COPY    tools/init-db.sh /local/bin/init-db.sh

RUN     mkdir -p /var/lib/mysql /var/run/mysqld /local/bin \
            && chown -R ${USER_NAME}:${USER_NAME} /var/lib/mysql /var/run/mysqld /local/bin \
            && chmod 755 /local/bin/init-db.sh

RUN     mkdir -p /usr/lib/mariadb \
        && chown -R ${USER_NAME}:${USER_NAME} /usr/lib/mariadb \
        && chmod 755 /usr/lib/mariadb

RUN     chmod 755 /var/lib/mysql /var/run/mysqld

EXPOSE  3306

WORKDIR /var/lib/mysql

# USER    ${USER_NAME}

ENTRYPOINT [ "sh", "/local/bin/init-db.sh" ]

CMD     ["mariadbd"]
