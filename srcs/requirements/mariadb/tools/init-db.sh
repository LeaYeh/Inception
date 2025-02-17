#!/bin/sh
set -e

wait_for_mariadb() {
    echo "Waiting for MariaDB to be ready..."
    for i in $(seq 1 30); do
        if mysqladmin ping -h"localhost" -u"root" --silent; then
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

    echo "Creating database and users..."
    mysql -uroot << EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_USER_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';

CREATE USER IF NOT EXISTS '${MYSQL_ADMIN}'@'%' IDENTIFIED BY '${MYSQL_ADMIN_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_ADMIN}'@'%' WITH GRANT OPTION;

FLUSH PRIVILEGES;
EOF

#     echo "Changing root password..."
#     mysql -uroot << EOF
# ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
# EOF

    touch .init
}

verify_users() {
    echo "Verifying users..."
    mysql -u root << EOF
SELECT User, Host FROM mysql.user WHERE User IN ('${MYSQL_USER}', '${MYSQL_ADMIN}');
SHOW GRANTS FOR '${MYSQL_USER}'@'%';
SHOW GRANTS FOR '${MYSQL_ADMIN}'@'%';
EOF
}

main() {
    chown -R mysql:mysql /var/lib/mysql

    # ls -alR /var/lib/mysql
    if [ ! -d "/var/lib/mysql/mysql" ]; then
        echo "Install DB..."
        mysql_install_db --user=mysql --datadir=/var/lib/mysql --skip-test-db 
        # --auth-root-authentication-method=normal
    else
        echo "The DB is init!!!!!! NOOOOO"
    fi
    echo "WHERE I AM"

    if [ ! -e .init ]; then
        mysqld --user=mysql &
        wait_for_mariadb
        init_database
        verify_users
        mysqladmin -uroot shutdown
        echo "Database initialization completed."
    else
        echo "Database already initialized."
    fi
}

main

exec "$@"

# exec mysqld --user=mysql
