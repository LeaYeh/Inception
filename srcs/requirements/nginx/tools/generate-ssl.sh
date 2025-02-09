#!/bin/sh

openssl genpkey -algorithm RSA -out /etc/nginx/ssl/privatekey.pem

openssl req -new -key /etc/nginx/ssl/privatekey.pem -out /etc/nginx/ssl/csr.pem -subj "/C=FR/ST=Paris/L=Paris/O=42/OU=42/CN=ft_services"

openssl x509 -req -days 365 -in /etc/nginx/ssl/csr.pem -signkey /etc/nginx/ssl/privatekey.pem -out /etc/nginx/ssl/certificate.pem

rm /etc/nginx/ssl/csr.pem

chmod 600 /etc/nginx/ssl/privatekey.pem
chmod 600 /etc/nginx/ssl/certificate.pem

