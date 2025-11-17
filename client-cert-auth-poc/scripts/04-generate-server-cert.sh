#!/bin/bash
#
# Generate Server Certificate for HTTPS
#
# This script generates a TLS server certificate for the web server.
# For production, you would typically use Let's Encrypt or another
# public CA. This is for development/testing purposes.
#
# Usage: ./04-generate-server-cert.sh [domain]
#
# Example: ./04-generate-server-cert.sh family.example.com

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERTS_DIR="${SCRIPT_DIR}/../certs"
SERVER_DIR="${CERTS_DIR}/server"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get domain name
if [ $# -eq 1 ]; then
    DOMAIN="$1"
else
    read -p "Enter domain name (e.g., family.example.com or localhost): " DOMAIN
fi

mkdir -p "${SERVER_DIR}"

echo
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Generating Server Certificate${NC}"
echo -e "${GREEN}================================${NC}"
echo
echo "Domain: ${DOMAIN}"
echo

# Create OpenSSL configuration
cat > "${SERVER_DIR}/server.conf" << EOF
[ req ]
default_bits       = 2048
distinguished_name = req_distinguished_name
string_mask        = utf8only
default_md         = sha256
x509_extensions    = v3_req

[ req_distinguished_name ]
countryName                = US
stateOrProvinceName        = California
localityName               = San Francisco
0.organizationName         = Family Website
organizationalUnitName     = Web Server
commonName                 = ${DOMAIN}

[ v3_req ]
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${DOMAIN}
DNS.2 = www.${DOMAIN}
DNS.3 = localhost
IP.1 = 127.0.0.1
EOF

echo -e "${YELLOW}Step 1: Generating server private key...${NC}"
openssl genrsa -out "${SERVER_DIR}/server-key.pem" 2048

echo -e "${YELLOW}Step 2: Creating self-signed certificate...${NC}"
# Create self-signed certificate (valid for 1 year)
# For production, this would be signed by a public CA like Let's Encrypt
openssl req -new -x509 -days 365 \
    -key "${SERVER_DIR}/server-key.pem" \
    -out "${SERVER_DIR}/server-cert.pem" \
    -config "${SERVER_DIR}/server.conf" \
    -extensions v3_req

# Set permissions
chmod 600 "${SERVER_DIR}/server-key.pem"
chmod 644 "${SERVER_DIR}/server-cert.pem"

echo
echo -e "${GREEN}✓ Server certificate generated successfully!${NC}"
echo
echo -e "${YELLOW}Certificate Details:${NC}"
openssl x509 -in "${SERVER_DIR}/server-cert.pem" -noout -subject -issuer -dates
echo
echo "Files created:"
echo "  Private key: ${SERVER_DIR}/server-key.pem"
echo "  Certificate: ${SERVER_DIR}/server-cert.pem"
echo
echo -e "${YELLOW}NOTE:${NC}"
echo "This is a self-signed certificate for development/testing."
echo "Browsers will show a security warning until you:"
echo "  1. Add this certificate to your trusted certificates, or"
echo "  2. Use a certificate from a trusted CA (like Let's Encrypt) in production"
echo
