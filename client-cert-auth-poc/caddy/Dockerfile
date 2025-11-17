FROM caddy:2.7-alpine

# Copy Caddyfile
COPY Caddyfile /etc/caddy/Caddyfile

# Create directories for certificates and logs
RUN mkdir -p /etc/caddy/certs /var/log/caddy

# Expose ports
EXPOSE 80 443

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/health || exit 1

# Caddy runs as non-root by default
# Start caddy with the Caddyfile
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
