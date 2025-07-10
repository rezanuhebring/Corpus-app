# Corpus: Intelligent Document Management System

![Corpus Logo](https://placehold.co/600x300/4F46E5/FFFFFF?text=Corpus&font=raleway)

**Corpus is a powerful, self-hosted document management and classification system designed for legal, corporate, and research environments. It automatically ingests documents from various sources, uses AI to classify and tag them, and provides a modern, fast, and secure web interface for searching and managing your entire document library.**

---
## ✨ Core Features
*   **💻 Multi-Source Ingestion:** A lightweight agent collects documents from local folders, server drives, and Microsoft OneDrive.
*   **🧠 Smart Categorization:** Automatically detects language (English, Bahasa) and categorizes documents using a built-in legal dictionary and trainable Machine Learning models.
*   **🗂️ Best-Practice Compliance:** Enforces legal best-practice file structures (Client-Matter model) and can automatically rename files to a standardized format on the server.
*   **⚡ Blazing-Fast Search:** Powered by Elasticsearch, allowing instant full-text search across millions of documents, filenames, metadata, and authors.
*   **🔐 Secure & Role-Based:** User and Admin roles with secure JWT authentication. Access to documents is controlled and logged.
*   **🌐 Modern Web Dashboard:** A clean, professional, and responsive dashboard built with React for managing, viewing, and analyzing your documents. Includes statistics and data visualizations.
*   **🚀 Easy Deployment:** Fully containerized with Docker and Docker Compose. A simple `setup.sh` script handles installation and configuration for both development and production environments.
*   **🔒 Automated HTTPS:** Production deployments use Nginx as a reverse proxy with free, auto-renewing SSL/TLS certificates from Let's Encrypt.
---
## 🛠️ Technology Stack
| Component         | Technology                                           |
| ----------------- | ---------------------------------------------------- |
| **Backend API**   | Python 3.10, FastAPI                                 |
| **Frontend UI**   | React.js, Material-UI (MUI)                          |
| **Database**      | Elasticsearch                                        |
| **Agent**         | Python 3                                             |
| **Web Proxy**     | Nginx                                                |
| **Containerization**| Docker, Docker Compose                             |
---
## 🚀 Getting Started
### Prerequisites
*   A server or VM running a modern Linux distribution (Ubuntu LTS recommended).
*   **Docker** and **Docker Compose** installed.
*   Git (to clone the repository).
*   For production: A registered domain name pointing to your server's public IP address.

### Installation
1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/corpus-app.git
    cd corpus-app
    ```
2.  **Make the installer executable:**
    ```bash
    chmod +x setup.sh
    ```
3.  **Run the interactive installer:**
    ```bash
    ./setup.sh
    ```
    The script will guide you through selecting either a **Development (HTTP)** or **Production (HTTPS)** setup.

### Accessing the Application
*   **Development Mode:** `http://localhost:8080`
*   **Production Mode:** `https://your-domain-name.com`
*   **Default Login:** `admin@corpus.com` / `secret`