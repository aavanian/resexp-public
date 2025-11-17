# User Best Practices Guide

This guide helps you use your client certificate safely and securely. Even if you're not technical, following these practices will keep your family website secure.

## Table of Contents

- [Quick Security Rules](#quick-security-rules)
- [Certificate Basics](#certificate-basics)
- [Installing Your Certificate](#installing-your-certificate)
- [Using Your Certificate](#using-your-certificate)
- [Security Best Practices](#security-best-practices)
- [Recognizing Threats](#recognizing-threats)
- [Certificate Lifecycle](#certificate-lifecycle)
- [What to Do If...](#what-to-do-if)

---

## Quick Security Rules

### The 5 Essential Rules

1. **🔒 Keep your certificate password secret**
   - Never share it
   - Don't write it on sticky notes
   - Store it in a password manager

2. **💾 Backup your certificate securely**
   - Keep a copy in a secure location
   - Don't email it to yourself
   - Encrypted cloud storage is OK

3. **🎯 Only approve certificate prompts for YOUR family site**
   - Know your site's URL
   - Don't click "OK" on random certificate prompts

4. **📱 Protect your devices**
   - Use device passcode/password
   - Don't install certificates on public/shared computers
   - Enable device encryption

5. **⏰ Renew before expiration**
   - Certificate expires after 1 year
   - Request renewal 30 days before expiration

---

## Certificate Basics

### What is a Client Certificate?

Think of your client certificate like a **digital key card**:

- 🏢 Building key card → Opens specific doors based on your access level
- 🔐 Client certificate → Grants access to website pages based on your permissions

### Why Use Certificates?

**Better than passwords because:**

- ✅ Can't be guessed (like passwords can)
- ✅ Can't be phished (stolen by fake websites)
- ✅ Automatically protects all your browsing
- ✅ Can be revoked instantly if lost

**Example scenario:**

```
WITHOUT certificate:
You → Password login → Website (could be fake!)

WITH certificate:
You → Automatic certificate exchange → Website ✓
      ↓                                    ↓
   Browser checks                    Server checks
   server identity                   your certificate
      ↓                                    ↓
   Both verified → Secure connection established
```

### What's In Your Certificate?

Your certificate contains:

- **Your name** - Common Name (CN)
- **Your email** - For identification
- **Permission level** - Admin, Family, or Guest
- **Expiration date** - When it needs renewal
- **Digital signature** - Proves it's authentic

Your certificate does **NOT** contain:
- ❌ Your passwords
- ❌ Your browsing history
- ❌ Personal information beyond name/email

---

## Installing Your Certificate

### What You'll Receive

When you get a certificate, you'll receive two things **separately**:

1. **Certificate file** (yourname.p12)
   - Via email, USB drive, or secure file share
   - File size: ~2-4 KB

2. **Password** (provided separately)
   - Via text message, phone call, or separate email
   - One-time use for installation

### Installation Security

✅ **DO:**
- Install on your personal devices only
- Install in a private location
- Verify the sender before installing
- Keep the password until installation completes

❌ **DON'T:**
- Install on public computers (library, internet cafe)
- Install on work computers (unless approved)
- Install on borrowed devices
- Share your certificate file with others

### After Installation

Once installed, you can:

1. **Delete the .p12 file** (certificate is now in your device)
2. **Delete the installation email** (if received via email)
3. **Keep a backup** in secure storage (see Backup section below)

---

## Using Your Certificate

### Accessing the Family Website

**First time:**
1. Open your web browser
2. Go to your family website URL
3. Browser will prompt: "Select a certificate"
4. Choose your certificate (shows your name)
5. Click "OK" or "Allow"
6. Check "Remember" or "Always allow" for convenience

**Subsequent visits:**
- Should automatically use your certificate
- No prompts needed
- Just visit the website normally

### When to Approve Certificate Requests

Your browser will ask to use your certificate when:

✅ **SAFE TO APPROVE:**
- Visiting your known family website
- URL matches exactly (https://family.example.com)
- You initiated the visit
- Padlock icon shows secure connection

❌ **DO NOT APPROVE:**
- Unknown websites asking for certificate
- Misspelled family website URL
- Popup appears without you visiting site
- HTTP (not HTTPS) website
- Site with certificate warnings

**Example - SAFE:**
```
[Certificate Selection Dialog]
family.example.com requests your certificate
Select certificate: John Doe (family.example.com)
[Remember this choice] ☑️
                   [Cancel]  [OK]
```

**Example - SUSPICIOUS:**
```
[Certificate Selection Dialog]
fami1y.example.com requests your certificate
⚠️ This connection is not secure
Select certificate: John Doe
                   [Cancel]  [OK]
```
👆 Notice misspelled URL and warning - DO NOT APPROVE!

### Multiple Devices

You can install your certificate on multiple devices:

- ✅ Your personal laptop
- ✅ Your personal desktop
- ✅ Your smartphone
- ✅ Your tablet

All using the **same** certificate file.

**Note:** Don't install the same certificate on more than ~5 devices. If you need more, contact the administrator.

---

## Security Best Practices

### Password Management

**For certificate installation password:**

Store in a password manager:
- 1Password
- LastPass
- Bitwarden
- Apple Keychain
- Google Password Manager

Or write it down and keep in a **secure physical location**:
- Locked drawer
- Safe
- Wallet (not ideal but OK temporarily)

**Don't:**
- ❌ Store in notes app unencrypted
- ❌ Email to yourself
- ❌ Post in family chat
- ❌ Share with others "for safekeeping"

### Certificate Backup

**Why backup?**

If you lose access to your device:
- Broken computer
- Lost phone
- Factory reset
- Hard drive failure

You'll need the certificate backup to regain access.

**How to backup safely:**

**Option 1: Encrypted Cloud Storage (Recommended)**
```
1. Put .p12 file in password manager as "secure file"
2. Or: encrypt with 7-Zip/GPG and upload to cloud
3. Store password separately (not with file)
```

**Option 2: Encrypted USB Drive**
```
1. Copy .p12 file to USB drive
2. Encrypt USB drive (BitLocker, FileVault, etc.)
3. Store USB in secure location (safe, locked drawer)
4. Keep password separate from USB
```

**Option 3: Encrypted External Backup**
```
1. Include in your regular encrypted backups
2. Time Machine (macOS) - encrypted
3. Windows Backup - encrypted
4. Ensure backups are password-protected
```

**Don't:**
- ❌ Email to yourself
- ❌ Store on unencrypted cloud storage
- ❌ Keep only one copy (always have backup)
- ❌ Store password with backup

### Device Security

Your certificate is only as secure as your device:

**Essential device security:**

1. **Lock Screen**
   - Use PIN, password, pattern, or biometric
   - Auto-lock after 5 minutes or less
   - Don't use simple patterns (1234, etc.)

2. **Device Encryption**
   - **iOS/macOS:** Enabled automatically
   - **Android:** Settings → Security → Encrypt device
   - **Windows:** BitLocker (Settings → System → Device encryption)
   - **Linux:** Enable during installation or use LUKS

3. **Keep Software Updated**
   - Install OS security updates
   - Keep browser updated
   - Enable automatic updates if possible

4. **Antivirus/Anti-malware**
   - Windows: Windows Defender (built-in) is sufficient
   - macOS: Built-in protection is usually enough
   - Android: Google Play Protect (built-in)

### Physical Security

**At home:**
- Lock computer when away (Windows: Win+L, Mac: Cmd+Ctrl+Q)
- Don't leave devices unattended while logged in
- Log out of browsers on shared computers

**In public:**
- Don't access family site on public WiFi (use VPN if necessary)
- Don't install certificates on public computers
- Be aware of shoulder surfers

**If device is stolen:**
- Contact administrator immediately to revoke certificate
- Use Find My Device / Find My iPhone to lock/wipe device
- Change passwords for other accounts

---

## Recognizing Threats

### Phishing Attempts

**What is phishing?**

Fake websites or emails trying to steal your information.

**Certificate phishing might look like:**

❌ **Fake Email:**
```
From: admin@fami1y.example.com (note the "1" instead of "l")
Subject: Your certificate has expired!

Your security certificate has expired.
Click here to renew: http://family-renew.com/cert
```

This is FAKE because:
- Domain is misspelled
- Uses HTTP not HTTPS
- Administrator wouldn't send renewal links
- Creates urgency to rush you

✅ **Real Certificate Renewal:**
```
Face-to-face communication or secure channel
Administrator will:
- Contact you directly
- Provide new .p12 file securely
- Never ask for your current certificate
- Never send links to click
```

### Warning Signs

**🚨 IMMEDIATE RED FLAGS:**

1. **Someone asks for your certificate file or password**
   - Administrator never needs these
   - This is always malicious

2. **Email with certificate attached from unknown sender**
   - Could be malware
   - Verify sender before opening

3. **Website with similar URL asks for certificate**
   - `fami1y.example.com` (number 1 instead of letter l)
   - `family.examp1e.com`
   - `family-example.com`
   - Check URL carefully

4. **Browser shows certificate error but prompts you to continue**
   - Don't ignore certificate warnings
   - Contact administrator if family site shows warnings

5. **Unexpected certificate selection prompt**
   - You didn't visit family site
   - Random popup appears
   - Don't select your certificate

### Safe Verification

**If you receive communication about your certificate:**

✅ **Verify it's legitimate:**
1. Contact administrator through known, trusted method
2. Call them directly (use phone number you already have)
3. Ask in person if possible
4. Don't use contact info from suspicious message

❌ **Don't:**
- Click links in emails about certificates
- Call phone numbers provided in suspicious messages
- Respond to texts asking about certificates
- Share certificate or password to "verify" anything

---

## Certificate Lifecycle

### Validity Period

Your certificate is valid for **1 year** from issue date.

**Timeline:**
```
Day 0:    Certificate issued
Day 335:  Renewal reminder appears on website (30 days before expiry)
Day 350:  Follow up reminder
Day 365:  Certificate expires - you lose access
```

### Renewal Process

**30 days before expiration:**

1. **Website will show warning:**
   ```
   ⚠️ Certificate Expiring Soon!
   Your certificate will expire in 25 days (Dec 15, 2024)
   Please contact the administrator for renewal.
   ```

2. **Contact administrator:**
   - Use your normal communication channel
   - Request certificate renewal
   - Mention you see the expiration warning

3. **Receive new certificate:**
   - Install using same process as before
   - Old certificate continues working until expiration
   - No downtime

4. **Test new certificate:**
   - Visit family website
   - Verify you can access all pages
   - Confirm new expiration date (1 year from now)

**What happens if you let it expire:**
- Certificate stops working at expiration
- You lose access to family site
- Must request new certificate from administrator
- Same installation process as before

### Certificate Replacement

**You'll need a new certificate if:**

- Current certificate expires
- You change your name
- Your permission level changes
- Certificate is compromised
- Administrator issues updated certificates

**Process:**
1. Receive new certificate
2. Install new certificate (same process)
3. Old certificate can be removed or left (will expire)
4. Test access with new certificate

---

## What to Do If...

### "My device was stolen"

**IMMEDIATELY:**

1. **Contact administrator** - Get your certificate revoked
2. **Use Find My Device**:
   - iPhone: iCloud.com → Find My iPhone → Erase iPhone
   - Android: google.com/android/find → Erase device
3. **Change other passwords** - Other accounts may be at risk

**After certificate is revoked:**
- Thief cannot use certificate anymore
- Request new certificate when you get new device
- Install on new device

### "I lost my certificate file"

**If certificate is already installed on a device:**
- ✅ You're fine! Continue using it normally
- Certificate is stored in device, don't need file anymore
- Make a backup from the device (export from keychain/cert store)

**If certificate is NOT installed anywhere:**
- ⚠️ Contact administrator
- Request new certificate
- Follow installation instructions

**Prevention:**
- Backup certificate after installation (see Backup section)
- Store backup securely

### "I forgot my certificate password"

**For installation:** If you haven't installed yet
- Contact administrator
- They can provide password again or issue new certificate

**For using website:** No password needed
- Certificates don't require passwords after installation
- Browser uses certificate automatically

**For backup:** If you need to restore from backup
- Try password manager (if you stored it there)
- Contact administrator for new certificate if can't recover

### "My browser keeps asking which certificate to use"

**This happens when:**
- Multiple certificates installed
- Browser didn't remember your choice

**Solution:**
1. Select your certificate
2. ✅ Check "Remember this choice" or "Always allow"
3. Click OK
4. Should only ask once

**If it keeps asking every time:**
- Verify checkbox for "remember" is available and checked
- Try removing old/expired certificates
- Restart browser

### "Website says my certificate is invalid"

**Possible causes:**

1. **Certificate expired**
   - Check expiration date
   - Request renewal from administrator

2. **Certificate revoked**
   - Administrator may have revoked it
   - Contact administrator
   - May need new certificate

3. **Wrong certificate selected**
   - You have multiple certificates
   - Make sure you select the right one
   - Look for most recent/correct name

4. **Certificate not installed properly**
   - Try re-installing
   - See installation guide for your platform

5. **Browser issue**
   - Try different browser
   - Clear browser cache
   - Restart browser

### "I see 'Your connection is not private'"

**For the family website:**

This usually means CA certificate not trusted.

**Solution:**
1. Get `ca-cert.pem` from administrator
2. Install and trust CA certificate
3. See [CLIENT_INSTALLATION.md](CLIENT_INSTALLATION.md) for platform-specific instructions

**For other websites:**

Don't ignore! Could be:
- Actual security issue
- Man-in-the-middle attack
- Don't proceed unless you know it's safe

### "I need to use certificate on new device"

**Process:**

1. **Get certificate file:**
   - From secure backup, OR
   - Export from current device, OR
   - Request new one from administrator

2. **Install on new device:**
   - Follow installation guide for that platform
   - Same .p12 file works on multiple devices

3. **Test:**
   - Visit family website
   - Verify access works

**Exporting from current device:**

- **macOS:** Keychain Access → Right-click cert → Export
- **Windows:** certmgr.msc → Right-click cert → Export → .pfx format
- **iOS:** Cannot export easily - use backup or request new
- **Android:** Cannot export easily - use backup or request new

### "Someone is asking me to share my certificate"

**❌ NEVER share your certificate**

Even if:
- They say they're from technical support
- They claim to be the administrator
- They say it's for "verification"
- They're a family member

**Why:**
- Your certificate identifies YOU
- Sharing allows others to impersonate you
- Violates security policy

**Exception:**
- Administrator may ask you to bring device for troubleshooting
- But they should never ask to send certificate file

**What to do:**
1. Decline the request
2. Contact administrator through known trusted method
3. Report the suspicious request

---

## Privacy Implications

### What the Server Knows

When you use your certificate, the server can see:

✅ **Information from certificate:**
- Your name
- Your email
- Your permission level
- Certificate serial number

✅ **Standard web server information:**
- Pages you visit
- Time of visit
- Your IP address
- Browser type

❌ **Server CANNOT see:**
- Your passwords for other sites
- Your browsing on other websites
- Your personal files
- Your location (beyond IP address)

### Family Member Privacy

**Everyone can see:**
- You have a certificate (if administrator shares list)
- Your permission level (if administrator shares)

**Only you and administrator can see:**
- Your certificate file
- Your certificate password

**Best practices:**
- Treat family website like any private family space
- Don't share sensitive information you don't want others to see
- Remember administrators can see access logs

---

## Getting Help

### Before Contacting Administrator

Try these steps:

1. **Check this guide** - Most questions are answered here
2. **Try different browser** - Helps isolate the issue
3. **Restart device** - Solves many technical problems
4. **Check certificate expiration** - Common cause of issues

### Information to Provide

When contacting administrator, include:

- **Your name** (on certificate)
- **What you're trying to do**
- **Error message** (exact text or screenshot)
- **Device and browser** (e.g., "iPhone 13, Safari")
- **When it started** (worked before or never worked)

### Emergency Situations

**Contact administrator IMMEDIATELY if:**

1. **Device stolen/lost** with certificate installed
2. **Certificate or password compromised** (someone else has access)
3. **Suspicious certificate requests** you didn't initiate
4. **Possible security breach** or unusual activity

---

## Quick Reference

### Certificate Do's and Don'ts

| ✅ DO | ❌ DON'T |
|-------|----------|
| Keep password secret | Share certificate or password |
| Backup certificate securely | Email certificate to yourself |
| Use on personal devices only | Install on public computers |
| Approve prompts for YOUR site only | Approve random certificate prompts |
| Renew before expiration | Ignore expiration warnings |
| Contact admin if device stolen | Share certificate with family members |
| Lock devices with password/PIN | Leave devices unlocked |
| Verify website URL before approving | Click OK without reading |

### Important URLs

- Family website: `https://your-family-site.com` (use your actual URL)
- Certificate installation help: [CLIENT_INSTALLATION.md](CLIENT_INSTALLATION.md)
- Permission levels: [PERMISSIONS_GUIDE.md](PERMISSIONS_GUIDE.md)

### Contact Information

**Administrator contact:**
- [Fill in your preferred contact method]
- [Emergency contact if needed]

---

## Appendix: Technical Details (Optional)

### How Certificate Authentication Works

**Simplified process:**

1. **You visit website:**
   ```
   Browser: "Hello! I want to visit this site."
   Server: "OK, but I need to see your certificate."
   ```

2. **Certificate exchange:**
   ```
   Browser: "Here's my certificate, signed by the family CA."
   Server: "Let me verify this signature..."
   Server: "Signature valid! You are John Doe with family permissions."
   ```

3. **Access granted:**
   ```
   Server: "Welcome John! Here are the pages you can access."
   Browser: "Thanks! Displaying family pages."
   ```

4. **Encrypted communication:**
   ```
   All communication is encrypted with your certificate
   Nobody can intercept or modify the data
   ```

### Public Key Cryptography Basics

Your certificate uses **public key cryptography**:

- **Private key** (kept secret on your device)
  - Used to prove you are YOU
  - Never leaves your device
  - Like a secret signature only you can make

- **Public certificate** (server has copy)
  - Can verify your signature
  - Cannot impersonate you
  - Like your ID card - anyone can look, but not forge

**Analogy:**
```
Your private key = Secret wax seal stamp (only you have)
Your certificate = Sealed letter (anyone can verify seal is real)
```

When you visit website:
1. Server sends challenge: "Prove you're John"
2. Your browser signs challenge with private key
3. Server verifies signature using your public certificate
4. Only you could create that signature → Access granted

---

## Stay Safe!

Remember:
- 🔒 Certificate is your digital key
- 💾 Backup securely
- 🎯 Only use on trusted sites
- 📱 Protect your devices
- ⏰ Renew on time
- 🤝 Ask for help when unsure

Following these practices keeps both you and your family secure!
