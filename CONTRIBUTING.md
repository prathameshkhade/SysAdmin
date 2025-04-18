# Contributing to sysAdmin

<div align="center">

![Contributing Banner](assets/LogoRound.png)

*Put the power of Linux administration in everyone's pocket*

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![Open Source Love](https://badges.frapsoft.com/os/v1/open-source.svg?v=103)](https://opensource.org/)
[![Good First Issues](https://img.shields.io/github/issues/prathameshkhade/sysAdmin/good%20first%20issue.svg)](https://github.com/prathameshkhade/sysAdmin/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22)

</div>

Thank you for considering contributing to sysAdmin! This document explains our development process and how you can be part of improving Linux server management for mobile users worldwide.

## 📋 Table of Contents

- [Code of Conduct](#-code-of-conduct)
- [Getting Started](#-getting-started)
- [Development Workflow](#-development-workflow)
- [Branching Strategy](#-branching-strategy)
- [Pull Request Process](#-pull-request-process)
- [Development Guidelines](#-development-guidelines)
- [Documentation](#-documentation)
- [Testing](#-testing)
- [Community](#-community)

## 🤝 Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for everyone. Please be kind, constructive, and patient with other community members.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio or VS Code with Flutter extensions
- Git

### Setup Your Development Environment

1. **Fork the Repository**

   Start by forking the sysAdmin repository to your GitHub account. This creates your own copy of the project to work on.

2. **Clone Your Fork**

   ```bash
   git clone https://github.com/YOUR-USERNAME/sysAdmin.git
   cd sysAdmin
   ```

3. **Add the Upstream Remote**

   ```bash
   git remote add upstream https://github.com/prathameshkhade/sysAdmin.git
   ```

4. **Install Dependencies**

   ```bash
   flutter pub get
   ```

5. **Run the App**

   ```bash
   flutter run
   ```

## 🔄 Development Workflow

1. **Find an Issue or Create One**

    - Browse through existing [issues](https://github.com/prathameshkhade/sysAdmin/issues)
    - Look for issues labeled `good first issue` if you're new to the project
    - If you want to work on something not listed, create a new issue describing the feature or bug

2. **Discuss the Implementation**

    - For significant changes, discuss your approach in the issue before starting work
    - This ensures your time is well spent and your contribution aligns with the project's direction

3. **Implement Your Changes**

    - Write clean, maintainable code
    - Follow the existing code style and patterns
    - Include comments where necessary

4. **Submit Your Contribution**

    - Create a pull request from your branch to the `develop` branch
    - Respond to review feedback
    - Once approved, your changes will be merged!

## 🌿 Branching Strategy

We follow a Git Flow-inspired branching model:

| Branch | Purpose |
|--------|---------|
| `main` | Production-ready code, stable releases |
| `develop` | Main development branch where ongoing work happens |
| `release/*` | Preparation for new releases, triggers builds when tagged |
| `feature/*` | Individual feature development or bug fixes |

### Branch Naming

- **New Feature**: `feature/descriptive-feature-name`
- **Bug Fix**: `feature/fix-descriptive-bug-name`
- **Documentation**: `feature/docs-what-you-documented`

### Creating a New Branch

```bash
# Make sure your develop branch is up to date
git checkout develop
git pull upstream develop

# Create and switch to a new branch
git checkout -b feature/your-feature-name
```

## 📥 Pull Request Process

1. **Update Your Branch**

   Ensure your branch is up to date with the latest changes:

   ```bash
   git checkout develop
   git pull upstream develop
   git checkout feature/your-feature-name
   git merge develop
   ```

2. **Push Your Changes**

   ```bash
   git push origin feature/your-feature-name
   ```

3. **Create a Pull Request**

    - Go to the repository on GitHub
    - Click "Pull Request"
    - Choose `develop` as the base branch and your feature branch as the compare branch
    - Fill out the PR template with details about your changes

4. **PR Title and Description**

    - Use a clear, descriptive title that summarizes your changes
    - In the description, explain what the PR does, why it's needed, and how it's implemented
    - Link any related issues using keywords like "Fixes #123" or "Closes #456"

5. **Code Review**

    - Be responsive to feedback and make requested changes
    - Push additional commits to address review comments
    - Maintain a positive and collaborative attitude

6. **Merge**

   Once your PR is approved, a maintainer will merge it into the `develop` branch.

## 💻 Development Guidelines

### Code Style

- Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Write self-documenting code where possible
- Keep functions focused and concise
- Use Flutter best practices for UI components

### Architecture

- Maintain the project structure as outlined in the README
- Follow the established patterns for state management
- Separate UI from business logic
- Create reusable components when appropriate

## 📚 Documentation

Good documentation is crucial for an open-source project:

- Update the README.md if you add or change features
- Add comments to complex code sections
- Include dartdoc comments for public APIs
- Consider updating Wiki pages for major features

## 🧪 Testing

We encourage a test-driven development approach:

- Write unit tests for business logic
- Add widget tests for UI components
- Ensure all tests pass before submitting a PR
- Run `flutter test` to verify

## 👥 Community

- **GitHub Discussions**: For questions, ideas, and community chat
- **Issues**: For bugs and feature requests
- **Pull Requests**: For code contributions

### Getting Help

If you need help at any point:

- Ask in the [GitHub Discussions](https://github.com/prathameshkhade/sysAdmin/discussions)
- Comment on the relevant issue
- Reach out via email: [pkhade2865+sysadmin@gmail.com](mailto:pkhade2865+sysadmin@gmail.com)

---

<div align="center">

## ✨ Thank You

**Your contributions make this project better for everyone!**

Whether it's code, documentation, bug reports, or feature ideas - every contribution counts.

</div>