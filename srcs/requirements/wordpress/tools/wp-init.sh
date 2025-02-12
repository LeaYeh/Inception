#!/bin/sh
set -e

# Check if required environment variables are set
for var in DOMAIN_NAME MYSQL_ADMIN MYSQL_ADMIN_PASSWORD MYSQL_ADMIN_EMAIL MYSQL_DATABASE MYSQL_USER MYSQL_USER_PASSWORD MYSQL_USER_EMAIL; do
  if [ -z "$(eval echo \$$var)" ]; then
    echo "Error: $var is not set"
    exit 1
  fi
done

export PHP_MEMORY_LIMIT=256M

# Function to wait for database
wait_for_db() {
    echo "Waiting for database connection..."
    for i in $(seq 1 30); do
        if wp db check --allow-root > /dev/null 2>&1; then
            echo "Database is ready!"
            return 0
        fi
        echo "Attempt $i: Database is not ready yet..."
        sleep 5
    done
    echo "Could not connect to database after 30 attempts."
    return 1
}

if [ ! -e index.php ] && [ ! -e wp-includes/version.php ]; then
  echo "WordPress not found. Downloading WordPress..."
  php -d memory_limit=256M /usr/local/bin/wp core download --allow-root --debug || { echo "Failed to download WordPress"; exit 1; }

  # Wait for database to be ready
  # wait_for_db || exit 1

  echo "Creating wp-config.php..."
  wp config create --allow-root \
    --dbname="${MYSQL_DATABASE}" \
    --dbuser="${MYSQL_USER}" \
    --dbpass="${MYSQL_USER_PASSWORD}" \
    --dbhost="db:3306" \
    --dbprefix="wp_" || { echo "Failed to create wp-config.php"; exit 1; }
  echo "wp-config.php created successfully!"

  # Wait for database connection
  # until wp db check --allow-root; do
  #   echo "Waiting for database connection..."
  #   sleep 5
  # done

  echo "Installing WordPress..."
  wp core install --allow-root \
    --url="${DOMAIN_NAME}" \
    --title="Inception WordPress" \
    --admin_user="${MYSQL_ADMIN}" \
    --admin_password="${MYSQL_ADMIN_PASSWORD}" \
    --admin_email="${MYSQL_ADMIN_EMAIL}" || { echo "Failed to install WordPress"; exit 1; }
  echo "WordPress installed successfully!"


  wp user create "${MYSQL_USER}" "${MYSQL_USER_EMAIL}" \
    --user_pass="${MYSQL_USER_PASSWORD}" \
    --role=author \
    --allow-root || echo "User ${MYSQL_USER} already exists or there was an error creating the user"

  echo "WordPress installed and configured successfully!"
fi

exec php-fpm82 --nodaemonize
