# srcs/requirements/mariadb/Dockerfile
ARG     BASE_IMAGE
# ARG     USER_NAME=mysql
# ARG     USER_UID=1000
# ARG     USER_GID=1000
FROM    ${BASE_IMAGE}

RUN     set -x \
            && addgroup -g 82 -S mysql || true \
            && adduser -u 82 -D -S -G mysql mysql || true

RUN     apk add --no-cache mariadb mariadb-client

COPY    tools/init-db.sh /local/bin/init-db.sh

RUN     mkdir -p /var/lib/mysql /var/run/mysqld /local/bin \
            && chown -R mysql:mysql /var/lib/mysql /var/run/mysqld /local/bin \
            && chmod 755 /local/bin/init-db.sh

RUN     chmod 777 /var/lib/mysql /var/run/mysqld

EXPOSE 3306

WORKDIR /var/lib/mysql

# USER ${USER_NAME}

ENTRYPOINT [ "sh", "/local/bin/init-db.sh" ]

CMD     ["mariadbd", "--bind-address=0.0.0.0", "--port=3306"]
