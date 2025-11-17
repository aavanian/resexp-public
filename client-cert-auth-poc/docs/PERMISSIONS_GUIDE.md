# Permissions Guide

This guide explains how the permission system works in the client certificate authentication setup and how to customize it for your needs.

## Table of Contents

- [Overview](#overview)
- [Permission Levels](#permission-levels)
- [How Permissions Work](#how-permissions-work)
- [Customizing Permissions](#customizing-permissions)
- [Advanced Permission Patterns](#advanced-permission-patterns)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

---

## Overview

### What Are Permission Levels?

Permission levels determine what pages and features a user can access on your family website. They are **embedded in the client certificate** and verified by the backend application.

**Key Concepts:**

- **Embedded in certificate** - Set when certificate is created
- **Cannot be changed** - Must issue new certificate to change permissions
- **Hierarchical** - Higher levels include lower level permissions
- **Application enforced** - Backend code checks permissions

### Why Use Certificate-Based Permissions?

**Traditional approaches:**
```
Website: Username + Password → Check database → Grant access
Problem: Must manage user database, remember passwords, risk of password leaks
```

**Certificate-based approach:**
```
Website: Present certificate → Verify signature → Read permission from cert → Grant access
Benefit: No password database, no passwords to leak, automatic authentication
```

---

## Permission Levels

### Default Permission Hierarchy

This PoC includes three permission levels:

| Level | Organizational Unit (OU) | Access | Typical Users |
|-------|-------------------------|---------|---------------|
| **Admin** | `Admin` | Full access to all pages | Site administrators, parents |
| **Family Member** | `Family` | Access to family pages | Family members, close relatives |
| **Guest** | `Guest` | Public pages only | Temporary guests, extended family |

### Permission Inheritance

Permissions follow a hierarchy:

```
Admin (Level 3)
  ├─ Can access: Public, Family, Admin pages
  │
  └─ Family Member (Level 2)
      ├─ Can access: Public, Family pages
      │
      └─ Guest (Level 1)
          └─ Can access: Public pages only
```

**Example:**
- Admin can view admin page ✅
- Admin can view family page ✅ (has higher permission)
- Family member can view family page ✅
- Family member cannot view admin page ❌ (needs higher permission)

### Page Access Matrix

| Page Route | Public | Guest | Family | Admin |
|------------|--------|-------|--------|-------|
| `/` (Home) | ✅ | ✅ | ✅ | ✅ |
| `/api/cert-info` | ✅ | ✅ | ✅ | ✅ |
| `/family` | ❌ | ❌ | ✅ | ✅ |
| `/admin` | ❌ | ❌ | ❌ | ✅ |

---

## How Permissions Work

### 1. Certificate Creation

When you create a certificate, the permission level is embedded in the **Organizational Unit (OU)** field:

```bash
# Create admin certificate
./scripts/02-generate-client-cert.sh "John Doe" "john@example.com" admin

# Certificate will contain: OU=Admin
```

**Certificate structure:**
```
Subject:
  C  = US
  ST = California
  L  = San Francisco
  O  = Family
  OU = Admin          ← Permission level stored here
  CN = John Doe
  emailAddress = john@example.com
```

### 2. Web Server Receives Certificate

When user visits website, web server (nginx or Caddy) extracts certificate information and passes it to the backend via HTTP headers:

**nginx headers:**
```
X-SSL-Client-DN: /C=US/ST=California/O=Family/OU=Admin/CN=John Doe/emailAddress=john@example.com
X-SSL-Client-CN: John Doe
X-SSL-Client-OU: Admin
X-SSL-Client-Email: john@example.com
X-SSL-Client-Verify: SUCCESS
```

**Caddy headers:**
```
X-Client-Cert-Subject: CN=John Doe,OU=Admin,O=Family,ST=California,C=US
X-Client-Cert-CN: John Doe
X-Client-Cert-OU: Admin
X-Client-Cert-Email: john@example.com
X-Client-Cert-Verified: 1
```

### 3. Backend Determines Permission

The Flask backend reads the `OU` field from headers:

**Code flow (`backend/app.py`):**

```python
def determine_permission_level(cert_info: dict) -> PermissionLevel:
    # Check certificate was verified
    if cert_info["verified"] not in ["SUCCESS", "success", "1"]:
        return PermissionLevel.GUEST

    # Read OU field
    ou = cert_info.get("ou", "").lower()

    # Map OU to permission level
    if "admin" in ou:
        return PermissionLevel.ADMIN
    elif "family" in ou:
        return PermissionLevel.FAMILY_MEMBER
    else:
        return PermissionLevel.GUEST
```

### 4. Backend Enforces Access Control

When user tries to access a page:

```python
@app.route("/family")
def family_page():
    cert_info = get_certificate_info()

    # Check if user has required permission
    if not check_permission(PermissionLevel.FAMILY_MEMBER, cert_info):
        return render_template("forbidden.html"), 403

    return render_template("family.html")
```

**Permission check logic:**

```python
def check_permission(required_level, cert_info):
    current_level = determine_permission_level(cert_info)

    hierarchy = {
        PermissionLevel.ADMIN: 3,
        PermissionLevel.FAMILY_MEMBER: 2,
        PermissionLevel.GUEST: 1,
    }

    return hierarchy[current_level] >= hierarchy[required_level]
```

---

## Customizing Permissions

### Adding New Permission Levels

**Scenario:** You want to add a "Moderator" level between Family and Admin.

**Step 1: Update Backend Enum**

Edit `backend/app.py`:

```python
class PermissionLevel(Enum):
    """Permission levels based on certificate attributes."""
    GUEST = "guest"
    FAMILY_MEMBER = "family-member"
    MODERATOR = "moderator"        # ← Add new level
    ADMIN = "admin"
```

**Step 2: Update Permission Logic**

```python
def determine_permission_level(cert_info: dict) -> PermissionLevel:
    ou = cert_info.get("ou", "").lower()

    if "admin" in ou:
        return PermissionLevel.ADMIN
    elif "moderator" in ou:        # ← Add moderator check
        return PermissionLevel.MODERATOR
    elif "family" in ou:
        return PermissionLevel.FAMILY_MEMBER
    else:
        return PermissionLevel.GUEST
```

**Step 3: Update Hierarchy**

```python
def check_permission(required_level, cert_info):
    hierarchy = {
        PermissionLevel.ADMIN: 4,           # ← Update admin to 4
        PermissionLevel.MODERATOR: 3,       # ← Add moderator at 3
        PermissionLevel.FAMILY_MEMBER: 2,
        PermissionLevel.GUEST: 1,
    }
    # ... rest of function
```

**Step 4: Create Certificate Generation Script**

Edit `scripts/02-generate-client-cert.sh` to accept "moderator":

```bash
case "$PERMISSION" in
    admin|family|moderator|guest)   # ← Add moderator here
        ;;
    *)
        echo "Invalid permission level"
        exit 1
        ;;
esac

# Add OU mapping
case "$PERMISSION" in
    admin)
        OU="Admin"
        ;;
    moderator)
        OU="Moderator"              # ← Add moderator mapping
        ;;
    family)
        OU="Family"
        ;;
    guest)
        OU="Guest"
        ;;
esac
```

**Step 5: Add Protected Page**

Create a moderator-only page:

```python
@app.route("/moderate")
def moderate_page():
    cert_info = get_certificate_info()

    if not check_permission(PermissionLevel.MODERATOR, cert_info):
        return render_template("forbidden.html"), 403

    return render_template("moderate.html")
```

**Step 6: Generate Certificates**

```bash
# Create moderator certificate
./scripts/02-generate-client-cert.sh "Jane Moderator" "jane@example.com" moderator
```

### Using Different Certificate Fields

Instead of OU, you can use other certificate fields:

**Option 1: Common Name (CN) Pattern**

```python
def determine_permission_level(cert_info: dict) -> PermissionLevel:
    cn = cert_info.get("cn", "").lower()

    # Use naming convention: "Admin: John Doe"
    if cn.startswith("admin:"):
        return PermissionLevel.ADMIN
    elif cn.startswith("family:"):
        return PermissionLevel.FAMILY_MEMBER
    else:
        return PermissionLevel.GUEST
```

**Option 2: Email Domain**

```python
def determine_permission_level(cert_info: dict) -> PermissionLevel:
    email = cert_info.get("email", "").lower()

    # Admins have @admin.family.example.com
    if email.endswith("@admin.family.example.com"):
        return PermissionLevel.ADMIN
    # Family members have @family.example.com
    elif email.endswith("@family.example.com"):
        return PermissionLevel.FAMILY_MEMBER
    else:
        return PermissionLevel.GUEST
```

**Option 3: Certificate Serial Number Range**

```python
def determine_permission_level(cert_info: dict) -> PermissionLevel:
    serial = cert_info.get("serial", "")

    try:
        serial_num = int(serial, 16)  # Convert hex to int

        # Serial 1000-1999: Admin
        if 1000 <= serial_num < 2000:
            return PermissionLevel.ADMIN
        # Serial 2000-2999: Family
        elif 2000 <= serial_num < 3000:
            return PermissionLevel.FAMILY_MEMBER
        else:
            return PermissionLevel.GUEST
    except:
        return PermissionLevel.GUEST
```

### Custom Permission Logic

**Scenario:** Different permissions for different pages

```python
class Permission:
    """Fine-grained permissions."""
    VIEW_PHOTOS = "view_photos"
    UPLOAD_PHOTOS = "upload_photos"
    VIEW_DOCUMENTS = "view_documents"
    EDIT_DOCUMENTS = "edit_documents"
    MANAGE_USERS = "manage_users"

# Map OU to multiple permissions
PERMISSION_MAP = {
    "Admin": [
        Permission.VIEW_PHOTOS,
        Permission.UPLOAD_PHOTOS,
        Permission.VIEW_DOCUMENTS,
        Permission.EDIT_DOCUMENTS,
        Permission.MANAGE_USERS,
    ],
    "Family": [
        Permission.VIEW_PHOTOS,
        Permission.UPLOAD_PHOTOS,
        Permission.VIEW_DOCUMENTS,
    ],
    "Guest": [
        Permission.VIEW_PHOTOS,
    ],
}

def has_permission(cert_info: dict, required_permission: str) -> bool:
    """Check if user has specific permission."""
    ou = cert_info.get("ou", "Guest")
    user_permissions = PERMISSION_MAP.get(ou, [])
    return required_permission in user_permissions

# Use in routes
@app.route("/photos/upload", methods=["POST"])
def upload_photo():
    cert_info = get_certificate_info()

    if not has_permission(cert_info, Permission.UPLOAD_PHOTOS):
        return jsonify({"error": "Permission denied"}), 403

    # Handle photo upload...
```

---

## Advanced Permission Patterns

### Time-Based Permissions

Allow access only during certain times:

```python
from datetime import datetime, time

def check_time_based_permission(cert_info: dict, required_level: PermissionLevel) -> bool:
    """Check permission with time restrictions."""

    # Basic permission check
    if not check_permission(required_level, cert_info):
        return False

    # Guests only allowed during business hours (9 AM - 5 PM)
    current_level = determine_permission_level(cert_info)
    if current_level == PermissionLevel.GUEST:
        now = datetime.now().time()
        business_start = time(9, 0)
        business_end = time(17, 0)

        if not (business_start <= now <= business_end):
            return False

    return True
```

### IP-Based Restrictions

Combine certificate auth with IP allowlists:

```python
ALLOWED_ADMIN_IPS = [
    "192.168.1.0/24",    # Home network
    "10.0.0.0/8",        # VPN network
]

def is_ip_allowed(ip_address: str, allowed_networks: list) -> bool:
    """Check if IP is in allowed networks."""
    from ipaddress import ip_address as parse_ip, ip_network

    ip = parse_ip(ip_address)
    for network in allowed_networks:
        if ip in ip_network(network):
            return True
    return False

@app.route("/admin")
def admin_page():
    cert_info = get_certificate_info()

    # Check certificate permission
    if not check_permission(PermissionLevel.ADMIN, cert_info):
        return "Certificate permission denied", 403

    # Check IP address
    client_ip = request.headers.get("X-Real-IP", request.remote_addr)
    if not is_ip_allowed(client_ip, ALLOWED_ADMIN_IPS):
        return "IP address not allowed", 403

    return render_template("admin.html")
```

### Certificate Expiry-Based Permissions

Warn users or restrict access near expiry:

```python
from datetime import datetime, timedelta

def check_expiry_warning(cert_info: dict) -> dict:
    """Check if certificate is expiring soon."""
    not_after = cert_info.get("not_after")

    try:
        expiry_date = datetime.strptime(not_after, "%b %d %H:%M:%S %Y %Z")
        days_remaining = (expiry_date - datetime.now()).days

        if days_remaining < 0:
            return {"expired": True, "days": days_remaining}
        elif days_remaining < 7:
            return {"expiring_soon": True, "days": days_remaining, "severity": "critical"}
        elif days_remaining < 30:
            return {"expiring_soon": True, "days": days_remaining, "severity": "warning"}
        else:
            return {"ok": True, "days": days_remaining}
    except:
        return {"ok": True, "days": None}

@app.route("/admin")
def admin_page():
    cert_info = get_certificate_info()

    # Check permission
    if not check_permission(PermissionLevel.ADMIN, cert_info):
        return "Permission denied", 403

    # Check expiry
    expiry_status = check_expiry_warning(cert_info)

    if expiry_status.get("expired"):
        return "Certificate expired. Please renew.", 403

    if expiry_status.get("expiring_soon") and expiry_status["severity"] == "critical":
        # Allow access but show urgent warning
        flash(f"Certificate expires in {expiry_status['days']} days! Renew immediately.", "danger")

    return render_template("admin.html")
```

### Multi-Factor Requirements

Require certificate + additional factor for sensitive operations:

```python
from functools import wraps
from flask import session, redirect, url_for

def require_certificate_and_totp(required_level):
    """Decorator requiring certificate and TOTP."""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            cert_info = get_certificate_info()

            # Check certificate permission
            if not check_permission(required_level, cert_info):
                return "Certificate permission denied", 403

            # Check if TOTP verified in this session
            if not session.get("totp_verified"):
                return redirect(url_for("verify_totp"))

            return f(*args, **kwargs)
        return decorated_function
    return decorator

@app.route("/admin/critical-action")
@require_certificate_and_totp(PermissionLevel.ADMIN)
def critical_action():
    # Highly sensitive admin action
    return "Critical action performed"
```

---

## Examples

### Example 1: Photo Gallery with Granular Permissions

```python
# Define specific permissions
class PhotoPermission:
    VIEW_PUBLIC = "view_public_photos"
    VIEW_FAMILY = "view_family_photos"
    VIEW_PRIVATE = "view_private_photos"
    UPLOAD = "upload_photos"
    DELETE = "delete_photos"

# Map certificate OU to photo permissions
PHOTO_PERMISSIONS = {
    "Admin": [
        PhotoPermission.VIEW_PUBLIC,
        PhotoPermission.VIEW_FAMILY,
        PhotoPermission.VIEW_PRIVATE,
        PhotoPermission.UPLOAD,
        PhotoPermission.DELETE,
    ],
    "Family": [
        PhotoPermission.VIEW_PUBLIC,
        PhotoPermission.VIEW_FAMILY,
        PhotoPermission.UPLOAD,
    ],
    "Guest": [
        PhotoPermission.VIEW_PUBLIC,
    ],
}

def has_photo_permission(cert_info: dict, permission: str) -> bool:
    ou = cert_info.get("ou", "Guest")
    return permission in PHOTO_PERMISSIONS.get(ou, [])

@app.route("/photos/<album_type>")
def view_photos(album_type):
    cert_info = get_certificate_info()

    # Check permission based on album type
    if album_type == "private" and not has_photo_permission(cert_info, PhotoPermission.VIEW_PRIVATE):
        return "Access denied", 403
    elif album_type == "family" and not has_photo_permission(cert_info, PhotoPermission.VIEW_FAMILY):
        return "Access denied", 403

    # Show photos...
```

### Example 2: Document Access with Owner Check

```python
@app.route("/documents/<int:doc_id>")
def view_document(doc_id):
    cert_info = get_certificate_info()

    # Load document from database
    document = get_document_by_id(doc_id)

    if not document:
        return "Document not found", 404

    # Check if user is owner
    owner_email = cert_info.get("email")
    if document.owner_email == owner_email:
        # Owner can always view their own documents
        return render_template("document.html", document=document)

    # Check permission level for others
    if document.visibility == "private":
        # Only owner can view
        return "Access denied", 403
    elif document.visibility == "family":
        # Require family member or admin
        if not check_permission(PermissionLevel.FAMILY_MEMBER, cert_info):
            return "Access denied", 403
    elif document.visibility == "public":
        # Anyone can view
        pass

    return render_template("document.html", document=document)
```

### Example 3: Dynamic Permission Loading

```python
# Store permissions in database instead of code
def get_user_permissions(cert_info: dict) -> list:
    """Load user permissions from database."""
    email = cert_info.get("email")

    # Query database for user permissions
    user = db.query("SELECT permissions FROM users WHERE email = ?", email)

    if user:
        return json.loads(user.permissions)
    else:
        # Default permissions based on OU
        ou = cert_info.get("ou", "Guest")
        return DEFAULT_PERMISSIONS.get(ou, [])

@app.route("/some-feature")
def some_feature():
    cert_info = get_certificate_info()
    permissions = get_user_permissions(cert_info)

    if "access_feature" not in permissions:
        return "Access denied", 403

    # Show feature...
```

---

## Troubleshooting

### Permission Not Working

**User has certificate but can't access page:**

1. **Check certificate OU field:**
   ```bash
   openssl x509 -in cert.pem -noout -subject
   ```
   Should show `OU=Admin` (or Family, Guest)

2. **Check backend receives OU:**
   - Visit `/api/cert-info`
   - Look for `"ou": "Admin"` in JSON response
   - If missing, check web server configuration

3. **Check permission logic:**
   ```python
   # Add debug logging in app.py
   ou = cert_info.get("ou", "")
   print(f"DEBUG: OU = {ou}")
   print(f"DEBUG: Permission = {determine_permission_level(cert_info)}")
   ```

4. **Verify permission hierarchy:**
   - Make sure `check_permission()` function includes all levels
   - Check hierarchy values are correct

### Headers Not Passed to Backend

**nginx:**
- Verify `proxy_set_header X-SSL-Client-OU $ssl_client_s_dn_ou;` exists
- Check nginx logs for certificate info
- Restart nginx after config changes

**Caddy:**
- Verify `header_up X-Client-Cert-OU {http.request.tls.client.subject.organizational_unit}` exists
- Check Caddy logs
- Restart Caddy after config changes

### Wrong Permission Detected

**Check certificate was created with correct OU:**

```bash
# View certificate details
openssl x509 -in certs/clients/username/cert.pem -noout -text | grep "Subject:"
```

Should show:
```
Subject: C=US, ST=California, L=San Francisco, O=Family, OU=Admin, CN=John Doe/emailAddress=john@example.com
                                                              ^^^^^^^^
                                                              This should match expected permission
```

**If OU is wrong:**
1. Revoke incorrect certificate
2. Generate new certificate with correct permission
3. Give new certificate to user

---

## Quick Reference

### Permission Configuration Checklist

- [ ] Define permission levels in `PermissionLevel` enum
- [ ] Update `determine_permission_level()` function
- [ ] Update `check_permission()` hierarchy
- [ ] Update certificate generation script
- [ ] Create or update protected routes
- [ ] Test with each permission level
- [ ] Document custom permissions

### Common Code Snippets

**Get user permission:**
```python
cert_info = get_certificate_info()
permission = determine_permission_level(cert_info)
```

**Check specific permission:**
```python
if check_permission(PermissionLevel.ADMIN, cert_info):
    # User is admin or higher
```

**Protect a route:**
```python
@app.route("/protected")
def protected_page():
    cert_info = get_certificate_info()
    if not check_permission(PermissionLevel.FAMILY_MEMBER, cert_info):
        return "Access denied", 403
    return "Welcome!"
```

---

## Further Reading

- [SERVER_SETUP.md](SERVER_SETUP.md) - Server configuration
- [CERTIFICATE_GENERATION.md](CERTIFICATE_GENERATION.md) - Creating certificates with permissions
- [Flask Authorization Patterns](https://flask.palletsprojects.com/en/2.3.x/patterns/authorization/)
- [OAuth2 Scopes](https://oauth.net/2/scope/) - Alternative permission model
