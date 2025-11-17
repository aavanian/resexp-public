"""
Flask application for client certificate authentication demonstration.

This application demonstrates how to handle client certificate authentication
with different permission levels based on certificate attributes.
"""

import os
from datetime import datetime
from enum import Enum
from typing import Optional

from flask import Flask, jsonify, render_template_string, request

app = Flask(__name__)


class PermissionLevel(Enum):
    """Permission levels based on certificate attributes."""

    GUEST = "guest"
    FAMILY_MEMBER = "family-member"
    ADMIN = "admin"


# Certificate header names vary by web server
# nginx uses: X-SSL-Client-*
# Caddy uses: X-Client-Cert-*
CERT_HEADERS = {
    "dn": ["X-SSL-Client-DN", "X-Client-Cert-Subject"],
    "cn": ["X-SSL-Client-CN", "X-Client-Cert-CN"],
    "email": ["X-SSL-Client-Email", "X-Client-Cert-Email"],
    "serial": ["X-SSL-Client-Serial", "X-Client-Cert-Serial"],
    "verified": ["X-SSL-Client-Verify", "X-Client-Cert-Verified"],
    "not_before": ["X-SSL-Client-Not-Before", "X-Client-Cert-Not-Before"],
    "not_after": ["X-SSL-Client-Not-After", "X-Client-Cert-Not-After"],
    "ou": ["X-SSL-Client-OU", "X-Client-Cert-OU"],
}


def get_cert_header(header_names: list[str]) -> Optional[str]:
    """Get certificate header value from multiple possible header names."""
    for header in header_names:
        value = request.headers.get(header)
        if value:
            return value
    return None


def get_certificate_info() -> dict:
    """Extract certificate information from headers."""
    return {
        "dn": get_cert_header(CERT_HEADERS["dn"]),
        "cn": get_cert_header(CERT_HEADERS["cn"]),
        "email": get_cert_header(CERT_HEADERS["email"]),
        "serial": get_cert_header(CERT_HEADERS["serial"]),
        "verified": get_cert_header(CERT_HEADERS["verified"]),
        "not_before": get_cert_header(CERT_HEADERS["not_before"]),
        "not_after": get_cert_header(CERT_HEADERS["not_after"]),
        "ou": get_cert_header(CERT_HEADERS["ou"]),
    }


def determine_permission_level(cert_info: dict) -> PermissionLevel:
    """
    Determine user permission level based on certificate attributes.

    Permission logic:
    - Admin: OU (Organizational Unit) contains "Admin"
    - Family Member: OU contains "Family"
    - Guest: OU contains "Guest" or any other value
    """
    if not cert_info.get("verified") or cert_info["verified"] not in ["SUCCESS", "success", "1"]:
        return PermissionLevel.GUEST

    ou = cert_info.get("ou", "").lower()

    if "admin" in ou:
        return PermissionLevel.ADMIN
    elif "family" in ou:
        return PermissionLevel.FAMILY_MEMBER
    else:
        return PermissionLevel.GUEST


def check_permission(required_level: PermissionLevel, cert_info: dict) -> bool:
    """Check if user has required permission level."""
    current_level = determine_permission_level(cert_info)

    # Permission hierarchy: ADMIN > FAMILY_MEMBER > GUEST
    hierarchy = {
        PermissionLevel.ADMIN: 3,
        PermissionLevel.FAMILY_MEMBER: 2,
        PermissionLevel.GUEST: 1,
    }

    return hierarchy.get(current_level, 0) >= hierarchy.get(required_level, 0)


def get_certificate_expiry_info(cert_info: dict) -> dict:
    """Get certificate expiry information."""
    not_after = cert_info.get("not_after")
    if not not_after:
        return {"expired": False, "days_remaining": None, "expiry_date": None}

    try:
        # Try parsing common date formats
        for fmt in ["%b %d %H:%M:%S %Y %Z", "%Y-%m-%d %H:%M:%S", "%Y%m%d%H%M%SZ"]:
            try:
                expiry_date = datetime.strptime(not_after, fmt)
                days_remaining = (expiry_date - datetime.now()).days
                return {
                    "expired": days_remaining < 0,
                    "days_remaining": days_remaining,
                    "expiry_date": expiry_date.strftime("%Y-%m-%d"),
                }
            except ValueError:
                continue
    except Exception:
        pass

    return {"expired": False, "days_remaining": None, "expiry_date": not_after}


# HTML templates
HOME_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Client Certificate Authentication Demo</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            border-radius: 8px;
            padding: 30px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .header {
            border-bottom: 2px solid #007bff;
            padding-bottom: 20px;
            margin-bottom: 20px;
        }
        .cert-info {
            background: #f8f9fa;
            border-left: 4px solid #007bff;
            padding: 15px;
            margin: 20px 0;
            border-radius: 4px;
        }
        .permission-badge {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-weight: bold;
            margin: 10px 0;
        }
        .admin { background: #dc3545; color: white; }
        .family-member { background: #28a745; color: white; }
        .guest { background: #6c757d; color: white; }
        .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
        .info-grid {
            display: grid;
            grid-template-columns: 200px 1fr;
            gap: 10px;
            margin: 15px 0;
        }
        .info-label {
            font-weight: bold;
            color: #495057;
        }
        .info-value {
            color: #212529;
            word-break: break-all;
        }
        .nav-links {
            margin: 30px 0;
        }
        .nav-links a {
            display: inline-block;
            margin: 10px 10px 10px 0;
            padding: 10px 20px;
            background: #007bff;
            color: white;
            text-decoration: none;
            border-radius: 4px;
        }
        .nav-links a:hover {
            background: #0056b3;
        }
        .access-list {
            list-style: none;
            padding: 0;
        }
        .access-list li {
            padding: 10px;
            margin: 5px 0;
            background: #e9ecef;
            border-radius: 4px;
        }
        .access-list li.accessible {
            background: #d4edda;
            border-left: 4px solid #28a745;
        }
        .access-list li.restricted {
            background: #f8d7da;
            border-left: 4px solid #dc3545;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔐 Client Certificate Authentication Demo</h1>
            <p>This demo shows how client certificate authentication works with different permission levels.</p>
        </div>

        <div class="cert-info">
            <h2>Your Certificate Information</h2>
            {% if cert_info.verified %}
                <span class="permission-badge {{ permission_level }}">
                    {{ permission_level.upper() }}
                </span>

                {% if expiry_info.days_remaining is not none %}
                    {% if expiry_info.days_remaining < 30 %}
                        <div class="warning">
                            <strong>⚠️ Certificate Expiring Soon!</strong>
                            Your certificate will expire in {{ expiry_info.days_remaining }} days
                            ({{ expiry_info.expiry_date }})
                        </div>
                    {% endif %}
                {% endif %}

                <div class="info-grid">
                    <div class="info-label">Common Name:</div>
                    <div class="info-value">{{ cert_info.cn or 'N/A' }}</div>

                    <div class="info-label">Email:</div>
                    <div class="info-value">{{ cert_info.email or 'N/A' }}</div>

                    <div class="info-label">Serial Number:</div>
                    <div class="info-value">{{ cert_info.serial or 'N/A' }}</div>

                    <div class="info-label">Organizational Unit:</div>
                    <div class="info-value">{{ cert_info.ou or 'N/A' }}</div>

                    <div class="info-label">Valid Until:</div>
                    <div class="info-value">
                        {{ expiry_info.expiry_date or cert_info.not_after or 'N/A' }}
                    </div>

                    <div class="info-label">Permission Level:</div>
                    <div class="info-value">{{ permission_level }}</div>
                </div>
            {% else %}
                <div class="warning">
                    <strong>⚠️ No Valid Certificate Detected</strong>
                    <p>You are browsing without a client certificate or your certificate could not be verified.</p>
                    <p>Please install a valid client certificate to access protected resources.</p>
                </div>
            {% endif %}
        </div>

        <div class="nav-links">
            <h2>Available Pages</h2>
            <ul class="access-list">
                <li class="accessible">
                    <a href="/">🏠 Home</a> - Public (Everyone)
                </li>
                <li class="{{ 'accessible' if can_access_family else 'restricted' }}">
                    <a href="/family">👨‍👩‍👧‍👦 Family Page</a> - Requires: Family Member or Admin
                    {% if not can_access_family %}<strong> 🔒 RESTRICTED</strong>{% endif %}
                </li>
                <li class="{{ 'accessible' if can_access_admin else 'restricted' }}">
                    <a href="/admin">⚙️ Admin Page</a> - Requires: Admin
                    {% if not can_access_admin %}<strong> 🔒 RESTRICTED</strong>{% endif %}
                </li>
                <li class="accessible">
                    <a href="/api/cert-info">📋 API: Certificate Info (JSON)</a> - Public
                </li>
            </ul>
        </div>
    </div>
</body>
</html>
"""

FAMILY_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Family Page - Client Cert Demo</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            border-radius: 8px;
            padding: 30px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .success {
            background: #d4edda;
            border-left: 4px solid #28a745;
            padding: 15px;
            margin: 20px 0;
            border-radius: 4px;
        }
        a {
            color: #007bff;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>👨‍👩‍👧‍👦 Family Members Area</h1>
        <div class="success">
            <p><strong>✅ Access Granted!</strong></p>
            <p>Welcome, {{ cert_info.cn }}! This page is only accessible to family members and admins.</p>
        </div>
        <p>This is where family-specific content would appear, such as:</p>
        <ul>
            <li>Shared photo albums</li>
            <li>Family calendar and events</li>
            <li>Shared documents and files</li>
            <li>Family announcements</li>
        </ul>
        <p><a href="/">← Back to Home</a></p>
    </div>
</body>
</html>
"""

ADMIN_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Admin Page - Client Cert Demo</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            border-radius: 8px;
            padding: 30px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .success {
            background: #d4edda;
            border-left: 4px solid #28a745;
            padding: 15px;
            margin: 20px 0;
            border-radius: 4px;
        }
        .admin-section {
            background: #f8f9fa;
            padding: 15px;
            margin: 15px 0;
            border-radius: 4px;
        }
        a {
            color: #007bff;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>⚙️ Administration Area</h1>
        <div class="success">
            <p><strong>✅ Admin Access Granted!</strong></p>
            <p>Welcome, {{ cert_info.cn }}! You have full administrative access.</p>
        </div>

        <div class="admin-section">
            <h2>Administrative Functions</h2>
            <p>This is where admin-specific functionality would appear, such as:</p>
            <ul>
                <li>User management (issue/revoke certificates)</li>
                <li>Access logs and audit trails</li>
                <li>System configuration</li>
                <li>Certificate renewal management</li>
                <li>Permission level assignments</li>
            </ul>
        </div>

        <p><a href="/">← Back to Home</a></p>
    </div>
</body>
</html>
"""

FORBIDDEN_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Access Forbidden - Client Cert Demo</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            border-radius: 8px;
            padding: 30px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .error {
            background: #f8d7da;
            border-left: 4px solid #dc3545;
            padding: 15px;
            margin: 20px 0;
            border-radius: 4px;
        }
        a {
            color: #007bff;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔒 Access Forbidden</h1>
        <div class="error">
            <p><strong>❌ Access Denied</strong></p>
            <p>{{ message }}</p>
            <p><strong>Your permission level:</strong> {{ current_level }}</p>
            <p><strong>Required permission level:</strong> {{ required_level }}</p>
        </div>
        <p>If you believe you should have access to this page, please contact the administrator.</p>
        <p><a href="/">← Back to Home</a></p>
    </div>
</body>
</html>
"""


@app.route("/")
def home():
    """Home page - accessible to everyone."""
    cert_info = get_certificate_info()
    permission_level = determine_permission_level(cert_info).value
    expiry_info = get_certificate_expiry_info(cert_info)

    return render_template_string(
        HOME_TEMPLATE,
        cert_info=cert_info,
        permission_level=permission_level,
        expiry_info=expiry_info,
        can_access_family=check_permission(PermissionLevel.FAMILY_MEMBER, cert_info),
        can_access_admin=check_permission(PermissionLevel.ADMIN, cert_info),
    )


@app.route("/family")
def family_page():
    """Family page - requires family member or admin permission."""
    cert_info = get_certificate_info()

    if not check_permission(PermissionLevel.FAMILY_MEMBER, cert_info):
        current_level = determine_permission_level(cert_info).value
        return (
            render_template_string(
                FORBIDDEN_TEMPLATE,
                message="You need to be a family member or admin to access this page.",
                current_level=current_level,
                required_level=PermissionLevel.FAMILY_MEMBER.value,
            ),
            403,
        )

    return render_template_string(FAMILY_TEMPLATE, cert_info=cert_info)


@app.route("/admin")
def admin_page():
    """Admin page - requires admin permission."""
    cert_info = get_certificate_info()

    if not check_permission(PermissionLevel.ADMIN, cert_info):
        current_level = determine_permission_level(cert_info).value
        return (
            render_template_string(
                FORBIDDEN_TEMPLATE,
                message="You need administrator privileges to access this page.",
                current_level=current_level,
                required_level=PermissionLevel.ADMIN.value,
            ),
            403,
        )

    return render_template_string(ADMIN_TEMPLATE, cert_info=cert_info)


@app.route("/api/cert-info")
def api_cert_info():
    """API endpoint returning certificate information as JSON."""
    cert_info = get_certificate_info()
    permission_level = determine_permission_level(cert_info)
    expiry_info = get_certificate_expiry_info(cert_info)

    return jsonify(
        {
            "certificate": cert_info,
            "permission_level": permission_level.value,
            "expiry_info": expiry_info,
            "access_levels": {
                "home": True,
                "family": check_permission(PermissionLevel.FAMILY_MEMBER, cert_info),
                "admin": check_permission(PermissionLevel.ADMIN, cert_info),
            },
        }
    )


@app.route("/health")
def health():
    """Health check endpoint."""
    return jsonify({"status": "healthy", "service": "client-cert-auth-backend"})


if __name__ == "__main__":
    # Development server - do not use in production
    app.run(host="0.0.0.0", port=5000, debug=True)
