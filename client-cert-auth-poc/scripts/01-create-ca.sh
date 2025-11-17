#!/bin/bash
#
# Create Certificate Authority (CA) for Family Website
#
# This script creates a private Certificate Authority that will be used to sign
# client certificates for family members. Keep the CA private key VERY secure!
#
# Usage: ./01-create-ca.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERTS_DIR="${SCRIPT_DIR}/../certs"
CA_DIR="${CERTS_DIR}/ca"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Creating Family Certificate Authority${NC}"
echo -e "${GREEN}======================================${NC}"
echo

# Create directory structure
mkdir -p "${CA_DIR}"
mkdir -p "${CERTS_DIR}/clients"
mkdir -p "${CERTS_DIR}/server"

# Create CA configuration file
cat > "${CA_DIR}/ca.conf" << 'EOF'
[ req ]
default_bits       = 4096
distinguished_name = req_distinguished_name
string_mask        = utf8only
default_md         = sha256
x509_extensions    = v3_ca

[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
countryName_default             = US
stateOrProvinceName             = State or Province Name
stateOrProvinceName_default     = California
localityName                    = Locality Name
localityName_default            = San Francisco
0.organizationName              = Organization Name
0.organizationName_default      = Family Certificate Authority
organizationalUnitName          = Organizational Unit Name
organizationalUnitName_default  = Family CA
commonName                      = Common Name
commonName_default              = Family Root CA
emailAddress                    = Email Address
emailAddress_default            = admin@family.example.com

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
EOF

echo -e "${YELLOW}Step 1: Generating CA private key...${NC}"
# Generate CA private key (4096-bit RSA for strong security)
openssl genrsa -aes256 -out "${CA_DIR}/ca-key.pem" 4096

echo
echo -e "${YELLOW}Step 2: Creating CA certificate...${NC}"
# Create CA certificate (valid for 10 years)
openssl req -new -x509 -days 3650 -key "${CA_DIR}/ca-key.pem" \
    -sha256 -extensions v3_ca -out "${CA_DIR}/ca-cert.pem" \
    -config "${CA_DIR}/ca.conf"

# Set restrictive permissions on CA private key
chmod 400 "${CA_DIR}/ca-key.pem"

# Create certificate database files for tracking issued certificates
touch "${CA_DIR}/index.txt"
echo 1000 > "${CA_DIR}/serial.txt"
echo 1000 > "${CA_DIR}/crlnumber.txt"

# Create OpenSSL configuration for certificate signing
cat > "${CA_DIR}/signing.conf" << 'EOF'
[ ca ]
default_ca = CA_default

[ CA_default ]
dir              = REPLACE_CA_DIR
certs            = $dir
crl_dir          = $dir/crl
new_certs_dir    = $dir/newcerts
database         = $dir/index.txt
serial           = $dir/serial.txt
RANDFILE         = $dir/.rand
private_key      = $dir/ca-key.pem
certificate      = $dir/ca-cert.pem
crlnumber        = $dir/crlnumber.txt
crl              = $dir/crl.pem
crl_extensions   = crl_ext
default_crl_days = 30
default_md       = sha256
name_opt         = ca_default
cert_opt         = ca_default
default_days     = 375
preserve         = no
policy           = policy_loose

[ policy_loose ]
countryName            = optional
stateOrProvinceName    = optional
localityName           = optional
organizationName       = optional
organizationalUnitName = optional
commonName             = supplied
emailAddress           = optional

[ req ]
default_bits       = 2048
distinguished_name = req_distinguished_name
string_mask        = utf8only
default_md         = sha256

[ req_distinguished_name ]
countryName                    = Country Name (2 letter code)
stateOrProvinceName            = State or Province Name
localityName                   = Locality Name
0.organizationName             = Organization Name
organizationalUnitName         = Organizational Unit Name
commonName                     = Common Name
emailAddress                   = Email Address

[ client_cert ]
basicConstraints       = CA:FALSE
nsCertType             = client, email
nsComment              = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid,issuer
keyUsage               = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage       = clientAuth, emailProtection

[ crl_ext ]
authorityKeyIdentifier = keyid:always

[ ocsp ]
basicConstraints       = CA:FALSE
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid,issuer
keyUsage               = critical, digitalSignature
extendedKeyUsage       = critical, OCSPSigning
EOF

# Replace placeholder with actual CA directory
sed -i "s|REPLACE_CA_DIR|${CA_DIR}|g" "${CA_DIR}/signing.conf"

# Create directory for new certificates
mkdir -p "${CA_DIR}/newcerts"
mkdir -p "${CA_DIR}/crl"

echo
echo -e "${GREEN}✓ Certificate Authority created successfully!${NC}"
echo
echo -e "${YELLOW}IMPORTANT SECURITY NOTES:${NC}"
echo -e "1. The CA private key is stored at: ${CA_DIR}/ca-key.pem"
echo -e "2. ${RED}BACK UP THIS KEY SECURELY AND KEEP IT SAFE!${NC}"
echo -e "3. Anyone with access to this key can create valid certificates"
echo -e "4. Consider storing the backup on encrypted offline media"
echo -e "5. The CA certificate (public) is at: ${CA_DIR}/ca-cert.pem"
echo
echo -e "${GREEN}Next step: Run ./02-generate-client-cert.sh to create client certificates${NC}"
echo
