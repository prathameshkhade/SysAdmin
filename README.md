# 🛠️ **sysAdmin** - Mobile GUI for Linux System Administrators 🖥️

<img src="assets/logo.png" alt="SysAdmin Logo">

Welcome to **sysAdmin** – a powerful mobile application built with Flutter and
Dart, designed to provide a graphical user interface for Linux system
administrators. sysAdmin enables admins to manage their Linux servers seamlessly
from their mobile devices.

## 🚀 Project Overview

**sysAdmin** is an open-source mobile application that simplifies the management
of Linux servers through an intuitive graphical interface. The application is
built to assist system administrators by offering mobile-friendly tools for
managing servers, users, and services efficiently from anywhere.

With **sysAdmin**, you can:

-   Manage user accounts and groups
-   Maintain multiple SSH connections simultaneously
-   Transfer files using SFTP
-   Manage services, view logs, and create/edit cron jobs
-   Install, update, and remove packages on your Linux server
-   Much more!

## 🎯 Scope of the Project

The primary aim of this project is to provide a **cross-platform mobile
solution** for Linux system administrators, allowing them to:

-   Access servers remotely through SSH
-   Manage users, files, and services without needing to access a terminal
    directly
-   Perform critical server management tasks on the go, from any location

This project is intended for system administrators who prefer a mobile interface
to carry out essential administrative tasks or as an alternative to using a
traditional command-line interface.

## 🛠️ How sysAdmin Solves the Problem

Traditionally, managing Linux servers requires either physical access or an SSH
session through a terminal, which may be inconvenient while on the go or for
small tasks. sysAdmin provides a **mobile GUI** for:

-   **`User and Group Management`**: Create, edit, or delete users and groups
    effortlessly from your mobile device.
-   **`SSH Management`**: Connect and manage multiple servers through SSH, all
    from one interface.
-   **`SFTP File Transfer`**: Seamlessly upload, download, and manage files on
    your server using SFTP.
-   **`Service and Log Management`**: Start, stop, or restart services and
    access system logs with just a few taps.
-   **`Cron Jobs`**: Quickly schedule and edit cron jobs with a simple
    interface.
-   **`Application Management`**: Install, update, remove, or search for
    packages on your server without hassle.

**sysAdmin** saves time by eliminating the need for terminal access for routine
tasks and provides a **visual interface** that enhances usability.

## 📦 Project Structure

```shell
lib/
│
├── core/                     # Core system-wide constants, utilities, and base classes
│   ├── constants/            # App-wide constants (colors, dimensions, strings, etc.)
│   ├── utils/                # Utility/helper functions (e.g., validators, formatters)
│   ├── theme/                # Theme and styling information
│   └── widgets/              # Shared reusable widgets across the app
│
├── data/                     # Data layer for managing data sources
│   ├── models/               # Data models representing application entities (User, SSH Connection, etc.)
│   ├── repositories/         # Abstraction of data sources (local, remote API, etc.)
│   └── services/             # Logic for handling services like network, authentication, etc.
│
├── domain/                   # Domain layer for business logic
│   ├── entities/             # Core business entities
│   ├── usecases/             # Application-specific business logic
│   └── interfaces/           # Interfaces for repositories or services
│
├── presentation/             # UI layer - Screens, Widgets, and State management
│   ├── screens/              # All major screens and pages (onboarding, dashboard, settings, etc.)
│   │   ├── onboarding/       # Screens related to onboarding
│   │   ├── dashboard/        # Main admin dashboard
│   │   ├── user_management/  # User and Group management screens
│   │   ├── ssh_management/   # SSH connections management screens
│   │   ├── sftp/             # File transfer (SFTP) management screens
│   │   └── ...               # More feature screens (logs, services, cron jobs, etc.)
│   └── widgets/              # Reusable widgets (buttons, cards, dialogs) specific to the presentation layer
│
├── providers/                # State management (e.g., Riverpod, Provider, etc.)
│   └── ssh_state.dart        # Global application state (loading, session, etc.)
│
├── routes/                   # Application navigation and routing
│   └── app_routes.dart       # App's route definitions and navigators
│
├── config/                   # Environment-based configurations
│   ├── env/                  # Separate config files for dev, staging, production
│   └── app_config.dart       # Main configuration file
│
└── main.dart                 # App entry point
```

### Explanation of Key Folders:

-   **`core/`**: Contains essential elements like constants, themes, and
    reusable widgets that are used across the app.

-   **`data/`**: Manages all data-related functionalities such as models,
    repositories, and services (like networking or local storage). For instance,
    models for user accounts, SSH connections, and other entities reside here.

-   **`domain/`**: Focuses on the business logic layer, separating concerns and
    following clean architecture principles. This ensures scalability for future
    features.

-   **`presentation/`**: Deals with the UI aspect of your app, including the
    various screens and reusable UI components specific to each feature.

-   **`providers/`**: Handles the state management system, ensuring that the
    app’s state is efficiently managed (whether you use Riverpod, Provider, or
    another state management tool).

-   **`routes/`**: Manages the navigation logic, defining how the app moves
    between different screens.

-   **`config/`**: Stores configuration settings for different environments
    (development, production, etc.).

This structure will ensure that your app remains maintainable and scalable as
the project grows with additional features.

## 🌟 Features

-   **User and Group Management**: Add, remove, or update user groups and
    accounts on the server.
-   **SSH Management**: Connect to multiple servers simultaneously and manage
    SSH connections.
-   **SFTP Support**: Upload, download, and manage files with SFTP
    functionality.
-   **Service Management**: Start, stop, or restart server services with ease.
-   **Log Viewing**: View system logs for troubleshooting and monitoring server
    health.
-   **Cron Job Management**: Create and manage scheduled tasks (cron jobs) with
    a user-friendly interface.
-   **Application Management**: Manage installed packages on the server.

## 💡 Getting Started

### Prerequisites

-   [Flutter](https://flutter.dev/docs/get-started/install) installed on your
    system.
-   A Linux server with SSH access for testing.
-   Basic knowledge of Dart and Flutter.

### Installation

1. **Clone the Repository**:

    ```bash
    git clone https://github.com/prathameshkhade/sysAdmin.git
    cd sysAdmin
    ```

2. **Install Dependencies**:

    ```bash
    flutter pub get
    ```

3. **Run the Application**:
    ```bash
    flutter run
    ```

## 🛠️ Contribution Guidelines

Follow this [Contribution Guideline](CONTRIBUTION.md) to contribute in this project.

## 🔧 Future Roadmap

We are actively working on the following features:

-   **Server Health Monitoring:** Add server CPU, memory, and disk monitoring.
-   **Real-Time Notifications:** Receive real-time alerts for server issues.
-   **Custom Server Scripts:** Add the ability to run custom shell scripts via
    the mobile app.
-   **Process Management:** View, start, stop, and terminate running processes.
-   **Disk Management:** View, format, partition, and mount disks.
-   **Backup and Restore:** Create and restore system backups.
<!-- -   **Multilingual Support**: Add localization for more languages. -->

> [!TIP] > **Feel free to suggest new features by opening a GitHub issue!**

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file
for details.

## 🛡️ Security

If you discover any security vulnerabilities, please report them directly to the
repository maintainer. All security vulnerabilities will be promptly addressed.

## 📞 Contact

Feel free to reach out via GitHub issues or by emailing us at
[pkhade2865+sysadmin@gmail.com](mailto:your-pkhade2865+sysadmin@gmail.com).

---

# We hope this project makes Linux server management more accessible and efficient for system administrators on the go! 🚀
