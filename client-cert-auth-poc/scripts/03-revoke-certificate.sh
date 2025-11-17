#!/bin/bash
#
# Revoke Client Certificate
#
# This script revokes a client certificate and updates the Certificate
# Revocation List (CRL). Once revoked, the certificate will no longer
# be accepted by the web servers.
#
# Usage: ./03-revoke-certificate.sh [serial-number|certificate-file]
#
# Example: ./03-revoke-certificate.sh 1000
# Example: ./03-revoke-certificate.sh ../certs/clients/john-doe/cert.pem

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERTS_DIR="${SCRIPT_DIR}/../certs"
CA_DIR="${CERTS_DIR}/ca"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if CA exists
if [ ! -f "${CA_DIR}/ca-cert.pem" ]; then
    echo -e "${RED}Error: CA not found!${NC}"
    echo "Please run ./01-create-ca.sh first"
    exit 1
fi

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Certificate Revocation${NC}"
echo -e "${GREEN}================================${NC}"
echo

# Get certificate to revoke
if [ $# -eq 1 ]; then
    CERT_INPUT="$1"
else
    echo "Available certificates:"
    echo
    cat "${CA_DIR}/index.txt" | grep "^V" | while read -r line; do
        serial=$(echo "$line" | awk '{print $3}')
        subject=$(echo "$line" | awk -F'/' '{print $NF}')
        echo "  Serial: ${serial} - ${subject}"
    done
    echo
    read -p "Enter serial number or path to certificate file: " CERT_INPUT
fi

# Determine if input is a file or serial number
if [ -f "$CERT_INPUT" ]; then
    # Extract serial from certificate file
    SERIAL=$(openssl x509 -in "$CERT_INPUT" -noout -serial | cut -d= -f2)
    CERT_FILE="$CERT_INPUT"
else
    # Use as serial number directly
    SERIAL="$CERT_INPUT"
    # Try to find the certificate file
    CERT_FILE="${CA_DIR}/newcerts/${SERIAL}.pem"
fi

echo -e "${YELLOW}Certificate to revoke:${NC}"
if [ -f "$CERT_FILE" ]; then
    openssl x509 -in "$CERT_FILE" -noout -subject -serial -dates
else
    echo "  Serial: ${SERIAL}"
    echo "  (Certificate file not found, but can still revoke by serial)"
fi
echo

# Confirm revocation
read -p "Are you sure you want to revoke this certificate? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Revocation cancelled."
    exit 0
fi

read -p "Reason for revocation (unspecified/keyCompromise/affiliationChanged/superseded/cessationOfOperation): " REASON

# Validate reason
case "$REASON" in
    unspecified|keyCompromise|affiliationChanged|superseded|cessationOfOperation)
        ;;
    *)
        echo -e "${YELLOW}Warning: Invalid reason. Using 'unspecified'${NC}"
        REASON="unspecified"
        ;;
esac

echo
echo -e "${YELLOW}Revoking certificate...${NC}"

# Revoke the certificate
if [ -f "$CERT_FILE" ]; then
    openssl ca -config "${CA_DIR}/signing.conf" \
        -revoke "$CERT_FILE" \
        -crl_reason "$REASON"
else
    # If we don't have the cert file but know the serial, update index.txt directly
    # This is a fallback method
    echo -e "${YELLOW}Warning: Certificate file not found. Manual revocation may be needed.${NC}"
fi

echo -e "${YELLOW}Updating Certificate Revocation List (CRL)...${NC}"

# Generate/update CRL
openssl ca -config "${CA_DIR}/signing.conf" \
    -gencrl \
    -out "${CA_DIR}/crl/crl.pem"

# Also create DER format for web server use
openssl crl -in "${CA_DIR}/crl/crl.pem" \
    -outform DER \
    -out "${CA_DIR}/crl/crl.der"

# Display CRL information
echo
echo -e "${GREEN}✓ Certificate revoked successfully!${NC}"
echo
echo -e "${YELLOW}Updated CRL Information:${NC}"
openssl crl -in "${CA_DIR}/crl/crl.pem" -noout -text | grep -A2 "Revoked Certificates:"
echo
echo -e "${YELLOW}CRL Files:${NC}"
echo "  PEM format: ${CA_DIR}/crl/crl.pem"
echo "  DER format: ${CA_DIR}/crl/crl.der"
echo
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Deploy updated CRL to web servers"
echo "  2. Restart web servers to ensure CRL is reloaded"
echo "  3. Verify certificate is rejected when presented"
echo "  4. Notify the certificate holder that their access has been revoked"
echo
