# Client Certificate Authentication PoC

A complete proof-of-concept implementation demonstrating client certificate authentication for a family website using Docker, with two web server options (nginx and Caddy).

## 🎯 Purpose

This project demonstrates how to implement secure, password-less authentication using client certificates for a private family website. It's designed to be:

- **Accessible** - Easy to set up for family members with moderate technical skills
- **Secure** - Follows best practices for TLS and certificate management
- **Educational** - Well-documented with clear examples and explanations
- **Practical** - Production-ready architecture with two implementation options

## ✨ Features

- ✅ **Two implementation options**:
  - Option A: nginx (traditional, widely-used)
  - Option B: Caddy (modern, simpler configuration)
- ✅ **Certificate Authority (CA) management** with scripts
- ✅ **Three permission levels** (Admin, Family, Guest)
- ✅ **Certificate generation and revocation** tools
- ✅ **Certificate Revocation List (CRL)** support
- ✅ **Docker-based deployment** for easy setup
- ✅ **Comprehensive documentation** for all platforms
- ✅ **Web UI** showing certificate info and permissions
- ✅ **Cross-platform support** - macOS, Windows, Linux, iOS, Android

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Documentation](#documentation)
- [Implementation Options](#implementation-options)
- [Security Considerations](#security-considerations)
- [Use Cases](#use-cases)
- [Requirements](#requirements)
- [License](#license)

## 🚀 Quick Start

### 1. Prerequisites

```bash
# Required
- Docker & Docker Compose
- OpenSSL
- Make (optional but recommended)
- Bash

# Verify installations
docker --version
docker-compose --version
openssl version
```

### 2. Complete Demo Setup

Set up everything with one command:

```bash
# Creates CA, server certificate, and 3 demo client certificates
make demo-setup
```

This creates:
- Certificate Authority (you'll set a password)
- Server certificate for HTTPS
- Admin certificate (`admin-user`)
- Family member certificate (`family-member`)
- Guest certificate (`guest-user`)

### 3. Start the Server

Choose your preferred implementation:

**Option A: nginx**
```bash
make start-nginx
```

**Option B: Caddy**
```bash
make start-caddy
```

The server will be available at `https://localhost`

### 4. Install a Client Certificate

**macOS/Windows:**
1. Locate a `.p12` file in `certs/clients/[username]/`
2. Find the password in `certs/clients/[username]/p12-password.txt`
3. Double-click the `.p12` file and enter the password

**iOS/Android:**
- See detailed instructions in [docs/CLIENT_INSTALLATION.md](docs/CLIENT_INSTALLATION.md)

### 5. Access the Website

1. Open browser (Safari, Chrome, Firefox, etc.)
2. Visit `https://localhost`
3. Accept the security warning (self-signed server certificate)
4. Select your client certificate when prompted
5. Check "Remember" or "Always allow"

You should see your certificate information and permission level displayed!

### 6. Test Different Permission Levels

Try accessing these pages with different certificates:

- `/` - Home (everyone)
- `/family` - Family page (family member or admin only)
- `/admin` - Admin page (admin only)
- `/api/cert-info` - JSON API (everyone)

## 📁 Project Structure

```
client-cert-auth-poc/
├── README.md                          # This file
├── Makefile                           # Convenient commands
├── docker-compose.nginx.yml           # nginx deployment
├── docker-compose.caddy.yml           # Caddy deployment
├── .gitignore                         # Git ignore rules
│
├── backend/                           # Flask backend
│   ├── app.py                         # Main application
│   ├── pyproject.toml                 # Python dependencies (uv)
│   ├── Dockerfile                     # Backend container
│   └── .env.example                   # Environment variables template
│
├── nginx/                             # nginx configuration
│   ├── nginx.conf                     # nginx config with client cert auth
│   └── Dockerfile                     # nginx container
│
├── caddy/                             # Caddy configuration
│   ├── Caddyfile                      # Caddy config with client cert auth
│   └── Dockerfile                     # Caddy container
│
├── scripts/                           # Certificate management
│   ├── 01-create-ca.sh                # Create Certificate Authority
│   ├── 02-generate-client-cert.sh     # Generate client certificates
│   ├── 03-revoke-certificate.sh       # Revoke certificates
│   ├── 04-generate-server-cert.sh     # Generate server certificate
│   └── 05-list-certificates.sh        # List all certificates
│
├── certs/                             # Certificates (not in git)
│   ├── ca/                            # Certificate Authority
│   ├── server/                        # Server certificates
│   └── clients/                       # Client certificates
│
└── docs/                              # Documentation
    ├── SERVER_SETUP.md                # Server setup and configuration
    ├── CERTIFICATE_GENERATION.md      # CA and certificate management
    ├── CLIENT_INSTALLATION.md         # Install certs on devices
    ├── USER_BEST_PRACTICES.md         # Security guidelines for users
    └── PERMISSIONS_GUIDE.md           # Permission system details
```

## 📖 Documentation

### For Administrators

- **[SERVER_SETUP.md](docs/SERVER_SETUP.md)** - How to set up and configure the server
  - Docker deployment instructions
  - Configuration options
  - Production deployment guide
  - Troubleshooting

- **[CERTIFICATE_GENERATION.md](docs/CERTIFICATE_GENERATION.md)** - Managing certificates
  - Creating the CA
  - Generating client certificates
  - Certificate lifecycle management
  - Revocation procedures

- **[PERMISSIONS_GUIDE.md](docs/PERMISSIONS_GUIDE.md)** - Understanding and customizing permissions
  - How permissions work
  - Adding custom permission levels
  - Advanced permission patterns
  - Code examples

### For Users

- **[CLIENT_INSTALLATION.md](docs/CLIENT_INSTALLATION.md)** - Installing certificates
  - Step-by-step for macOS, Windows, Linux
  - Mobile installation (iOS, Android)
  - Browser-specific instructions
  - Troubleshooting

- **[USER_BEST_PRACTICES.md](docs/USER_BEST_PRACTICES.md)** - Security guidelines
  - How to use certificates safely
  - Recognizing phishing attempts
  - Certificate backup and recovery
  - What to do if device is lost/stolen

## 🔄 Implementation Options

### Option A: nginx

**Pros:**
- ✅ Widely used and well-documented
- ✅ Excellent performance
- ✅ Mature and battle-tested
- ✅ More configuration options

**Cons:**
- ❌ More complex configuration syntax
- ❌ Manual certificate management for server cert

**Best for:** Production deployments, high traffic, familiarity with nginx

**Start:**
```bash
make start-nginx
```

### Option B: Caddy

**Pros:**
- ✅ Simpler configuration (Caddyfile)
- ✅ Automatic HTTPS with Let's Encrypt
- ✅ Modern defaults (HTTP/2, TLS 1.3)
- ✅ Easier to maintain

**Cons:**
- ❌ Newer, less widely adopted
- ❌ Slightly fewer online resources

**Best for:** Easier setup, automatic certificate management, modern deployments

**Start:**
```bash
make start-caddy
```

### Feature Comparison

| Feature | nginx | Caddy |
|---------|-------|-------|
| Client cert auth | ✅ | ✅ |
| Auto HTTPS | ❌ | ✅ |
| Configuration | Complex | Simple |
| Performance | Excellent | Excellent |
| CRL support | ✅ | ✅* |
| Documentation | Extensive | Good |

\* Varies by version

## 🔒 Security Considerations

### What This PoC Demonstrates

✅ **Secure practices:**
- TLS 1.2+ only
- Strong cipher suites
- Client certificate verification
- Certificate revocation support
- Permission-based access control
- Secure certificate generation

### For Production Use

Before deploying to production:

1. **Use proper SSL certificates**
   - Get real certificates from Let's Encrypt or commercial CA
   - Don't use self-signed server certificates

2. **Secure the CA private key**
   - Store offline in encrypted backup
   - Use strong password protection
   - Limit access to CA private key

3. **Enable Certificate Revocation**
   - Implement CRL or OCSP
   - Regular CRL updates
   - Automated revocation processes

4. **Regular security updates**
   - Keep Docker images updated
   - Update web server versions
   - Monitor security advisories

5. **Implement monitoring**
   - Log all certificate auth attempts
   - Monitor for unusual access patterns
   - Set up alerts for security events

6. **Backup and disaster recovery**
   - Regular backups of CA and certificates
   - Test restore procedures
   - Document recovery process

See [SERVER_SETUP.md](docs/SERVER_SETUP.md#production-deployment) for complete production checklist.

## 💡 Use Cases

### Ideal For

✅ **Private family websites**
- Photo sharing
- Document repository
- Family calendar
- Private communications

✅ **Small team collaboration**
- Internal wikis
- Project management
- Code repositories
- Internal tools

✅ **IoT device authentication**
- Smart home dashboards
- Device management panels
- Sensor data collection

✅ **Learning and experimentation**
- Understanding PKI
- Testing certificate-based auth
- Security research

### Not Ideal For

❌ **Public websites** - Certificates harder to distribute
❌ **Large scale deployments** - Certificate management complexity
❌ **Frequent user turnover** - Constant certificate reissuance
❌ **Non-technical users** - Requires technical setup

## 🛠️ Requirements

### System Requirements

- **OS:** Linux, macOS, or Windows with WSL2
- **RAM:** 2GB minimum
- **Disk:** 2GB free space
- **CPU:** Any modern processor

### Software Requirements

- **Docker:** 20.10 or later
- **Docker Compose:** 1.29 or later
- **OpenSSL:** 1.1.1 or later
- **Bash:** 4.0 or later
- **Make:** 3.8 or later (optional)

### Network Requirements

- **Ports:** 80 and 443 available
- **Firewall:** Allow inbound on ports 80, 443
- **DNS:** (Optional) Domain name for production

## 📝 Common Commands

```bash
# Certificate Management
make setup-ca                    # Create Certificate Authority
make create-server-cert          # Create server certificate
make generate-cert               # Create client certificate (interactive)
make generate-admin              # Quick admin certificate
make generate-family             # Quick family certificate
make list-certs                  # List all issued certificates
make revoke-cert                 # Revoke a certificate

# Server Management
make start-nginx                 # Start nginx version
make start-caddy                 # Start Caddy version
make stop-nginx                  # Stop nginx
make stop-caddy                  # Stop Caddy
make restart-nginx               # Restart nginx
make restart-caddy               # Restart Caddy
make logs-nginx                  # View nginx logs
make logs-caddy                  # View Caddy logs

# Testing
make test-nginx                  # Test nginx setup
make test-caddy                  # Test Caddy setup

# Cleanup
make clean                       # Stop containers, remove volumes
make clean-certs                 # Remove all certificates (DANGEROUS!)

# Information
make status                      # Show container status
make show-ca-cert                # Display CA certificate details
make verify-cert CERT=path.pem   # Verify certificate

# Help
make help                        # Show all available commands
```

## 🔧 Customization

### Adding Custom Permission Levels

1. Edit `backend/app.py` - Add new PermissionLevel enum value
2. Update permission logic in `determine_permission_level()`
3. Update hierarchy in `check_permission()`
4. Modify `scripts/02-generate-client-cert.sh` to support new level
5. Create protected routes for new permission level

See [PERMISSIONS_GUIDE.md](docs/PERMISSIONS_GUIDE.md) for detailed instructions.

### Changing Certificate Validity Period

Edit `scripts/02-generate-client-cert.sh`:

```bash
# Change from 365 days (1 year) to 730 days (2 years)
openssl ca -config "${CA_DIR}/signing.conf" \
    -extensions client_cert \
    -days 730 \         # ← Change this
    # ...
```

### Custom Certificate Fields

Modify certificate fields in `scripts/02-generate-client-cert.sh`:

```bash
# In the cert.conf section
[ req_distinguished_name ]
countryName                = US
stateOrProvinceName        = California
localityName               = YourCity        # ← Customize
0.organizationName         = YourFamilyName  # ← Customize
```

## 🐛 Troubleshooting

### Server won't start

```bash
# Check if ports are already in use
sudo netstat -tulpn | grep -E ':(80|443)'

# Check Docker logs
docker-compose -f docker-compose.nginx.yml logs

# Verify certificates exist
ls -la certs/ca/ certs/server/
```

### Certificate not working

```bash
# Verify certificate is valid
make verify-cert CERT=certs/clients/username/cert.pem

# Check certificate hasn't expired
openssl x509 -in cert.pem -noout -dates

# View certificate details
openssl x509 -in cert.pem -noout -text
```

### Can't access website

1. Check server is running: `make status`
2. Check firewall allows ports 80, 443
3. Try different browser
4. Check server logs: `make logs-nginx` or `make logs-caddy`

See documentation for more detailed troubleshooting.

## 🤝 Contributing

This is a proof-of-concept project for research and learning. Feel free to:

- Fork and modify for your needs
- Report issues or suggestions
- Share improvements or additional documentation
- Use as a learning resource

## 📄 License

This project is provided as-is for educational and research purposes. Use at your own risk in production environments.

## 🙏 Acknowledgments

Built using:
- [Flask](https://flask.palletsprojects.com/) - Python web framework
- [nginx](https://nginx.org/) - Web server
- [Caddy](https://caddyserver.com/) - Modern web server
- [OpenSSL](https://www.openssl.org/) - Certificate management
- [Docker](https://www.docker.com/) - Containerization

## 📚 Additional Resources

### Learn More

- [X.509 Certificates](https://en.wikipedia.org/wiki/X.509)
- [Public Key Infrastructure (PKI)](https://en.wikipedia.org/wiki/Public_key_infrastructure)
- [TLS/SSL Explained](https://www.cloudflare.com/learning/ssl/what-is-ssl/)
- [mTLS (Mutual TLS)](https://www.cloudflare.com/learning/access-management/what-is-mutual-tls/)

### Related Projects

- [Easy-RSA](https://github.com/OpenVPN/easy-rsa) - PKI management
- [CFSSL](https://github.com/cloudflare/cfssl) - CloudFlare's PKI toolkit
- [Let's Encrypt](https://letsencrypt.org/) - Free SSL/TLS certificates

---

## 🚦 Getting Help

1. **Check the documentation** in the `docs/` directory
2. **Run `make help`** for available commands
3. **Review troubleshooting sections** in relevant docs
4. **Check logs** with `make logs-nginx` or `make logs-caddy`
5. **Verify setup** with `make test-nginx` or `make test-caddy`

---

**Made with ❤️ for secure family communications**

*This project demonstrates client certificate authentication for educational purposes. Always follow security best practices in production deployments.*
