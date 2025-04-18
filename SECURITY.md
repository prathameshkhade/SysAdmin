# Security Policy

## 🔒 Security Philosophy

At sysAdmin, security is foundational to our mission. We prioritize the protection of our users' data and servers by following industry best practices for secure coding, credential management, and data protection. Since our application handles sensitive server credentials and operations, we take security extremely seriously.

## 🛡️ Supported Versions

Only the most recent version of sysAdmin receives security updates. We strongly recommend all users to update to the latest release as soon as available.

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |
| < latest| :x:                |

## 🐛 Reporting a Vulnerability

We appreciate the work of security researchers and the responsible disclosure of security vulnerabilities. If you discover a security issue in sysAdmin, please follow these guidelines:

### How to Report

1. **Do NOT create a public GitHub issue** for security vulnerabilities
2. Email your findings to [pkhade2865+sysadmin-security@gmail.com](mailto:pkhade2865+sysadmin-security@gmail.com)
3. Include detailed information about the vulnerability:
   - Description of the issue
   - Steps to reproduce
   - Potential impact
   - Any suggested mitigations (if available)
4. If possible, provide proof of concept code or screenshots that demonstrate the vulnerability

### What to Expect

- **Initial Response:** We aim to acknowledge receipt of your report within 48 hours
- **Updates:** You will receive updates on the progress of your report within 7 days
- **Resolution:** We will work diligently to verify and fix the issue as quickly as possible
- **Disclosure:** We practice coordinated disclosure and will work with you to determine an appropriate timeline for public disclosure after the issue is fixed

### Recognition

We believe in acknowledging security researchers who help improve our security:

- Researchers who report valid security vulnerabilities will be credited (with their permission) in our release notes and security advisories
- We may establish a security hall of fame on our GitHub repository for significant contributions

## 🧰 Application Security Features

sysAdmin implements several security measures to protect user data:

### Credential Storage

- All SSH credentials and keys are stored in the device's secure storage using the `flutter_secure_storage` package
- Credentials are never transmitted to external servers or services
- Private keys are handled securely in memory and cleared after use

### Communications Security

- All communications with Linux servers are encrypted using SSH protocols
- We use industry-standard SSH/SFTP libraries (dartssh2) with secure cipher suites
- The application does not implement custom cryptographic solutions

### Local Authentication

- Local device authentication (biometric/PIN) is required before accessing stored credentials
- The app implements session timeouts to protect against unauthorized access

### Permission Model

- The application requests only the minimum required device permissions necessary for operation
- File access is limited to designated directories for uploading/downloading files

## 📋 Security Best Practices for Users

We recommend the following security practices for users:

1. **Use SSH Keys** instead of passwords when possible
2. **Enable Device Lock** on your mobile device
3. **Regularly Update** the sysAdmin application to the latest version
4. **Avoid Public Networks** when managing sensitive servers
5. **Use Restricted Users** with limited privileges for routine server management
6. **Enable Timeout** settings in the app to automatically log out after inactivity
7. **Verify Server Fingerprints** when establishing new connections
8. **Don't Root/Jailbreak** devices used for server management

## 🔄 Security Development Lifecycle

Our development process includes:

1. **Design Reviews** for security implications of new features
2. **Static Analysis** of code to identify potential vulnerabilities
3. **Dependency Scanning** to identify and update vulnerable dependencies
4. **Manual Code Reviews** with specific focus on security aspects
5. **Testing** for common security vulnerabilities

## 📑 Compliance & Standards

While sysAdmin is not currently certified against security standards, we strive to follow best practices from:

- OWASP Mobile Security Project guidelines
- Google's Mobile Application Security Verification Standard (MASVS)
- Flutter security best practices

---

This security policy will be updated periodically as our security practices evolve. Last updated: April 18, 2025.