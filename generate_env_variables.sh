#!/bin/bash
# Author: Ravi Prakash Yadav
# Generate random values for each environment variable
APP_KEYS=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")
API_TOKEN_SALT=$(node -e "console.log(require('crypto').randomBytes(16).toString('base64'))")
ADMIN_JWT_SECRET=$(node -e "console.log(require('crypto').randomBytes(16).toString('base64'))")

TRANSFER_TOKEN_SALT=$(node -e "console.log(require('crypto').randomBytes(16).toString('base64'))")
# Export variables
export APP_KEYS
export API_TOKEN_SALT
export ADMIN_JWT_SECRET
export TRANSFER_TOKEN_SALT

# Optionally, write them to a .env file
echo "APP_KEYS=${APP_KEYS}" > .env
echo "API_TOKEN_SALT=${API_TOKEN_SALT}" >> .env
echo "ADMIN_JWT_SECRET=${ADMIN_JWT_SECRET}" >> .env

echo "Environment variables generated and exported:"
echo "APP_KEYS=${APP_KEYS}"
echo "API_TOKEN_SALT=${API_TOKEN_SALT}"
echo "ADMIN_JWT_SECRET=${ADMIN_JWT_SECRET}"
