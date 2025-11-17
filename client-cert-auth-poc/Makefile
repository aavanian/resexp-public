# Makefile for Client Certificate Authentication PoC
#
# This Makefile provides convenient commands for managing the PoC project.
# Run 'make help' to see all available commands.

.PHONY: help setup-ca create-server-cert generate-cert list-certs revoke-cert \
        start-nginx start-caddy stop-nginx stop-caddy logs-nginx logs-caddy \
        clean clean-certs clean-docker test-nginx test-caddy

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

##@ General

help: ## Display this help message
	@echo "$(GREEN)Client Certificate Authentication PoC - Available Commands$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make $(BLUE)<target>$(NC)\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(BLUE)%-20s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Certificate Authority

setup-ca: ## Create the Certificate Authority (first step)
	@echo "$(GREEN)Creating Certificate Authority...$(NC)"
	@./scripts/01-create-ca.sh
	@echo "$(GREEN)✓ Certificate Authority created$(NC)"

create-server-cert: ## Generate server certificate for HTTPS
	@echo "$(GREEN)Creating server certificate...$(NC)"
	@./scripts/04-generate-server-cert.sh localhost
	@echo "$(GREEN)✓ Server certificate created$(NC)"

##@ Client Certificates

generate-cert: ## Generate a client certificate (interactive)
	@echo "$(GREEN)Generating client certificate...$(NC)"
	@./scripts/02-generate-client-cert.sh

generate-admin: ## Generate an admin certificate for demo
	@./scripts/02-generate-client-cert.sh "Admin User" "admin@family.example.com" admin

generate-family: ## Generate a family member certificate for demo
	@./scripts/02-generate-client-cert.sh "Family Member" "member@family.example.com" family

generate-guest: ## Generate a guest certificate for demo
	@./scripts/02-generate-client-cert.sh "Guest User" "guest@family.example.com" guest

list-certs: ## List all issued certificates
	@./scripts/05-list-certificates.sh

revoke-cert: ## Revoke a certificate (interactive)
	@./scripts/03-revoke-certificate.sh

##@ Docker - nginx (Option A)

start-nginx: ## Start the application with nginx
	@echo "$(GREEN)Starting application with nginx...$(NC)"
	@docker-compose -f docker-compose.nginx.yml up -d
	@echo ""
	@echo "$(GREEN)✓ Application started!$(NC)"
	@echo "Access it at: $(BLUE)https://localhost$(NC)"
	@echo "View logs: $(BLUE)make logs-nginx$(NC)"

stop-nginx: ## Stop the nginx application
	@echo "$(YELLOW)Stopping nginx application...$(NC)"
	@docker-compose -f docker-compose.nginx.yml down
	@echo "$(GREEN)✓ Stopped$(NC)"

logs-nginx: ## View nginx application logs
	@docker-compose -f docker-compose.nginx.yml logs -f

restart-nginx: stop-nginx start-nginx ## Restart the nginx application

build-nginx: ## Build/rebuild nginx containers
	@docker-compose -f docker-compose.nginx.yml build

##@ Docker - Caddy (Option B)

start-caddy: ## Start the application with Caddy
	@echo "$(GREEN)Starting application with Caddy...$(NC)"
	@docker-compose -f docker-compose.caddy.yml up -d
	@echo ""
	@echo "$(GREEN)✓ Application started!$(NC)"
	@echo "Access it at: $(BLUE)https://localhost$(NC)"
	@echo "View logs: $(BLUE)make logs-caddy$(NC)"

stop-caddy: ## Stop the Caddy application
	@echo "$(YELLOW)Stopping Caddy application...$(NC)"
	@docker-compose -f docker-compose.caddy.yml down
	@echo "$(GREEN)✓ Stopped$(NC)"

logs-caddy: ## View Caddy application logs
	@docker-compose -f docker-compose.caddy.yml logs -f

restart-caddy: stop-caddy start-caddy ## Restart the Caddy application

build-caddy: ## Build/rebuild Caddy containers
	@docker-compose -f docker-compose.caddy.yml build

##@ Testing

test-nginx: ## Test nginx setup (must be running)
	@echo "$(GREEN)Testing nginx setup...$(NC)"
	@echo ""
	@echo "$(BLUE)1. Testing HTTP to HTTPS redirect:$(NC)"
	@curl -I http://localhost 2>/dev/null | grep -i location || echo "$(RED)HTTP redirect test failed$(NC)"
	@echo ""
	@echo "$(BLUE)2. Testing HTTPS health endpoint:$(NC)"
	@curl -k https://localhost/health 2>/dev/null || echo "$(RED)HTTPS test failed$(NC)"
	@echo ""
	@echo "$(BLUE)3. Testing API endpoint:$(NC)"
	@curl -k https://localhost/api/cert-info 2>/dev/null | head -5 || echo "$(RED)API test failed$(NC)"
	@echo ""
	@echo "$(YELLOW)To test with client certificate:$(NC)"
	@echo "curl -k --cert certs/clients/[name]/cert.pem --key certs/clients/[name]/key.pem https://localhost/"

test-caddy: ## Test Caddy setup (must be running)
	@echo "$(GREEN)Testing Caddy setup...$(NC)"
	@echo ""
	@echo "$(BLUE)1. Testing HTTP to HTTPS redirect:$(NC)"
	@curl -I http://localhost 2>/dev/null | grep -i location || echo "$(RED)HTTP redirect test failed$(NC)"
	@echo ""
	@echo "$(BLUE)2. Testing HTTPS health endpoint:$(NC)"
	@curl -k https://localhost/health 2>/dev/null || echo "$(RED)HTTPS test failed$(NC)"
	@echo ""
	@echo "$(BLUE)3. Testing API endpoint:$(NC)"
	@curl -k https://localhost/api/cert-info 2>/dev/null | head -5 || echo "$(RED)API test failed$(NC)"
	@echo ""
	@echo "$(YELLOW)To test with client certificate:$(NC)"
	@echo "curl -k --cert certs/clients/[name]/cert.pem --key certs/clients/[name]/key.pem https://localhost/"

##@ Development

demo-setup: setup-ca create-server-cert generate-admin generate-family generate-guest ## Complete demo setup (CA + server cert + 3 demo client certs)
	@echo ""
	@echo "$(GREEN)✓ Demo setup complete!$(NC)"
	@echo ""
	@echo "$(YELLOW)Demo certificates created:$(NC)"
	@echo "  1. Admin User (admin permissions)"
	@echo "  2. Family Member (family permissions)"
	@echo "  3. Guest User (guest permissions)"
	@echo ""
	@echo "$(YELLOW)Next steps:$(NC)"
	@echo "  1. Start the application: $(BLUE)make start-nginx$(NC) or $(BLUE)make start-caddy$(NC)"
	@echo "  2. Install a client certificate (see docs/CLIENT_INSTALLATION.md)"
	@echo "  3. Visit $(BLUE)https://localhost$(NC)"
	@echo ""
	@echo "$(YELLOW)Client certificate locations:$(NC)"
	@find certs/clients -name "*.p12" -exec echo "  - {}" \;

shell-backend: ## Open shell in backend container (nginx)
	@docker-compose -f docker-compose.nginx.yml exec backend sh

shell-nginx: ## Open shell in nginx container
	@docker-compose -f docker-compose.nginx.yml exec nginx sh

shell-caddy: ## Open shell in Caddy container
	@docker-compose -f docker-compose.caddy.yml exec caddy sh

##@ Cleanup

clean: clean-docker ## Clean everything (stops containers, removes volumes)
	@echo "$(YELLOW)Cleaning up...$(NC)"
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

clean-certs: ## Remove all certificates (DANGEROUS - requires confirmation)
	@echo "$(RED)WARNING: This will delete all certificates including the CA!$(NC)"
	@echo "This action cannot be undone."
	@read -p "Are you sure? Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		rm -rf certs/; \
		echo "$(GREEN)✓ Certificates deleted$(NC)"; \
	else \
		echo "$(YELLOW)Cancelled$(NC)"; \
	fi

clean-docker: ## Stop and remove all containers and volumes
	@echo "$(YELLOW)Stopping and removing containers...$(NC)"
	@docker-compose -f docker-compose.nginx.yml down -v 2>/dev/null || true
	@docker-compose -f docker-compose.caddy.yml down -v 2>/dev/null || true
	@echo "$(GREEN)✓ Docker cleanup complete$(NC)"

clean-logs: ## Remove log files
	@rm -rf logs/*.log
	@echo "$(GREEN)✓ Logs cleaned$(NC)"

##@ Monitoring

status: ## Show status of running containers
	@echo "$(GREEN)Container Status:$(NC)"
	@echo ""
	@echo "$(YELLOW)nginx:$(NC)"
	@docker-compose -f docker-compose.nginx.yml ps 2>/dev/null || echo "  Not running"
	@echo ""
	@echo "$(YELLOW)Caddy:$(NC)"
	@docker-compose -f docker-compose.caddy.yml ps 2>/dev/null || echo "  Not running"

##@ Information

show-ca-cert: ## Display CA certificate details
	@if [ -f certs/ca/ca-cert.pem ]; then \
		openssl x509 -in certs/ca/ca-cert.pem -noout -text; \
	else \
		echo "$(RED)CA certificate not found. Run 'make setup-ca' first.$(NC)"; \
	fi

show-server-cert: ## Display server certificate details
	@if [ -f certs/server/server-cert.pem ]; then \
		openssl x509 -in certs/server/server-cert.pem -noout -text; \
	else \
		echo "$(RED)Server certificate not found. Run 'make create-server-cert' first.$(NC)"; \
	fi

verify-cert: ## Verify a client certificate against CA (usage: make verify-cert CERT=path/to/cert.pem)
	@if [ -z "$(CERT)" ]; then \
		echo "$(RED)Usage: make verify-cert CERT=path/to/cert.pem$(NC)"; \
		exit 1; \
	fi
	@openssl verify -CAfile certs/ca/ca-cert.pem $(CERT)
