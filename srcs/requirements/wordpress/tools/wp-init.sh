#!/bin/sh
set -e

until nc -z -v -w30 db 3306
do
  echo "Waiting for database connection..."
  sleep 5
done
echo "Database connection established."

if ! wp core is-installed --allow-root; then
  wp core install --allow-root \
    --url="${DOMAIN_NAME}" \
    --title="Inception WordPress" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASSWORD}" \
    --admin_email="${WP_ADMIN_EMAIL}"
  wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
    --user_pass="${WP_USER_PASSWORD}" \
    --role=author \
    --allow-root

  echo "WordPress installed and configured successfully!"
fi

exec php-fpm82 --nodaemonize