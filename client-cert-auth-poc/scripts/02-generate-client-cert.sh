#!/bin/bash
#
# Generate Client Certificate for Family Member
#
# This script generates a client certificate signed by the Family CA.
# The certificate can be assigned different permission levels based on
# the Organizational Unit (OU) field.
#
# Usage: ./02-generate-client-cert.sh [name] [email] [permission-level]
#
# Permission levels:
#   - admin: Full administrative access
#   - family: Family member access
#   - guest: Limited guest access
#
# Example: ./02-generate-client-cert.sh "John Doe" "john@family.example.com" family

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERTS_DIR="${SCRIPT_DIR}/../certs"
CA_DIR="${CERTS_DIR}/ca"
CLIENT_DIR="${CERTS_DIR}/clients"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if CA exists
if [ ! -f "${CA_DIR}/ca-cert.pem" ]; then
    echo -e "${RED}Error: CA certificate not found!${NC}"
    echo "Please run ./01-create-ca.sh first"
    exit 1
fi

# Parse arguments or prompt for input
if [ $# -eq 3 ]; then
    NAME="$1"
    EMAIL="$2"
    PERMISSION="$3"
else
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Generate Client Certificate${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo

    read -p "Enter name (e.g., 'John Doe'): " NAME
    read -p "Enter email (e.g., 'john@family.example.com'): " EMAIL
    echo
    echo "Permission levels:"
    echo "  1) admin   - Full administrative access"
    echo "  2) family  - Family member access"
    echo "  3) guest   - Limited guest access"
    echo
    read -p "Enter permission level (admin/family/guest): " PERMISSION
fi

# Validate permission level
case "$PERMISSION" in
    admin|family|guest)
        ;;
    *)
        echo -e "${RED}Error: Invalid permission level '${PERMISSION}'${NC}"
        echo "Must be one of: admin, family, guest"
        exit 1
        ;;
esac

# Create safe filename from name
FILENAME=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
CERT_DIR="${CLIENT_DIR}/${FILENAME}"

# Check if certificate already exists
if [ -d "${CERT_DIR}" ]; then
    echo -e "${YELLOW}Warning: Certificate for '${NAME}' already exists at ${CERT_DIR}${NC}"
    read -p "Do you want to overwrite it? (yes/no): " OVERWRITE
    if [ "$OVERWRITE" != "yes" ]; then
        echo "Aborted."
        exit 0
    fi
    rm -rf "${CERT_DIR}"
fi

mkdir -p "${CERT_DIR}"

echo
echo -e "${YELLOW}Generating certificate for:${NC}"
echo "  Name: ${NAME}"
echo "  Email: ${EMAIL}"
echo "  Permission: ${PERMISSION}"
echo "  Output directory: ${CERT_DIR}"
echo

# Map permission to OU name
case "$PERMISSION" in
    admin)
        OU="Admin"
        ;;
    family)
        OU="Family"
        ;;
    guest)
        OU="Guest"
        ;;
esac

# Create OpenSSL configuration for this certificate
cat > "${CERT_DIR}/cert.conf" << EOF
[ req ]
default_bits       = 2048
distinguished_name = req_distinguished_name
string_mask        = utf8only
default_md         = sha256
req_extensions     = req_ext

[ req_distinguished_name ]
countryName                = US
stateOrProvinceName        = California
localityName               = San Francisco
0.organizationName         = Family
organizationalUnitName     = ${OU}
commonName                 = ${NAME}
emailAddress               = ${EMAIL}

[ req_ext ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection
subjectAltName = @alt_names

[ alt_names ]
email.1 = ${EMAIL}
EOF

echo -e "${YELLOW}Step 1: Generating private key...${NC}"
# Generate private key for client
openssl genrsa -out "${CERT_DIR}/key.pem" 2048

echo -e "${YELLOW}Step 2: Creating certificate signing request (CSR)...${NC}"
# Create certificate signing request
openssl req -new -key "${CERT_DIR}/key.pem" \
    -out "${CERT_DIR}/csr.pem" \
    -config "${CERT_DIR}/cert.conf"

echo -e "${YELLOW}Step 3: Signing certificate with CA...${NC}"
# Sign the certificate with CA (valid for 1 year)
openssl ca -config "${CA_DIR}/signing.conf" \
    -extensions client_cert \
    -days 365 \
    -notext \
    -md sha256 \
    -in "${CERT_DIR}/csr.pem" \
    -out "${CERT_DIR}/cert.pem" \
    -batch

echo -e "${YELLOW}Step 4: Creating PKCS#12 bundle (.p12 file)...${NC}"
# Generate a random password for the P12 file
P12_PASSWORD=$(openssl rand -base64 12)

# Create PKCS#12 bundle for easy import (contains private key + certificate + CA cert)
openssl pkcs12 -export \
    -out "${CERT_DIR}/${FILENAME}.p12" \
    -inkey "${CERT_DIR}/key.pem" \
    -in "${CERT_DIR}/cert.pem" \
    -certfile "${CA_DIR}/ca-cert.pem" \
    -name "${NAME}" \
    -password "pass:${P12_PASSWORD}"

# Save password to file
echo "${P12_PASSWORD}" > "${CERT_DIR}/p12-password.txt"

# Set restrictive permissions
chmod 600 "${CERT_DIR}/key.pem"
chmod 600 "${CERT_DIR}/${FILENAME}.p12"
chmod 600 "${CERT_DIR}/p12-password.txt"

# Get certificate serial number for tracking
SERIAL=$(openssl x509 -in "${CERT_DIR}/cert.pem" -noout -serial | cut -d= -f2)

# Create a README for this certificate
cat > "${CERT_DIR}/README.txt" << EOF
Client Certificate for: ${NAME}
Email: ${EMAIL}
Permission Level: ${PERMISSION}
Generated: $(date)
Serial Number: ${SERIAL}
Valid for: 365 days

FILES IN THIS DIRECTORY:
========================

${FILENAME}.p12          - PKCS#12 bundle (for installation on most devices)
p12-password.txt        - Password for the .p12 file (KEEP SECURE!)
cert.pem                - Certificate in PEM format
key.pem                 - Private key in PEM format (KEEP SECURE!)
csr.pem                 - Certificate signing request (for reference)
cert.conf               - OpenSSL configuration used (for reference)

INSTALLATION:
=============

1. Most users: Use the ${FILENAME}.p12 file
   - This contains everything needed (private key + certificate + CA certificate)
   - Password is in p12-password.txt

2. Advanced users: Use cert.pem and key.pem separately

See ../docs/CLIENT_INSTALLATION.md for detailed installation instructions
for different platforms and browsers.

SECURITY:
=========

- Keep the .p12 file and password secure!
- Do not share these files via unencrypted channels
- Back up the .p12 file securely
- If compromised, contact admin immediately for revocation

EXPIRATION:
===========

This certificate will expire in 1 year. You will need to renew it before:
$(openssl x509 -in "${CERT_DIR}/cert.pem" -noout -enddate | cut -d= -f2)
EOF

echo
echo -e "${GREEN}✓ Certificate generated successfully!${NC}"
echo
echo -e "${YELLOW}Certificate Details:${NC}"
echo "  Location: ${CERT_DIR}"
echo "  P12 File: ${CERT_DIR}/${FILENAME}.p12"
echo "  Password: ${P12_PASSWORD} (also saved in p12-password.txt)"
echo "  Serial Number: ${SERIAL}"
echo
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Securely send the .p12 file and password to ${NAME}"
echo "  2. User should follow CLIENT_INSTALLATION.md to install the certificate"
echo "  3. Keep a secure backup of this certificate"
echo
echo -e "${YELLOW}SECURITY WARNING:${NC}"
echo -e "${RED}  - Do NOT send the password and .p12 file via the same channel${NC}"
echo -e "${RED}  - Consider using encrypted communication (Signal, encrypted email, etc.)${NC}"
echo
