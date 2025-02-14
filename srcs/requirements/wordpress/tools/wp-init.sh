#!/bin/sh
set -e  # exit immediately if a command exits with a non-zero status

### 🔹 Check env all setting
echo "🔍 Checking required environment variables..."
REQUIRED_VARS="DOMAIN_NAME MYSQL_ADMIN MYSQL_ADMIN_PASSWORD MYSQL_ADMIN_EMAIL MYSQL_DATABASE MYSQL_USER MYSQL_USER_PASSWORD MYSQL_USER_EMAIL"
for var in $REQUIRED_VARS; do
  if [ -z "$(eval echo \$$var)" ]; then
    echo "❌ Error: $var is not set"
    exit 1
  fi
done
echo "✅ All required environment variables are set."

### 🔹 Wait for db getting ready
MAX_RETRIES=5
RETRY_COUNT=0
echo "⏳ Waiting for database to be ready..."
while [ "$RETRY_COUNT" -lt "$MAX_RETRIES" ]; do
    if php test_db_connection.php; then
        echo "✅ Database is ready!"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT+1))
    echo "⚠️ Database connection failed. Retrying ($RETRY_COUNT/$MAX_RETRIES)..."
    sleep 5
done

if [ "$RETRY_COUNT" -eq "$MAX_RETRIES" ]; then
    echo "❌ Database connection failed after $MAX_RETRIES attempts. Exiting..."
    exit 1
fi

### 🔹 Check wordpress exist
echo "🔍 Checking if WordPress files are present..."
if [ ! -e index.php ] || [ ! -e wp-includes/version.php ]; then
  echo "❌ WordPress files not found. Please mount the WordPress installation files to /var/www/html"
  exit 1
fi
echo "✅ WordPress files are present."

### 🔹 Check wp-config.php exist
if [ -e wp-config.php ]; then
    echo "✅ wp-config.php already exists."
else
    echo "⚙️  Creating wp-config.php..."
    wp config create --allow-root \
      --dbname="${MYSQL_DATABASE}" \
      --dbuser="${MYSQL_USER}" \
      --dbpass="${MYSQL_USER_PASSWORD}" \
      --dbhost="db:3306" \
      --dbprefix="wp_" || { echo "❌ Failed to create wp-config.php"; exit 1; }
    echo "✅ wp-config.php created successfully!"
fi

### 🔹 Install WordPress
echo "🔽 Installing WordPress..."
if wp core is-installed --allow-root; then
    echo "✅ WordPress is already installed."
else
    wp core install --allow-root \
      --url="${DOMAIN_NAME}" \
      --title="Inception WordPress" \
      --admin_user="${MYSQL_ADMIN}" \
      --admin_password="${MYSQL_ADMIN_PASSWORD}" \
      --admin_email="${MYSQL_ADMIN_EMAIL}" || { echo "❌ Failed to install WordPress"; exit 1; }
    echo "✅ WordPress installed successfully!"
fi

### 🔹 Create users
echo "➕ Creating WordPress user '${MYSQL_USER}'..."
if wp user get "${MYSQL_USER}" --allow-root >/dev/null 2>&1; then
    echo "⚠️  User '${MYSQL_USER}' already exists. Skipping."
else
    if wp user create "${MYSQL_USER}" "${MYSQL_USER_EMAIL}" \
        --user_pass="${MYSQL_USER_PASSWORD}" \
        --role=author \
        --allow-root; then
        echo "✅ User '${MYSQL_USER}' created successfully."
    else
        echo "❌ Failed to create user '${MYSQL_USER}'."
    fi
fi

echo "🎉 WordPress setup completed successfully!"

### 🔹 Start PHP-FPM
exec php-fpm82 --nodaemonize