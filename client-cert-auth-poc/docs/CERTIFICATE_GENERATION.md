# Certificate Generation Guide

This guide explains how to set up your Certificate Authority and generate certificates for family members.

## Table of Contents

- [Overview](#overview)
- [Setting Up the Certificate Authority](#setting-up-the-certificate-authority)
- [Generating Client Certificates](#generating-client-certificates)
- [Certificate Lifecycle Management](#certificate-lifecycle-management)
- [Certificate Revocation](#certificate-revocation)
- [Advanced Topics](#advanced-topics)

## Overview

### What is a Certificate Authority?

A Certificate Authority (CA) is a trusted entity that issues digital certificates. In this family setup:

- **You create your own private CA** - You control who gets access
- **CA signs client certificates** - Proves certificates are authentic
- **Server trusts the CA** - Only certificates signed by your CA are accepted

### Certificate Types

This project uses three types of certificates:

1. **CA Certificate** (ca-cert.pem)
   - Signs other certificates
   - Public - safe to share
   - Created once, lasts 10 years

2. **Server Certificate** (server-cert.pem)
   - Enables HTTPS
   - For your website domain
   - Renewed annually

3. **Client Certificates** (one per family member)
   - Proves user identity
   - Contains permission level
   - Renewed annually

## Setting Up the Certificate Authority

### Step 1: Create the CA

```bash
# Using Makefile (easiest)
make setup-ca

# Or run script directly
./scripts/01-create-ca.sh
```

You'll be prompted for:
- **Password** - Protects the CA private key (CHOOSE A STRONG PASSWORD!)
- **Country/State/City** - Certificate location info
- **Organization Name** - e.g., "Smith Family CA"
- **Email** - Admin email address

### What This Creates

```
certs/ca/
├── ca-key.pem          # CA private key (KEEP SECURE!)
├── ca-cert.pem         # CA certificate (public, can share)
├── ca.conf             # Configuration file
├── signing.conf        # Certificate signing config
├── index.txt           # Certificate database
├── serial.txt          # Next serial number
└── crlnumber.txt       # Revocation list tracking
```

### CRITICAL: Secure the CA Private Key

The file `certs/ca/ca-key.pem` is the most important file in your setup:

⚠️ **If someone steals this file, they can:**
- Create certificates for anyone
- Impersonate family members
- Access your family site

⚠️ **If you lose this file, you:**
- Cannot issue new certificates
- Must rebuild everything
- Must reissue all certificates

**How to protect it:**

```bash
# 1. Verify permissions (should be 400 = read-only for owner)
ls -l certs/ca/ca-key.pem

# 2. Create encrypted backup
tar -czf ca-backup.tar.gz certs/ca/
gpg -c ca-backup.tar.gz  # Encrypts with password
rm ca-backup.tar.gz

# 3. Store backup securely:
# - Encrypted external drive in safe
# - Password manager with encrypted attachments
# - Encrypted cloud storage (Dropbox, Google Drive, etc. - but ENCRYPTED first)
```

### Step 2: Create Server Certificate

```bash
# For development/testing (localhost)
make create-server-cert

# For production (your domain)
./scripts/04-generate-server-cert.sh family.example.com
```

**Note:** For production with a real domain, consider using **Let's Encrypt** instead for your server certificate. You'll still use your own CA for client certificates.

## Generating Client Certificates

### Quick Generation

```bash
# Interactive mode - asks for details
make generate-cert

# Or specify everything on command line
./scripts/02-generate-client-cert.sh "John Doe" "john@family.com" family
```

### Permission Levels

Three permission levels are available:

| Level | Access | Use For |
|-------|--------|---------|
| **admin** | Full access to all pages | Site administrators, parents |
| **family** | Access to family pages | Family members, trusted friends |
| **guest** | Public pages only | Temporary guests, limited access |

**Examples:**

```bash
# Admin certificate (for yourself)
make generate-admin

# Family member certificate
./scripts/02-generate-client-cert.sh "Jane Doe" "jane@example.com" family

# Guest certificate
./scripts/02-generate-client-cert.sh "Bob Smith" "bob@example.com" guest
```

### What Gets Created

For each user, a directory is created in `certs/clients/[name]/`:

```
certs/clients/john-doe/
├── john-doe.p12        # PKCS#12 bundle (give to user)
├── p12-password.txt    # Password for .p12 file
├── cert.pem            # Certificate (PEM format)
├── key.pem             # Private key (PEM format)
├── csr.pem             # Certificate signing request
├── cert.conf           # OpenSSL config used
└── README.txt          # Instructions for user
```

### Understanding the Files

**For the user (what to give them):**
- `john-doe.p12` - The certificate file to install
- Password from `p12-password.txt` - Needed during installation

**For your records:**
- `cert.pem` - Certificate in standard format
- `key.pem` - Private key
- `README.txt` - Installation instructions

**For reference only:**
- `csr.pem` - The certificate request
- `cert.conf` - OpenSSL configuration used

### Distributing Certificates to Users

**SECURITY: Never send .p12 file and password together!**

**Safe distribution methods:**

**Option 1: In-person (Best)**
```
1. Copy .p12 file to USB drive
2. Give USB drive to user in person
3. Tell them password verbally or via separate secure channel
```

**Option 2: Separate Channels**
```
1. Email the .p12 file as attachment
2. Send password via:
   - Text message (SMS)
   - Signal/WhatsApp
   - Phone call
   - Different email account
```

**Option 3: Encrypted Messaging**
```
1. Use Signal, WhatsApp, or similar end-to-end encrypted app
2. Send .p12 file
3. Send password in separate message
```

**DO NOT:**
- ❌ Email .p12 and password together
- ❌ Post password in unencrypted chat
- ❌ Leave .p12 files on shared network drives
- ❌ Use SMS for .p12 files (too large and insecure)

## Certificate Lifecycle Management

### Certificate Validity

Default validity periods:
- **CA Certificate**: 10 years
- **Server Certificate**: 1 year
- **Client Certificates**: 1 year

### Checking Certificate Expiration

```bash
# List all certificates and their status
make list-certs

# Check specific certificate
openssl x509 -in certs/clients/john-doe/cert.pem -noout -dates

# Check when certificate expires
openssl x509 -in certs/clients/john-doe/cert.pem -noout -enddate
```

### Certificate Renewal

**Before expiration (recommended):**

```bash
# Generate new certificate with same details
./scripts/02-generate-client-cert.sh "John Doe" "john@example.com" family

# Script will ask if you want to overwrite - answer "yes"
```

**The old certificate continues working until:**
- It expires naturally, OR
- You revoke it

**Best practice:**
1. Generate new certificate
2. Give to user
3. Wait until user confirms new cert installed
4. Revoke old certificate

### Renewal Notifications

The Flask backend automatically shows a warning 30 days before expiration. Users will see:

```
⚠️ Certificate Expiring Soon!
Your certificate will expire in 25 days (2024-12-15)
```

**Setting up automated reminders:**

```bash
# Add to crontab to email reminders
0 9 * * 1 /path/to/scripts/check-expiring-certs.sh
```

Create `scripts/check-expiring-certs.sh`:

```bash
#!/bin/bash
# Email certificates expiring in next 30 days

DAYS=30
CERTS_DIR="./certs/clients"

find "$CERTS_DIR" -name "cert.pem" | while read cert; do
    expiry=$(openssl x509 -in "$cert" -noout -enddate | cut -d= -f2)
    expiry_epoch=$(date -d "$expiry" +%s)
    now_epoch=$(date +%s)
    days_left=$(( ($expiry_epoch - $now_epoch) / 86400 ))

    if [ $days_left -lt $DAYS ]; then
        name=$(openssl x509 -in "$cert" -noout -subject | grep -oP 'CN=\K[^/]+')
        email=$(openssl x509 -in "$cert" -noout -subject | grep -oP 'emailAddress=\K[^/]+')
        echo "Certificate for $name ($email) expires in $days_left days"
        # Add email command here
    fi
done
```

## Certificate Revocation

### When to Revoke

Revoke a certificate if:

- ✅ User's device is lost or stolen
- ✅ User's .p12 file is compromised
- ✅ User should no longer have access
- ✅ Certificate was issued by mistake
- ✅ User left the family

### How to Revoke

```bash
# Interactive mode
make revoke-cert

# Or specify serial number
./scripts/03-revoke-certificate.sh 1000

# Or specify certificate file
./scripts/03-revoke-certificate.sh certs/clients/john-doe/cert.pem
```

You'll be asked for:
- **Confirmation** - Are you sure?
- **Reason** - Why revoking? Options:
  - `unspecified` - General revocation
  - `keyCompromise` - Private key was stolen/exposed
  - `affiliationChanged` - User left organization
  - `superseded` - Replaced by new certificate
  - `cessationOfOperation` - No longer needed

### After Revocation

1. **CRL is automatically updated** in `certs/ca/crl/`

2. **Restart the server to load new CRL:**
   ```bash
   make restart-nginx  # or restart-caddy
   ```

3. **Verify revocation:**
   ```bash
   # Check CRL contents
   openssl crl -in certs/ca/crl/crl.pem -noout -text

   # Try to access site with revoked cert - should fail
   curl -k --cert certs/clients/john-doe/cert.pem \
        --key certs/clients/john-doe/key.pem \
        https://localhost/
   ```

### Certificate Revocation List (CRL)

CRL is a list of revoked certificates. Enable it in production:

**nginx (`nginx/nginx.conf`):**
```nginx
ssl_crl /etc/nginx/certs/crl.pem;
```

**Caddy (`caddy/Caddyfile`):**
```caddyfile
# Update to Caddy 2.7+ for CRL support
client_auth {
    mode request
    trusted_ca_cert_file /etc/caddy/certs/ca-cert.pem
    # CRL support varies by Caddy version
}
```

**Mount CRL in Docker Compose:**

```yaml
volumes:
  - ./certs/ca/crl/crl.pem:/etc/nginx/certs/crl.pem:ro
```

### OCSP (Advanced)

For more dynamic revocation checking, OCSP (Online Certificate Status Protocol) can be used instead of CRL. This is more complex and typically used in enterprise environments. Not covered in this basic PoC.

## Advanced Topics

### Changing Permission Levels

To change a user's permission level:

```bash
# 1. Generate new certificate with different permission
./scripts/02-generate-client-cert.sh "John Doe" "john@example.com" admin
# (answer "yes" to overwrite)

# 2. Give new certificate to user

# 3. Optionally revoke old certificate
make revoke-cert
```

### Batch Certificate Generation

Create multiple certificates at once:

```bash
#!/bin/bash
# batch-create-certs.sh

# Format: Name,Email,Permission
cat <<EOF | while IFS=, read name email perm; do
Alice Anderson,alice@example.com,admin
Bob Brown,bob@example.com,family
Carol Clark,carol@example.com,family
Dave Davis,dave@example.com,guest
EOF
    ./scripts/02-generate-client-cert.sh "$name" "$email" "$perm"
done
```

### Custom Certificate Fields

Edit `scripts/02-generate-client-cert.sh` to add custom fields:

```bash
# In the cert.conf section, add:
[ req_distinguished_name ]
# ... existing fields ...
1.organizationName = "Department Name"  # Add custom field
```

### Certificate Formats

The scripts generate certificates in multiple formats:

**PEM Format** (`.pem`)
- Text-based, Base64 encoded
- Used by: curl, openssl, most servers
- Files: `cert.pem`, `key.pem`

**PKCS#12 Format** (`.p12`)
- Binary format, password-protected
- Used by: Most browsers, mobile devices
- Contains: private key + certificate + CA cert
- Files: `username.p12`

**DER Format** (`.der`, `.crt`)
- Binary version of PEM
- Used by: Some Java applications
- Convert: `openssl x509 -in cert.pem -outform DER -out cert.der`

### Intermediate CA (Advanced)

For larger deployments, create an intermediate CA:

```bash
# 1. Create intermediate CA key
openssl genrsa -aes256 -out intermediate-key.pem 4096

# 2. Create intermediate CA CSR
openssl req -new -key intermediate-key.pem -out intermediate-csr.pem

# 3. Sign with root CA
openssl ca -config certs/ca/signing.conf \
    -extensions v3_intermediate_ca \
    -days 3650 -notext -md sha256 \
    -in intermediate-csr.pem \
    -out intermediate-cert.pem

# 4. Use intermediate CA to sign client certificates
```

Benefits:
- Keep root CA offline for security
- Easier to revoke all certificates (revoke intermediate)
- Better separation of duties

### Troubleshooting

**Error: "CA certificate not found"**
```bash
# Solution: Create the CA first
make setup-ca
```

**Error: "serial number already used"**
```bash
# Solution: Certificate database may be corrupted
# Check index.txt and serial.txt
cat certs/ca/index.txt
cat certs/ca/serial.txt
```

**Error: "unable to write 'random state'"**
```bash
# Solution: Permission issue
chmod 755 certs/ca
```

**Certificate generation hangs at password prompt**
```bash
# Solution: CA key password required
# Enter the password you set when creating the CA
```

**Generated .p12 file won't open**
```bash
# Verify .p12 file
openssl pkcs12 -in file.p12 -info -noout

# If corrupted, regenerate certificate
```

## Quick Reference

```bash
# Setup
make setup-ca                    # Create CA (do this first)
make create-server-cert          # Create server certificate

# Generate certificates
make generate-cert               # Interactive
make generate-admin              # Quick admin cert
make generate-family             # Quick family cert
make generate-guest              # Quick guest cert

# Management
make list-certs                  # Show all certificates
make revoke-cert                 # Revoke a certificate
make verify-cert CERT=path.pem   # Verify certificate

# Information
make show-ca-cert                # Show CA details
make show-server-cert            # Show server cert details
```

## Security Reminders

1. ✅ **Backup the CA private key** - You can't recover from losing it
2. ✅ **Use strong passwords** - For CA key and .p12 files
3. ✅ **Secure distribution** - Never send .p12 and password together
4. ✅ **Monitor expiration** - Set up renewal reminders
5. ✅ **Revoke promptly** - If a certificate is compromised
6. ✅ **Enable CRL** - In production environments
7. ✅ **Audit regularly** - Review who has certificates

## Further Reading

- [OpenSSL Certificate Authority](https://jamielinux.com/docs/openssl-certificate-authority/)
- [X.509 Certificate Format](https://en.wikipedia.org/wiki/X.509)
- [PKCS #12 Format](https://en.wikipedia.org/wiki/PKCS_12)
- [Certificate Revocation Lists](https://en.wikipedia.org/wiki/Certificate_revocation_list)
