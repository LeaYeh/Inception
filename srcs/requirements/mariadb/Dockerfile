# srcs/requirements/mariadb/Dockerfile
ARG     BASE_IMAGE
FROM    ${BASE_IMAGE}

ARG     USER_NAME=mysql

RUN     set -x \
            && addgroup -S ${USER_NAME} \
            && adduser -D -S -G ${USER_NAME} ${USER_NAME} \
            && getent group ${USER_NAME}

RUN     apk add --no-cache mariadb mariadb-client

COPY    tools/init-db.sh /local/bin/init-db.sh

RUN     mkdir -p /var/lib/mysql /var/run/mysqld /local/bin \
            && chown -R ${USER_NAME}:${USER_NAME} /var/lib/mysql /var/run/mysqld /local/bin \
            && chmod 755 /local/bin/init-db.sh

RUN     chmod 755 /var/lib/mysql /var/run/mysqld


WORKDIR /var/lib/mysql

USER    ${USER_NAME}

ENTRYPOINT [ "sh", "/local/bin/init-db.sh" ]

CMD     ["mariadbd"]
