#!/bin/sh
if [ -z "$DOMAIN_NAME" ]; then
    echo "Error: DOMAIN_NAME environment variable is not set"
    exit 1
fi

echo "Generating SSL certificate for ${DOMAIN_NAME}..."
openssl req -x509 -nodes \
    -days 365 \
    -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/privatekey.pem \
    -out /etc/nginx/ssl/certificate.pem \
    -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42/CN=${DOMAIN_NAME}" \
    -addext "subjectAltName=DNS:${DOMAIN_NAME}"

chmod 600 /etc/nginx/ssl/privatekey.pem
chmod 644 /etc/nginx/ssl/certificate.pem

echo "SSL certificate generated successfully!"
