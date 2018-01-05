#!/usr/bin/env bash

mkdir -p var/jwt # Ensure folder exists
php -r "require'vendor/autoload.php';file_put_contents('passphrase.txt',\Symfony\Component\Yaml\Yaml::parse(file_get_contents('app/config/parameters.yml'))['parameters']['pass_phrase']);"
openssl genrsa -out var/jwt/private.pem -aes256 -passout file:passphrase.txt 4096
openssl rsa -pubout -in var/jwt/private.pem -passin file:passphrase.txt -out var/jwt/public.pem
rm -f passphrase.txt # Delete passphrase file after generation of key pair