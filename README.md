<div align="center">

# 🎴 Cross-Platform Flashcard Application

**An enterprise-grade, containerized vocabulary engine built with Flutter & Dart.**

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Dev Containers](https://img.shields.io/badge/Dev_Containers-2496ED?style=for-the-badge&logo=visualstudiocode&logoColor=white)](https://code.visualstudio.com/docs/devcontainers/containers)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

[Architecture](#-tech-stack--architecture) •
[Development Environment](#-containerized-development-environment) •
[Getting Started](#-getting-started) •
[Troubleshooting](#-troubleshooting)

</div>

---

## ⚡ Overview

A modern, high-performance Flashcard application engineered for scalable multi-platform deployment. Built with a declarative UI architecture in Flutter, the application provides a smooth, cross-device experience while maintaining complete environment isolation for developers through Docker containerization.

---

## 🛠️ Tech Stack & Architecture

### Core Technologies
* **[Flutter](https://flutter.dev/)**: Reactive, cross-platform UI framework compiling directly to native machine code (ARM64) and optimized web targets.
* **[Dart](https://dart.dev/)**: Sound null-safe, object-oriented language utilizing Ahead-Of-Time (AOT) compilation for production and Just-In-Time (JIT) compilation for rapid hot reloads.
* **[Docker Engine](https://www.docker.com/)**: Containerization layer providing OS-level virtualization to execute the Flutter SDK inside a sandboxed Linux runtime.
* **[VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers)**: Workspace orchestration protocol enabling seamless extension forwarding, LSP (Language Server Protocol) binding, and isolated terminal execution directly within the container.

### Architectural Highlights
* **Zero Host Contamination**: The entire toolchain (Dart SDK, Flutter SDK, C++ build tools) resides exclusively within the Docker volume.
* **Deterministic Builds**: Locked dependency trees (`pubspec.lock`) combined with pinned container images eliminate target-environment drift across engineering teams.
* **CanvasKit & HTML Web Renderers**: Configured to utilize optimized rendering engines for browser targets.

---

## 🐋 Containerized Development Environment

This repository utilizes `.devcontainer` specs to automatically configure an identical, isolated development container for all contributors.

### Environment Specifications
* **Base OS**: Debian GNU/Linux (Containerized)
* **Pre-configured Extensions**: Flutter, Dart, C/C++, YAML tooling
* **Network Binding**: Auto-mapped ports for live-reloading web services (`:8080`)

---

## 🚀 Getting Started

### Prerequisites

Ensure the following system dependencies are running on your host machine:

* **[Git](https://git-scm.com/)** (v2.30+)
* **[Docker Desktop](https://www.docker.com/products/docker-desktop/)** (v4.0+)
* **[VS Code](https://code.visualstudio.com/)** with the **[Dev Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)**

---

### Quickstart Guide

#### 1. Clone the Repository
```bash
git clone https://github.com/your-username/my_flashcard_app.git
cd my_flashcard_app
```

### Firebase display names

Email account names are reserved case-insensitively in Firestore. Guest names
are not reserved, but a guest must choose an available name when linking an
email account. Existing email account names are reserved the next time the
account signs in; if a name is already claimed, the account needs to choose a
different one. Guests are local-only: progress and guest names stay in local
device storage, with no Firebase Auth session, Firestore writes, or Storage
uploads. Email-linked accounts sync progress to Firestore and store profile
pictures as a selected built-in avatar ID in Firestore. Avatar images are local
assets and do not require Firebase Storage or a paid Storage plan. A device keeps one guest profile; when a saved
guest exists, the user can resume it or replace it with a new guest and discard
the old guest progress. Linked-account progress is cached separately and the
local cache is removed on sign-out; Firebase data remains. Unlinking requires
name and password, removes the Firebase Auth account, progress document,
avatar selection, and reserved name, then temporarily exposes that account's
local progress in guest mode. Logging out of that unlinked session deletes its
local cache while leaving the separately saved guest profile intact. Linking a
different email before logging out carries the current unlinked progress to
that new linked account; it never replaces the device's saved guest progress.

On Web, guest data is stored by the browser for the exact site origin. Use the
VS Code launch profile **Flashcard (Web, persistent guest storage)** to keep
local development on port `8080`; changing the hostname or port, using private
browsing, or clearing site data makes the saved guest unavailable.
Web guest profiles remain saved but start signed out after each app launch, and
Firebase email sessions use session persistence so closing the browser session
signs them out.

Deploy the Firestore rules before using name reservations:

```bash
cd my_flashcard_app
firebase deploy --only firestore:rules
```

Linked accounts can look up another linked user's statistics by display name.
Stats privacy defaults to **Cloaked**. Users can choose **Open** with a
blacklist, **Restricted** with a whitelist, or **Cloaked**. Viewer lists use
unique account display names. Only linked accounts can use the lookup feature;
guest sessions remain local-only. Deploy the Firestore rules after changing
privacy or stats access rules.
