# srcs/requirements/mariadb/Dockerfile
ARG     BASE_IMAGE
FROM    ${BASE_IMAGE}

RUN     apk add --no-cache mariadb mariadb-client

COPY    conf/my.cnf /etc/my.cnf.d/my.cnf
COPY    tools/init-db.sh /local/bin/init-db.sh

RUN     mkdir -p /var/lib/mysql /var/run/mysqld /local/bin \
            && chown -R mysql:mysql /var/lib/mysql /var/run/mysqld /local/bin \
            && chmod 755 /local/bin/init-db.sh

RUN     chmod 777 /var/run/mysqld

WORKDIR /var/lib/mysql

EXPOSE  3306

CMD     ["sh", "-c", "/local/bin/init-db.sh && exec mysqld --user=mysql"]
