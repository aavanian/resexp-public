#!/bin/bash
#
# List All Issued Certificates
#
# This script displays all certificates issued by the CA, including
# their status (valid, revoked, expired), serial numbers, and subjects.
#
# Usage: ./05-list-certificates.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERTS_DIR="${SCRIPT_DIR}/../certs"
CA_DIR="${CERTS_DIR}/ca"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if CA exists
if [ ! -f "${CA_DIR}/index.txt" ]; then
    echo -e "${RED}Error: CA database not found!${NC}"
    echo "Please run ./01-create-ca.sh first"
    exit 1
fi

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Issued Certificates${NC}"
echo -e "${GREEN}================================${NC}"
echo

if [ ! -s "${CA_DIR}/index.txt" ]; then
    echo "No certificates have been issued yet."
    echo "Run ./02-generate-client-cert.sh to create a certificate."
    exit 0
fi

# Function to parse and display certificate info
display_cert_info() {
    local status="$1"
    local expiry="$2"
    local revocation="$3"
    local serial="$4"
    local subject="$5"

    # Extract common name and OU from subject
    local cn=$(echo "$subject" | grep -oP 'CN=\K[^/]+' || echo "N/A")
    local ou=$(echo "$subject" | grep -oP 'OU=\K[^/]+' || echo "N/A")
    local email=$(echo "$subject" | grep -oP 'emailAddress=\K[^/]+' || echo "N/A")

    # Display based on status
    case "$status" in
        V)
            echo -e "${GREEN}[VALID]${NC} Serial: ${serial}"
            ;;
        R)
            echo -e "${RED}[REVOKED]${NC} Serial: ${serial} (Revoked: ${revocation})"
            ;;
        E)
            echo -e "${YELLOW}[EXPIRED]${NC} Serial: ${serial}"
            ;;
    esac

    echo "  Name: ${cn}"
    echo "  Email: ${email}"
    echo "  Permission: ${ou}"
    echo "  Expiry: ${expiry}"
    echo
}

# Count certificates by status
total=$(wc -l < "${CA_DIR}/index.txt")
valid=$(grep -c "^V" "${CA_DIR}/index.txt" || true)
revoked=$(grep -c "^R" "${CA_DIR}/index.txt" || true)
expired=$(grep -c "^E" "${CA_DIR}/index.txt" || true)

echo -e "${BLUE}Summary:${NC}"
echo "  Total: ${total} certificate(s)"
echo "  Valid: ${valid}"
echo "  Revoked: ${revoked}"
echo "  Expired: ${expired}"
echo
echo "================================"
echo

# Read and display each certificate
while IFS=$'\t' read -r status expiry revocation serial subject; do
    display_cert_info "$status" "$expiry" "$revocation" "$serial" "$subject"
done < "${CA_DIR}/index.txt"

echo "================================"
echo
echo -e "${YELLOW}Commands:${NC}"
echo "  View certificate details: openssl x509 -in ${CA_DIR}/newcerts/[SERIAL].pem -noout -text"
echo "  Revoke certificate: ./03-revoke-certificate.sh [SERIAL]"
echo
