#!/bin/sh
# services/nginx/entrypoint.sh

echo "🔍 Setting up nginx configuration..."
envsubst '${DOMAIN_NAME}' \
  < /etc/nginx/nginx.conf.template \
  > /etc/nginx/nginx.conf
echo "✅ Nginx configuration setup completed successfully!"

exec "$@"
