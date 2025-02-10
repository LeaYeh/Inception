#!/bin/sh
set -e

wait_for_mariadb() {
    echo "Waiting for MariaDB to be ready..."
    for i in $(seq 1 30); do
        if mysqladmin ping -h"localhost" -u"root" -p"${MYSQL_ROOT_PASSWORD}" --silent; then
            echo "MariaDB is ready!"
            return 0
        fi
        echo "Attempt $i: MariaDB is not ready yet... waiting"
        sleep 2
    done
    echo "Could not connect to MariaDB after 30 attempts. Exiting..."
    return 1
}

init_database() {
    mysql -u root << EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_USER_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';

CREATE USER IF NOT EXISTS '${MYSQL_ADMIN}'@'%' IDENTIFIED BY '${MYSQL_ADMIN_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_ADMIN}'@'%' WITH GRANT OPTION;

FLUSH PRIVILEGES;
EOF
}

main() {
    if [ ! -d "/var/lib/mysql/mysql" ]; then
        mysql_install_db --user=mysql --datadir=/var/lib/mysql
    fi

    mysqld_safe &

    wait_for_mariadb

    init_database

    mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown

    echo "Database initialization completed."
}

main