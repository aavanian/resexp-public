# Client Certificate Installation Guide

This guide provides step-by-step instructions for installing client certificates on various devices and browsers.

## Table of Contents

- [Before You Begin](#before-you-begin)
- [Desktop Platforms](#desktop-platforms)
  - [macOS](#macos)
  - [Windows](#windows)
  - [Linux](#linux)
- [Mobile Platforms](#mobile-platforms)
  - [iOS](#ios-iphone--ipad)
  - [Android](#android)
- [Browser-Specific Instructions](#browser-specific-instructions)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

## Before You Begin

### What You Need

1. **Certificate file** - Usually named `yourname.p12` or `yourname.pfx`
2. **Password** - Provided separately from the certificate file
3. **CA Certificate** (optional) - May be needed for some installations

### File Formats

- **PKCS#12 (.p12 or .pfx)** - Most common, works with all browsers and devices
- **PEM (.pem)** - Advanced users, some browsers

This guide focuses on `.p12` files as they're easiest for most users.

### Security First

⚠️ **Important Security Notes:**

- Keep your certificate and password secure
- Don't share your certificate file with anyone
- Don't send certificate and password via the same communication method
- Back up your certificate in a secure location

---

## Desktop Platforms

## macOS

macOS uses a system-wide Keychain that most browsers (Safari, Chrome, Brave, Arc) use automatically. Firefox manages its own certificates separately.

### Safari / Chrome / Brave / Arc / Orion (macOS)

These browsers all use the macOS Keychain, so install once and it works everywhere.

**Step 1: Install Certificate in Keychain**

1. **Locate your `.p12` file** (e.g., `john-doe.p12`)

2. **Double-click the `.p12` file**
   - Keychain Access application will open automatically

3. **Enter the certificate password**
   - This is the password that was provided with your certificate
   - Click "OK"

4. **Choose keychain location**
   - Select "login" keychain (recommended)
   - Click "Add"

5. **Enter your macOS password**
   - This authorizes adding the certificate to your keychain

**Step 2: Trust the Certificate**

1. **Open Keychain Access**
   - Applications → Utilities → Keychain Access
   - Or search "Keychain Access" in Spotlight

2. **Find your certificate**
   - Select "login" keychain on left sidebar
   - Select "My Certificates" category
   - Find your certificate (named with your common name)

3. **Set trust settings**
   - Double-click your certificate
   - Expand "Trust" section
   - Set "When using this certificate" to **"Always Trust"**
   - Close window (you'll be asked for your macOS password)

**Step 3: Install CA Certificate (if needed)**

If the website shows "not secure" warnings:

1. **Obtain `ca-cert.pem`** from your administrator

2. **Double-click `ca-cert.pem`**
   - Add to "login" or "System" keychain

3. **Trust the CA certificate**
   - Find it in Keychain Access (under "Certificates" category)
   - Double-click, expand "Trust"
   - Set "When using this certificate" to **"Always Trust"**
   - Set "Secure Sockets Layer (SSL)" to **"Always Trust"**

**Step 4: Test**

1. Open Safari (or Chrome/Brave/etc.)
2. Visit your family website (e.g., `https://family.example.com`)
3. Browser may prompt to select a certificate
   - Select your certificate
   - Click "OK" or "Allow"
   - Check "Always allow" to skip this prompt in the future

**Troubleshooting macOS:**

- **Certificate doesn't appear in browser**: Restart browser
- **Still prompted every time**: Check "Always allow" when selecting certificate
- **"Not secure" warning**: Install and trust CA certificate (see Step 3)
- **Permission denied**: Make sure certificate is in "login" keychain, not "System"

### Firefox (macOS)

Firefox uses its own certificate store, separate from macOS Keychain.

**Step 1: Open Certificate Manager**

1. Open Firefox
2. Click menu (☰) → Settings → Privacy & Security
3. Scroll down to "Certificates" section
4. Click "View Certificates" button
5. Select "Your Certificates" tab

**Step 2: Import Certificate**

1. Click "Import" button
2. Navigate to your `.p12` file
3. Click "Open"
4. Enter certificate password
5. Click "OK"

**Step 3: Import CA Certificate (if needed)**

1. In Certificate Manager, select "Authorities" tab
2. Click "Import"
3. Select `ca-cert.pem`
4. Check these boxes:
   - ✅ Trust this CA to identify websites
   - ✅ Trust this CA to identify email users
5. Click "OK"

**Step 4: Test**

1. Visit your family website
2. Firefox will prompt to select a certificate
3. Select your certificate and click "OK"
4. Check "Remember this decision" to avoid future prompts

---

## Windows

### Chrome / Edge (Windows)

Chrome and Edge use the Windows Certificate Store.

**Method 1: Double-Click Installation (Easiest)**

1. **Locate your `.p12` file**

2. **Double-click the `.p12` file**
   - Certificate Import Wizard opens

3. **Storage Location**
   - Select "Current User"
   - Click "Next"

4. **File to Import**
   - Should show your `.p12` file
   - Click "Next"

5. **Password**
   - Enter your certificate password
   - Click "Next"

6. **Certificate Store**
   - Select "Automatically select the certificate store"
   - Click "Next"

7. **Complete**
   - Click "Finish"
   - You should see "The import was successful"

**Method 2: Manual Installation**

1. **Open Certificate Manager**
   - Press `Win + R`
   - Type `certmgr.msc`
   - Press Enter

2. **Navigate to Personal Certificates**
   - Expand "Personal" folder
   - Right-click "Certificates"
   - Select "All Tasks" → "Import"

3. **Follow Import Wizard**
   - Click "Next"
   - Browse to your `.p12` file
   - Click "Next"
   - Enter password
   - Click "Next"
   - Select "Place all certificates in the following store"
   - Ensure "Personal" is selected
   - Click "Next"
   - Click "Finish"

**Install CA Certificate (if needed)**

1. **Import CA certificate**
   - Right-click "Trusted Root Certification Authorities"
   - Select "All Tasks" → "Import"
   - Import `ca-cert.pem`

2. **Trust warning**
   - Windows will warn about installing a root certificate
   - Verify the thumbprint with your administrator
   - Click "Yes" if correct

**Test in Browser**

1. Open Chrome or Edge
2. Visit your family website
3. Browser will prompt to select a certificate
4. Select your certificate and click "OK"

### Firefox (Windows)

Same process as Firefox on macOS (see above).

---

## Linux

### Chrome / Chromium (Linux)

Chrome on Linux can use either its own certificate store or the system store, depending on the distribution.

**Method 1: Chrome Certificate Manager**

1. **Open Chrome Settings**
   - Click menu (⋮) → Settings
   - Search for "certificates"
   - Click "Security" → "Manage certificates"

2. **Import Certificate**
   - Select "Your Certificates" tab
   - Click "Import"
   - Select your `.p12` file
   - Enter password

3. **Import CA Certificate**
   - Select "Authorities" tab
   - Click "Import"
   - Select `ca-cert.pem`
   - Check "Trust this certificate for identifying websites"
   - Click "OK"

**Method 2: NSS Database (Advanced)**

```bash
# Install certutil
sudo apt-get install libnss3-tools  # Debian/Ubuntu
sudo dnf install nss-tools          # Fedora

# Import certificate
certutil -d sql:$HOME/.pki/nssdb -A -t "P,," -n "My Cert" -i cert.pem
certutil -d sql:$HOME/.pki/nssdb -A -t "u,u,u" -n "My Key" -i key.pem

# Import CA certificate
certutil -d sql:$HOME/.pki/nssdb -A -t "C,," -n "Family CA" -i ca-cert.pem

# List certificates
certutil -d sql:$HOME/.pki/nssdb -L
```

### Firefox (Linux)

Same process as Firefox on macOS/Windows (see above).

---

## Mobile Platforms

## iOS (iPhone & iPad)

iOS Safari uses the system certificate store. Other browsers (Chrome, Firefox) on iOS are actually Safari wrappers and use the same certificate store.

**Step 1: Transfer Certificate to iOS**

Choose one method:

**Option A: AirDrop (if on macOS)**
1. On Mac: Right-click `.p12` file → Share → AirDrop
2. Select your iOS device
3. On iOS: Tap "Accept"

**Option B: Email**
1. Email the `.p12` file to yourself
2. Open email on iOS device
3. Tap the attachment

**Option C: Cloud Storage**
1. Upload `.p12` to iCloud Drive/Dropbox/etc.
2. Open on iOS device
3. Tap the file

**Step 2: Install Profile**

1. **After opening the `.p12` file**, iOS shows:
   - "Profile Downloaded"
   - Or "This website is trying to open Settings"

2. **Open Settings app**
   - You may see a notification "Profile Downloaded"
   - Or go to Settings → General → VPN & Device Management

3. **Install Profile**
   - Tap on the downloaded profile
   - Tap "Install" (top right)
   - Enter your device passcode
   - Tap "Install" again
   - Enter certificate password
   - Tap "Done"

**Step 3: Trust Certificate**

1. **Open Settings**
2. **Go to: General → About → Certificate Trust Settings**
3. **Enable full trust**
   - Toggle ON the switch next to your certificate
   - Confirm by tapping "Continue"

**Step 4: Install CA Certificate (if needed)**

Repeat Step 1-3 with `ca-cert.pem` file.

**Step 5: Test**

1. Open Safari
2. Visit your family website
3. Website should load without errors
4. You may see a popup asking to use the certificate
   - Tap "Allow"
   - Consider selecting "Always Allow" for convenience

**iOS Troubleshooting:**

- **"Cannot verify server identity"**: Install and trust CA certificate (Step 4)
- **Certificate not appearing**: Make sure you trusted it in Step 3
- **Installing profile fails**: Check certificate password is correct
- **"Profile installation failed"**: File may be corrupted, request a new one

### iOS - Remove Certificate

If you need to remove a certificate:

1. Settings → General → VPN & Device Management
2. Tap the profile/certificate
3. Tap "Remove Profile"
4. Enter device passcode
5. Confirm removal

---

## Android

Android certificate installation varies slightly by manufacturer (Samsung, Google, OnePlus, etc.) but follows a similar process.

**Step 1: Transfer Certificate to Android**

**Option A: Email**
1. Email `.p12` file to yourself
2. Open email on Android device
3. Download attachment

**Option B: Cloud Storage**
1. Upload to Google Drive/Dropbox
2. Download on Android device

**Option C: USB Transfer**
1. Connect device to computer
2. Copy `.p12` file to Downloads folder

**Step 2: Install Certificate**

**Method 1: Direct Installation (Most Devices)**

1. **Tap the `.p12` file**
   - In Downloads app, Files app, or email attachment
   - Android may prompt: "Install certificates"

2. **Name the certificate**
   - Enter a name (e.g., "Family Site Cert")

3. **Enter password**
   - Type the certificate password
   - Tap "OK"

4. **Set credential use**
   - Select "VPN and apps" (recommended)
   - Or "Wi-Fi" for Wi-Fi certificates only

5. **Set lock screen**
   - If you don't have a lock screen PIN/password
   - Android will require you to set one
   - Follow prompts to set PIN/password/pattern

**Method 2: Settings Menu (Alternative)**

1. **Open Settings**
2. **Navigate to security**
   - Settings → Security → Encryption & credentials
   - Or: Settings → Biometrics and security → Other security settings
   - (Path varies by manufacturer)

3. **Install certificate**
   - Tap "Install a certificate" or "Install from storage"
   - Select "CA certificate" or "VPN & app user certificate"
   - Browse to your `.p12` file
   - Tap to select

4. **Enter password**
   - Type certificate password
   - Tap "OK"

**Step 3: Install CA Certificate (if needed)**

1. Go to Settings → Security → Encryption & credentials
2. Tap "Install a certificate" → "CA certificate"
3. Android shows warning about network monitoring
   - This is standard for CA certificates
   - Tap "Install anyway"
4. Select `ca-cert.pem` file

**Step 4: Test**

1. **Open Chrome browser**
2. **Visit your family website**
3. **Chrome should prompt** to select a certificate
   - Select your certificate
   - Tap "Allow"
   - Check "Remember my choice" for future

**Android Troubleshooting:**

- **"No certificate to install"**: File may be corrupted or wrong format
- **Chrome doesn't prompt for certificate**: Certificate may not be installed correctly
- **"Your connection is not private"**: Install CA certificate (Step 3)
- **Can't find certificate option in Settings**: Search Settings for "certificate" or "credential"

### Android - View/Remove Certificates

1. Settings → Security → Encryption & credentials
2. Tap "User credentials" or "Trusted credentials"
3. Find your certificate
4. Tap to view details or remove

---

## Browser-Specific Instructions

### Safari

Uses system certificate store (macOS Keychain or iOS certificate store).
See platform-specific instructions above.

### Chrome

- **macOS/Windows**: Uses system certificate store
- **Linux**: Uses NSS database or system store
- **Android**: Uses Android certificate store
- **iOS**: Uses iOS certificate store (same as Safari)

### Firefox

- **All Platforms**: Uses its own certificate store
- See Firefox-specific instructions in each platform section

### Edge

- **Windows/macOS**: Uses system certificate store
- Same process as Chrome

### Brave

- **All Platforms**: Uses system certificate store
- Same process as Chrome

### Opera

- **All Platforms**: Usually uses system certificate store
- If not working, use Firefox instructions

---

## Verification

### How to Verify Certificate is Installed

**macOS:**
```bash
# List certificates in Keychain
security find-identity -p ssl-client -v
```

**Windows:**
```cmd
certutil -user -store My
```

**Linux (NSS):**
```bash
certutil -d sql:$HOME/.pki/nssdb -L
```

**Browser (any platform):**
1. Visit your family website
2. Click the padlock icon in address bar
3. Click "Connection is secure" → "Certificate is valid"
4. Should show your certificate information

### Test Certificate is Working

**Method 1: Via Website**
1. Open your browser
2. Go to `https://your-family-site.com`
3. Check for:
   - ✅ Padlock icon (secure connection)
   - ✅ Your name displayed on the page
   - ✅ Access to protected pages

**Method 2: Via curl (command line)**
```bash
# Test with certificate
curl --cert cert.pem --key key.pem https://your-site.com/api/cert-info

# Or with .p12 file
curl --cert-type P12 --cert file.p12:PASSWORD https://your-site.com/api/cert-info
```

Expected response shows your certificate information as JSON.

---

## Troubleshooting

### Common Issues

**"The site cannot provide a secure connection"**
- **Cause**: Server certificate not trusted
- **Fix**: Install CA certificate (`ca-cert.pem`)

**Browser doesn't prompt for certificate**
- **Cause**: Certificate not installed correctly
- **Fix**: Re-install certificate, restart browser

**"Your connection is not private" / NET::ERR_CERT_AUTHORITY_INVALID**
- **Cause**: CA certificate not trusted
- **Fix**: Install and trust CA certificate

**Certificate prompts every time**
- **Cause**: Browser not remembering selection
- **Fix**: Check "Always allow" or "Remember my choice" when prompted

**Wrong certificate selected automatically**
- **Cause**: Multiple certificates installed
- **Fix**: Remove old certificates, or select correct one each time

**Certificate expired**
- **Cause**: Certificate validity period ended
- **Fix**: Contact administrator for renewed certificate

### Getting Help

If you're stuck:

1. **Check certificate validity**:
   ```bash
   openssl pkcs12 -in yourname.p12 -noout -info
   # Enter password when prompted
   ```

2. **Verify you have the right files**:
   - Certificate file (`.p12`)
   - Password
   - CA certificate (optional but helpful)

3. **Try a different browser**:
   - If Chrome doesn't work, try Firefox
   - Helps isolate if issue is certificate or browser-specific

4. **Check with administrator**:
   - Certificate may be revoked
   - Server may be misconfigured
   - You may need a new certificate

5. **Browser developer tools**:
   - Press F12 → Console tab
   - Look for certificate or TLS errors
   - Share error messages with administrator

### Platform-Specific Issues

**macOS: "Not trusted" in Keychain**
- Right-click certificate → Get Info → Trust → "Always Trust"

**Windows: "Cannot find the certificate and private key for decryption"**
- Re-import certificate, ensure it goes to "Personal" store

**iOS: "Cannot verify server identity"**
- Settings → General → About → Certificate Trust Settings
- Enable trust for CA certificate

**Android: "Unknown certificate authority"**
- Install CA certificate as "CA certificate" (not user certificate)

**Linux: Chrome says certificate not available**
- Make sure certificate is in NSS database
- Try restarting Chrome completely

### Security Warnings

These warnings are NORMAL for a private CA:

- ✅ "This site uses a certificate from an unrecognized authority"
  → Expected with private CA, install CA cert to fix

- ✅ "Your connection is not private" (before installing CA cert)
  → Normal, will go away after installing CA cert

These warnings are NOT NORMAL and require attention:

- ⚠️ "This certificate has been revoked"
  → Contact administrator immediately

- ⚠️ "This certificate is expired"
  → Request renewed certificate

- ⚠️ "Certificate is not trusted"
  → After installing CA cert → Possible attack, verify with administrator

---

## Quick Reference Card

**Installation Quick Steps:**

| Platform | Quick Steps |
|----------|-------------|
| **macOS** | Double-click `.p12` → Enter password → Trust in Keychain Access |
| **Windows** | Double-click `.p12` → Follow wizard → Install to Personal store |
| **Linux** | Chrome Settings → Manage certificates → Import → Your Certificates |
| **iOS** | AirDrop/Email `.p12` → Settings → Install Profile → Trust in Certificate Trust Settings |
| **Android** | Download `.p12` → Tap file → Enter password → Set lock screen if needed |

**Common Commands:**

```bash
# Verify .p12 file integrity
openssl pkcs12 -in file.p12 -info -noout

# Extract certificate from .p12
openssl pkcs12 -in file.p12 -clcerts -nokeys -out cert.pem

# Extract private key from .p12
openssl pkcs12 -in file.p12 -nocerts -nodes -out key.pem

# Test with curl
curl --cert cert.pem --key key.pem https://site.com
```

---

## Need Help?

- 📖 [User Best Practices](USER_BEST_PRACTICES.md) - Security guidelines
- 📖 [Certificate Generation](CERTIFICATE_GENERATION.md) - How certificates are created
- 📖 [Permissions Guide](PERMISSIONS_GUIDE.md) - Understanding access levels
