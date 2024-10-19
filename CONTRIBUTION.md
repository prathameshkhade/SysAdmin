We welcome contributions from everyone! Whether it's fixing bugs, improving
documentation, or adding new features, your help is appreciated. Here's how you
can contribute:

---

# Contribution Guidelines

We’re excited that you’re interested in contributing to our project! Follow
these guidelines to make sure that your contributions are easily integrated and
that the codebase remains stable and well-maintained.

## Branching Model

We follow a **Git Flow**-inspired branching model to keep development organized:

-   **main**: The stable branch containing production-ready code.
-   **develop**: The main development branch where ongoing work happens.
-   **release**: This branch is used to prepare and release new versions of the
    app. Builds for Android and iOS are triggered by creating tags here.
-   **feature/\***: Individual branches created from `develop` for working on
    specific features or bug fixes.

## How to Contribute

Follow these steps to contribute to the project:

### 1. Fork the Repository

Start by forking the repository to your own GitHub account. This will allow you
to work on the codebase independently.

### 2. Create a Feature Branch

When you're ready to start working on a new feature or bug fix, create a new
branch from `develop`. Use the following naming convention for your branch:

-   For a new feature: `feature/your-feature-name`
-   For a bug fix: `feature/fix-your-bug-name`

Example:

```bash
git checkout develop
git checkout -b feature/add-new-feature
```

### 3. Make Your Changes

Now you're ready to code! Be sure to:

-   Keep your changes focused and avoid bundling multiple features or fixes in
    one pull request.
-   Write clear, concise commit messages that explain your changes.

Example:

```bash
git add .
git commit -m "Added new feature for managing SSH connections"
```

### 4. Push to Your Fork

Once you're satisfied with your changes, push your feature branch to your forked
repository:

```bash
git push origin feature/add-new-feature
```

### 5. Submit a Pull Request

Submit a pull request (PR) from your feature branch to the **`develop`** branch
in the main repository. Make sure your PR includes a detailed description of
your changes, any issues it addresses, and any specific notes for the reviewers.

### 6. Code Review Process

Your PR will undergo a code review by maintainers or contributors:

-   Please respond to any feedback or requested changes.
-   Once your PR is approved, it will be merged into the `develop` branch.

### 7. Post-Merge

After the feature is merged into `develop`, it will be included in the next
release. Releases are handled by the maintainers, and the `release` branch will
be updated with version tags to trigger the CI/CD pipeline for Android and iOS
builds.

## Best Practices

-   **Keep your branches up to date**: Regularly pull changes from `develop` to
    avoid conflicts.

    Example:

    ```bash
    git checkout develop
    git pull origin develop
    git checkout feature/add-new-feature
    git merge develop
    ```

-   **Write tests**: If applicable, write unit tests to cover new features or
    bug fixes.
-   **Documentation**: Update the relevant documentation if your change impacts
    usage or setup.
-   **Respect coding standards**: Follow the project’s existing coding style and
    guidelines.

## Getting Help

#### If you need help at any point, feel free to open an issue or reach out in the project discussions. We’re here to help!

<br><br>

<h1 align='center'> Thank you for contributing! We’re looking forward to your pull requests. </h1>
