# Contributing to SysAdmin

<div align="center">

<div align="center" style="background-color: #1A1B1E; border-radius: 25px; padding: 20px; width: 200px; height: 200px; display: flex; justify-content: center; align-items: center; margin-left: auto; margin-right: auto;">
   <picture>
      <img width="200" src="assets/LogoRound.png" alt="SysAdmin Logo" />
   </picture>
</div>

<br>

*Put the power of Linux administration in everyone's pocket*

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![Open Source Love](https://badges.frapsoft.com/os/v1/open-source.svg?v=103)](https://opensource.org/)
[![Good First Issues](https://img.shields.io/github/issues/prathameshkhade/SysAdmin/good%20first%20issue.svg)](https://github.com/prathameshkhade/SysAdmin/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22)

</div>

Thank you for considering contributing to SysAdmin! This document explains our development process and how you can be part of improving Linux server management for mobile users worldwide.

## 📋 Table of Contents

- [Contributing to SysAdmin](#contributing-to-sysadmin)
  - [📋 Table of Contents](#-table-of-contents)
  - [🤝 Code of Conduct](#-code-of-conduct)
  - [🚀 Getting Started](#-getting-started)
    - [Prerequisites](#prerequisites)
    - [Setup Your Development Environment](#setup-your-development-environment)
  - [🔄 Development Workflow](#-development-workflow)
  - [🌿 Branching Strategy](#-branching-strategy)
    - [Branch Flow](#branch-flow)
    - [Creating a New Branch](#creating-a-new-branch)
  - [📥 Pull Request Process](#-pull-request-process)
  - [🚀 Release Process](#-release-process)
    - [Semantic Versioning](#semantic-versioning)
  - [💻 Development Guidelines](#-development-guidelines)
    - [Code Style](#code-style)
    - [Architecture](#architecture)
  - [📚 Documentation](#-documentation)
  - [🧪 Testing](#-testing)
  - [👥 Community](#-community)
    - [Getting Help](#getting-help)
  - [✨ Thank You ✨](#-thank-you-)

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

   Start by forking the SysAdmin repository to your GitHub account. This creates your own copy of the project to work on.

2. **Clone Your Fork**

   ```bash
   git clone https://github.com/YOUR-USERNAME/SysAdmin.git
   cd SysAdmin
   ```

3. **Add the Upstream Remote**

   ```bash
   git remote add upstream https://github.com/prathameshkhade/SysAdmin.git
   ```

4. **Create a local dev branch that tracks upstream/dev**

   ```bash
   git fetch upstream
   git checkout -b dev upstream/dev
   ```

5. **Install Dependencies**

   ```bash
   flutter pub get
   ```

6. **Run the App**

   ```bash
   flutter run
   ```

## 🔄 Development Workflow

1. **Find an Issue or Create One**

    - Browse through existing [issues](https://github.com/prathameshkhade/SysAdmin/issues)
    - Look for issues labeled `good first issue` if you're new to the project
    - If you want to work on something not listed, create a new issue describing the feature or bug

2. **Discuss the Implementation**

    - For significant changes, discuss your approach in the issue before starting work
    - This ensures your time is well spent and your contribution aligns with the project's direction

3. **Implement Your Changes**

    - Create a feature branch from the `dev` branch (not from `main`)
    - Write clean, maintainable code
    - Follow the existing code style and patterns
    - Include comments where necessary

4. **Submit Your Contribution**

    - Create a pull request from your branch to the `dev` branch (not to `main`)
    - Respond to review feedback
    - Once approved, your changes will be merged into `dev`!

## 🌿 Branching Strategy

We follow a branching model with two primary branches:

| Branch | Purpose |
|--------|---------|
| `main` | Production-ready code only. Stable releases are deployed from this branch. |
| `dev` | Development branch where all feature branches are merged first for integration testing. |

Feature branches are based on specific types of work:

| Branch Type | Purpose | Naming Convention |
|------------|---------|-------------------|
| `feat/*` | New features or enhancements | `feat/descriptive-feature-name` |
| `bugfix/*` | Non-critical bug fixes | `bugfix/descriptive-bug-name` |
| `hotfix/*` | Critical fixes that need immediate release | `hotfix/descriptive-issue-name` |
| `docs/*` | Documentation changes | `docs/what-you-documented` |

### Branch Flow

```
    main
     |
     |__________
     |          \
     |           \
     v            v
    dev         hotfix/*
     |             |
     |             |
  /  |  \          |
 /   |   \         |
v    v    v        v
feat/* bugfix/* docs/*
```

- Regular development work is done on feature branches (`feat/*`, `bugfix/*`, `docs/*`) from `dev`
- All feature branches are merged back to `dev`
- When `dev` is stable, it gets merged to `main` for release
- Critical fixes may be done on `hotfix/*` branches from `main`, then merged to both `main` and `dev`

### Creating a New Branch

```bash
# Make sure your dev branch is up to date
git checkout dev
git pull upstream dev

# Create and switch to a new branch
git checkout -b feat/your-feature-name
```

## 📥 Pull Request Process

1. **Update Your Branch**

   Ensure your branch is up to date with the latest changes:

   ```bash
   git checkout dev
   git pull upstream dev
   git checkout feat/your-feature-name
   git merge dev
   ```

2. **Run Tests Locally**

   Before submitting, run tests to ensure your changes don't break existing functionality:

   ```bash
   flutter analyze
   flutter test
   ```

3. **Push Your Changes**

   ```bash
   git push origin feat/your-feature-name
   ```

4. **Create a Pull Request**

    - Go to the repository on GitHub
    - Click "Pull Request"
    - Choose `dev` as the base branch and your feature branch as the compare branch
    - Fill out the PR template with details about your changes

5. **PR Title and Description**

    - Use a clear, descriptive title that summarizes your changes
    - In the description, explain what the PR does, why it's needed, and how it's implemented
    - Link any related issues using keywords like "Fixes #123" or "Closes #456"

6. **Code Review**

    - Be responsive to feedback and make requested changes
    - Push additional commits to address review comments
    - Maintain a positive and collaborative attitude

7. **Merge**

   Once your PR is approved and all checks pass, a maintainer will merge it into the `dev` branch.

## 🚀 Release Process

Our release process follows these steps:

1. **Integration in `dev`**
   - All feature branches are merged into `dev`
   - Comprehensive testing is performed on the `dev` branch

2. **Version Update**
   - When `dev` is stable and ready for release, the maintainer:
     - Updates the version in `pubspec.yaml` following semantic versioning
     - Updates the version code in `pubspec.yaml`

3. **Release Branch Creation**
   - The maintainer merges `dev` into `main`

4. **Automated Release**
   - The GitHub workflow in `.github/workflows/main.yml` builds and publishes releases when changes are pushed to `main`
   - This creates a new tag and GitHub release with Android and iOS builds

5. **Hotfix Process**
   - For critical issues:
     - Create a `hotfix/*` branch from `main`
     - Fix the issue and create a PR to `main`
     - After merging to `main`, create another PR to merge the hotfix into `dev`

### Semantic Versioning

We follow [Semantic Versioning](https://semver.org/) for releases:

- **MAJOR.MINOR.PATCH** (e.g., 1.2.3)
- Increment MAJOR for incompatible API changes
- Increment MINOR for new features in a backward-compatible manner
- Increment PATCH for backward-compatible bug fixes

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

Our CI workflow automatically runs tests for all PRs to the `main` branch.

## 👥 Community

- **GitHub Discussions**: For questions, ideas, and community chat
- **Issues**: For bugs and feature requests
- **Pull Requests**: For code contributions

### Getting Help

If you need help at any point:

- Ask in the [GitHub Discussions](https://github.com/prathameshkhade/SysAdmin/discussions)
- Comment on the relevant issue
- Reach out via email: [pkhade2865+sysadmin@gmail.com](mailto:pkhade2865+sysadmin@gmail.com)

---

<div align="center">

## ✨ Thank You ✨

**Your contributions make this project better for everyone!**

Whether it's code, documentation, bug reports, or feature ideas - every contribution counts.

</div>