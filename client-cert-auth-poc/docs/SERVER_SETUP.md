# Server Setup Guide

This guide explains how to set up and run the client certificate authentication server using either nginx (Option A) or Caddy (Option B).

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Option A: nginx Setup](#option-a-nginx-setup)
- [Option B: Caddy Setup](#option-b-caddy-setup)
- [Configuration Details](#configuration-details)
- [Production Deployment](#production-deployment)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- Docker and Docker Compose installed
- Basic command line knowledge
- OpenSSL (for certificate generation)
- At least 2GB of free disk space

## Quick Start

The fastest way to get started is using the Makefile:

```bash
# 1. Create CA, server cert, and demo client certificates
make demo-setup

# 2. Start the server (choose one)
make start-nginx   # For Option A (nginx)
# OR
make start-caddy   # For Option B (Caddy)

# 3. Visit https://localhost in your browser
# Note: You'll see a certificate warning because we're using self-signed certs
```

## Option A: nginx Setup

### Architecture

```
Client Browser → nginx (SSL/TLS + Client Cert Verification) → Flask Backend
```

nginx handles:
- SSL/TLS termination
- Client certificate verification
- Header injection with certificate metadata
- Static file serving (if needed)

### Starting nginx

```bash
# Using Makefile
make start-nginx

# Or using Docker Compose directly
docker-compose -f docker-compose.nginx.yml up -d
```

### nginx Configuration

The nginx configuration is located at `nginx/nginx.conf`. Key settings:

```nginx
# Client certificate verification
ssl_client_certificate /etc/nginx/certs/ca-cert.pem;
ssl_verify_client optional;  # Change to 'on' to require certificates
ssl_verify_depth 2;

# Pass certificate info to backend
proxy_set_header X-SSL-Client-DN $ssl_client_s_dn;
proxy_set_header X-SSL-Client-CN $ssl_client_s_dn_cn;
proxy_set_header X-SSL-Client-OU $ssl_client_s_dn_ou;
# ... more headers ...
```

### Customizing nginx

To modify nginx behavior, edit `nginx/nginx.conf`:

**Require certificates for all pages:**
```nginx
ssl_verify_client on;  # Change from 'optional' to 'on'
```

**Require certificates only for specific paths:**
```nginx
location ~ ^/(admin|family) {
    if ($ssl_client_verify != SUCCESS) {
        return 403 "Client certificate required";
    }
    proxy_pass http://backend;
    # ... headers ...
}
```

**Enable Certificate Revocation List (CRL):**
```nginx
ssl_crl /etc/nginx/certs/crl.pem;
```

After changes, restart:
```bash
make restart-nginx
```

## Option B: Caddy Setup

### Architecture

```
Client Browser → Caddy (SSL/TLS + Client Cert Verification) → Flask Backend
```

Caddy handles:
- Automatic HTTPS (with Let's Encrypt in production)
- Client certificate verification
- Header injection with certificate metadata
- Simpler configuration syntax

### Starting Caddy

```bash
# Using Makefile
make start-caddy

# Or using Docker Compose directly
docker-compose -f docker-compose.caddy.yml up -d
```

### Caddy Configuration

The Caddy configuration is located at `caddy/Caddyfile`. Key settings:

```caddyfile
tls /etc/caddy/certs/server-cert.pem /etc/caddy/certs/server-key.pem {
    client_auth {
        mode request  # request, require, or verify_if_given
        trusted_ca_cert_file /etc/caddy/certs/ca-cert.pem
    }
    protocols tls1.2 tls1.3
}
```

### Customizing Caddy

To modify Caddy behavior, edit `caddy/Caddyfile`:

**Require certificates for all pages:**
```caddyfile
client_auth {
    mode require  # Change from 'request' to 'require'
    trusted_ca_cert_file /etc/caddy/certs/ca-cert.pem
}
```

**Require certificates only for specific paths:**
```caddyfile
# See commented section in Caddyfile for full example
@authenticated {
    path /admin* /family*
}

handle @authenticated {
    @no_cert {
        not {
            expression {http.request.tls.client.verified} == "1"
        }
    }
    handle @no_cert {
        respond "Client certificate required" 403
    }
    reverse_proxy backend:5000 { ... }
}
```

After changes, restart:
```bash
make restart-caddy
```

## Configuration Details

### Environment Variables

Backend configuration (`.env` file - not committed to git):

```bash
FLASK_ENV=production
FLASK_DEBUG=0
HOST=0.0.0.0
PORT=5000
```

### Certificate Locations

The Docker containers expect certificates at these locations:

**For nginx:**
- CA cert: `/etc/nginx/certs/ca-cert.pem`
- Server cert: `/etc/nginx/certs/server-cert.pem`
- Server key: `/etc/nginx/certs/server-key.pem`
- CRL (optional): `/etc/nginx/certs/crl.pem`

**For Caddy:**
- CA cert: `/etc/caddy/certs/ca-cert.pem`
- Server cert: `/etc/caddy/certs/server-cert.pem`
- Server key: `/etc/caddy/certs/server-key.pem`
- CRL (optional): `/etc/caddy/certs/crl.pem`

These are mounted from the host `certs/` directory via Docker volumes.

### Port Configuration

Default ports:
- `80` - HTTP (redirects to HTTPS)
- `443` - HTTPS with client certificate authentication

To change ports, edit the `docker-compose.*.yml` file:

```yaml
ports:
  - "8080:80"    # Use port 8080 for HTTP
  - "8443:443"   # Use port 8443 for HTTPS
```

## Production Deployment

### Security Checklist

Before deploying to production:

- [ ] Use a real domain name (not localhost)
- [ ] Use proper SSL certificates (Let's Encrypt or commercial CA)
- [ ] Keep CA private key offline and highly secure
- [ ] Set `ssl_verify_client on` (nginx) or `mode require` (Caddy) if all pages need auth
- [ ] Enable Certificate Revocation List (CRL) or OCSP
- [ ] Set `FLASK_DEBUG=0` in environment
- [ ] Use strong passwords for PKCS#12 files
- [ ] Implement rate limiting
- [ ] Set up proper logging and monitoring
- [ ] Regular certificate renewal process
- [ ] Backup strategy for CA and certificates
- [ ] Firewall rules (only ports 80, 443 open)
- [ ] Keep Docker images updated

### TLS Best Practices

Current configuration already includes:

✅ TLS 1.2 and 1.3 only (no SSL, TLS 1.0, or TLS 1.1)
✅ Strong cipher suites
✅ Perfect Forward Secrecy (PFS)
✅ HTTP to HTTPS redirect
✅ Security headers

### Domain Configuration

For production with a real domain:

**nginx (`nginx/nginx.conf`):**
```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com www.your-domain.com;
    # ...
}
```

**Caddy (`caddy/Caddyfile`):**
```caddyfile
your-domain.com {
    # Caddy will automatically get Let's Encrypt certificate
    tls {
        client_auth {
            mode request
            trusted_ca_cert_file /etc/caddy/certs/ca-cert.pem
        }
    }
    # ...
}
```

### Using Let's Encrypt with Caddy

Caddy automatically obtains Let's Encrypt certificates. For production:

1. Ensure port 80 and 443 are accessible from the internet
2. Use your real domain in the Caddyfile
3. Remove `auto_https off` from the global options
4. Remove manual `tls` directive or keep only `client_auth` part:

```caddyfile
{
    # Remove: auto_https off
}

your-domain.com {
    tls {
        # Caddy handles server cert automatically
        client_auth {
            mode request
            trusted_ca_cert_file /etc/caddy/certs/ca-cert.pem
        }
    }
    # ...
}
```

### Reverse Proxy Behind Another Load Balancer

If running behind AWS ELB, Cloudflare, or another load balancer:

**nginx:**
```nginx
# Trust proxy headers
set_real_ip_from 10.0.0.0/8;  # Your load balancer IP range
real_ip_header X-Forwarded-For;
real_ip_recursive on;
```

**Caddy:**
```caddyfile
# Caddy handles this automatically with trusted_proxies
servers {
    trusted_proxies static 10.0.0.0/8
}
```

## Monitoring and Logging

### View Logs

```bash
# nginx
make logs-nginx
# or
docker-compose -f docker-compose.nginx.yml logs -f

# Caddy
make logs-caddy
# or
docker-compose -f docker-compose.caddy.yml logs -f
```

### Log Locations

- nginx: Container stdout/stderr (visible via `docker logs`)
- Caddy: `logs/caddy/access.log` (JSON format)
- Backend: Container stdout/stderr

### Important Log Events

Look for these in logs:

- Certificate verification failures
- Invalid certificates presented
- Expired certificates
- Revoked certificates (if CRL enabled)
- Backend errors
- Unusual access patterns

## Testing

### Basic Health Check

```bash
# Test HTTP redirect
curl -I http://localhost

# Test HTTPS (without cert)
curl -k https://localhost/health

# Test with client certificate
curl -k --cert certs/clients/admin-user/cert.pem \
     --key certs/clients/admin-user/key.pem \
     https://localhost/

# Test with PKCS#12
curl -k --cert-type P12 \
     --cert certs/clients/admin-user/admin-user.p12:PASSWORD \
     https://localhost/
```

### Automated Tests

```bash
make test-nginx  # Test nginx setup
make test-caddy  # Test Caddy setup
```

## Troubleshooting

### Container Won't Start

```bash
# Check container logs
docker-compose -f docker-compose.nginx.yml logs

# Check if ports are already in use
sudo netstat -tulpn | grep -E ':(80|443)'

# Verify certificates exist
ls -la certs/ca/
ls -la certs/server/
```

### Certificate Verification Failures

```bash
# Verify client cert is signed by CA
make verify-cert CERT=certs/clients/username/cert.pem

# Check CA certificate
make show-ca-cert

# View client certificate details
openssl x509 -in certs/clients/username/cert.pem -noout -text
```

### Cannot Access Site

1. Check containers are running:
   ```bash
   make status
   ```

2. Check certificate trust:
   - Browser may not trust self-signed server certificate
   - Add server certificate to browser's trusted certificates
   - Or use a proper CA in production

3. Check firewall:
   ```bash
   # Linux
   sudo ufw status
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   ```

### Client Certificate Not Working

1. Verify certificate is installed in browser
2. Check certificate hasn't expired
3. Check browser is sending certificate (check nginx/Caddy logs)
4. Verify certificate is signed by correct CA
5. Clear browser certificate cache and re-import

### Backend Not Receiving Certificate Headers

1. Check proxy configuration passes headers
2. Verify backend is looking for correct header names:
   - nginx uses: `X-SSL-Client-*`
   - Caddy uses: `X-Client-Cert-*`
3. Check backend logs for received headers

### Performance Issues

1. Enable SSL session caching (already enabled in config)
2. Consider using HTTP/2 (enabled by default)
3. Monitor container resources:
   ```bash
   docker stats
   ```

## Updating Certificates

### Renew Client Certificate

```bash
# Generate new certificate with same name (will prompt to overwrite)
./scripts/02-generate-client-cert.sh "User Name" "email@example.com" permission-level
```

### Update CRL After Revocation

```bash
# Revoke certificate
make revoke-cert

# Restart server to reload CRL
make restart-nginx  # or restart-caddy
```

### Update Server Certificate

```bash
# Generate new server cert
make create-server-cert

# Restart server
make restart-nginx  # or restart-caddy
```

## Backup and Disaster Recovery

### Critical Files to Backup

**Must backup (NEVER lose these):**
- `certs/ca/ca-key.pem` - CA private key (MOST IMPORTANT)
- `certs/ca/ca-cert.pem` - CA certificate
- `certs/ca/index.txt` - Certificate database
- `certs/ca/serial.txt` - Serial number tracker

**Should backup:**
- `certs/server/` - Server certificates
- `certs/clients/` - Client certificates (users should keep their own)

**Backup command:**
```bash
tar -czf cert-backup-$(date +%Y%m%d).tar.gz \
    certs/ca/ca-key.pem \
    certs/ca/ca-cert.pem \
    certs/ca/index.txt \
    certs/ca/serial.txt
```

**Store backups:**
- Encrypted external drive
- Encrypted cloud storage with 2FA
- Physical safe
- NOT on the same server

### Disaster Recovery

If CA private key is lost:
1. **YOU CANNOT issue new certificates**
2. Must create new CA
3. Must reissue all client certificates
4. Must redistribute to all users

If CA private key is compromised:
1. Revoke all certificates immediately
2. Create new CA
3. Reissue all certificates
4. Investigate security breach
5. Notify all users

## Additional Resources

- [CERTIFICATE_GENERATION.md](CERTIFICATE_GENERATION.md) - How to create and manage certificates
- [CLIENT_INSTALLATION.md](CLIENT_INSTALLATION.md) - Installing certificates on various platforms
- [USER_BEST_PRACTICES.md](USER_BEST_PRACTICES.md) - Security guidelines for users
- [PERMISSIONS_GUIDE.md](PERMISSIONS_GUIDE.md) - How the permission system works
- nginx documentation: https://nginx.org/en/docs/
- Caddy documentation: https://caddyserver.com/docs/
