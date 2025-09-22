#!/bin/bash
set -e  # Exit on any error
set -u  # Exit on undefined variables

echo "🔐 Generating Security Secrets for TMS"
echo "===================================="

# Generate random secrets
JWT_SECRET="$(openssl rand -hex 32)"
CSRF_SECRET="$(openssl rand -hex 32)"
ADMIN_PASS="$(openssl rand -base64 12)"

echo "Generated secrets:"
echo "JWT_SECRET=${JWT_SECRET}"
echo "CSRF_SECRET=${CSRF_SECRET}"
echo "ADMIN_PASS=${ADMIN_PASS}"
echo ""

# Update .env file if it exists
if [ -f .env ]; then
    echo "Updating .env file..."
    sed -i "s/JWT_SECRET=.*/JWT_SECRET=${JWT_SECRET}/" .env
    sed -i "s/CSRF_SECRET=.*/CSRF_SECRET=${CSRF_SECRET}/" .env
    sed -i "s/ADMIN_PASS=.*/ADMIN_PASS=${ADMIN_PASS}/" .env
    echo "✅ .env file updated"
else
    echo "Creating .env file from template..."
    cp .env.example .env
    sed -i "s/JWT_SECRET=.*/JWT_SECRET=${JWT_SECRET}/" .env
    sed -i "s/CSRF_SECRET=.*/CSRF_SECRET=${CSRF_SECRET}/" .env
    sed -i "s/ADMIN_PASS=.*/ADMIN_PASS=${ADMIN_PASS}/" .env
    echo "✅ .env file created"
fi

echo ""
echo "🔒 IMPORTANT: Save these credentials securely!"
echo "Admin Password: ${ADMIN_PASS}"