# Corpus: Intelligent Document Management System

![Corpus Logo](https://placehold.co/600x300/4F46E5/FFFFFF?text=Corpus&font=raleway)
*(Replace the placeholder image with a real logo)*

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

## 🏛️ Architecture Overview

Corpus is built on a modern microservices architecture, ensuring scalability and maintainability.

![Architecture Diagram](https://placehold.co/800x400/FFFFFF/000000?text=Agent+->+API+->+Elasticsearch+<->+Dashboard)
*(Replace with a real architecture diagram)*

*   **Corpus-Agent:** A Python-based agent that monitors file systems and sends new/modified documents.
*   **Corpus-API (Backend):** A FastAPI (Python) application that handles ingestion, processing, classification, and serves data to the dashboard.
*   **Corpus-Dashboard (Frontend):** A React.js single-page application that provides the user interface.
*   **Database:** Elasticsearch for powerful full-text search and document storage.
*   **Reverse Proxy:** Nginx for routing traffic and handling SSL/TLS.

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
| **Host OS**       | Ubuntu (Latest LTS recommended)                      |
| **SSL/TLS**       | Let's Encrypt (managed by Certbot)                   |

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
    The script will guide you through selecting either a **Development (HTTP)** or **Production (HTTPS)** setup. For production, you will be prompted for your domain name and email address.

4.  **Wait for the process to complete.** The script will configure everything, build the Docker images, and start all the services.

### Accessing the Application

*   **Development Mode:** `http://localhost:8080` (or your server's IP address if not local).
*   **Production Mode:** `https://your-domain-name.com`

---

## ⚙️ Usage & Configuration

### Environment Variables

All configuration is managed in the `.env` file, which is created by the `setup.sh` script from `.env.template`. Key variables include:

*   `SECRET_KEY`: A randomly generated key for securing user sessions.
*   `ELASTICSEARCH_HOST`: The internal hostname for the Elasticsearch service.
*   `CORPUS_DOMAIN`: Your public domain name (production only).
*   `CERTBOT_EMAIL`: Your email for Let's Encrypt notifications (production only).

### Managing Services

You can manage the running containers using standard Docker Compose commands from the `corpus-app` directory:

*   **Stop all services:** `docker-compose down`
*   **Start all services:** `docker-compose up -d`
*   **View logs for a specific service:** `docker-compose logs -f backend`

---

## 🤝 Contributing

We welcome contributions! Please feel free to fork the repository, make changes, and submit a pull request. For major changes, please open an issue first to discuss what you would like to change.

## 📄 License

This project is licensed under the MIT License - see the `LICENSE` file for details.
