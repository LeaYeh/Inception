#!/bin/sh
set -e  # exit immediately if a command exits with a non-zero status

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
      --dbname="${WP_DATABASE}" \
      --dbuser="${MYSQL_ADMIN}" \
      --dbpass="${MYSQL_ADMIN_PASSWORD}" \
      --dbhost="db" \
      --debug \
      --dbprefix="wp_" || { echo "❌ Failed to create wp-config.php"; exit 1; }
    echo "✅ wp-config.php created successfully!"
fi

### 🔹 Install WordPress
echo "🔽 Installing WordPress..."
if wp core is-installed --allow-root; then
    echo "✅ WordPress is already installed."
    wp core verify-checksums --allow-root || { echo "❌ Failed to verify WordPress checksums"; exit 1; }
else
    wp core install --allow-root \
      --url="${DOMAIN_NAME}" \
      --title="Inception WordPress" \
      --admin_user="${WP_ADMIN}" \
      --admin_password="${WP_ADMIN_PASSWORD}" \
      --admin_email="dummy@example.com" \
      --skip-email || { echo "❌ Failed to install WordPress"; exit 1; }
    echo "✅ WordPress installed successfully!"
fi

### 🔹 Create users
echo "➕ Creating WordPress user '${WP_USER}'..."
if wp user get "${WP_USER}" --allow-root >/dev/null 2>&1; then
    echo "⚠️  User '${WP_USER}' already exists. Skipping."
else
    if wp user create "${WP_USER}" "${WP_USER}@example.com" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author \
        --allow-root; then
        echo "✅ User '${WP_USER}' created successfully."
    else
        echo "❌ Failed to create user '${WP_USER}'."
    fi
fi

echo "🎉 WordPress setup completed successfully!"

exec "$@"
