#!/bin/bash
# This script must be run as a non-root user with sudo privileges.
# It will automatically use 'sudo' when needed for installations.
set -e

echo "Welcome to the Corpus App Installer!"
echo "===================================="
echo "This script will check for dependencies, install them if necessary,"
echo "and set up the application."
echo

# --- Helper Function to Check for Commands ---
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- This function handles all Docker-related setup ---
ensure_docker_is_ready() {
    # 1. CHECK IF DOCKER COMMAND EXISTS
    if ! command_exists docker; then
        echo "Docker command not found. Beginning installation of Docker Engine..."
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        echo "✅ Docker Engine and Compose Plugin installed."
    else
        echo "✅ Docker command found."
    fi

    # 2. ENSURE DOCKER GROUP EXISTS
    if ! getent group docker > /dev/null; then
        echo "Docker group not found. Creating it..."
        sudo groupadd docker
        echo "✅ Docker group created."
    fi

    # 3. ENSURE CURRENT USER IS IN THE DOCKER GROUP
    if ! id -nG "$USER" | grep -qw "docker"; then
        echo "User '$USER' is not in the 'docker' group. Adding..."
        sudo usermod -aG docker "$USER"
        echo
        echo "----------------------------- CRITICAL -----------------------------"
        echo "You have been added to the 'docker' group."
        echo "For this change to take effect, you MUST log out and log back in."
        echo "The most reliable method is to REBOOT the system:"
        echo
        echo "    sudo reboot"
        echo
        echo "After rebooting, please re-run this script."
        echo "--------------------------------------------------------------------"
        exit 1
    fi

    # 4. FINAL PERMISSION CHECK: Can we actually connect to the Docker socket?
    if ! docker info >/dev/null 2>&1; then
        echo
        echo "----------------------------- CRITICAL ERROR -----------------------------"
        echo "❌ Cannot connect to the Docker daemon. Your session is 'stale'."
        echo "Even though you are in the 'docker' group, your current terminal"
        echo "session does not have the correct permissions yet."
        echo
        echo "SOLUTION: Log out and log back in, or reboot the system."
        echo "          A reboot ('sudo reboot') is the most definitive fix."
        echo
        echo "TEMPORARY FIX for this session only: Run 'newgrp docker' and"
        echo "then re-run this script in the new shell that appears."
        echo "--------------------------------------------------------------------"
        exit 1
    fi
}

# --- Main Script Execution ---

# Run the comprehensive Docker check and setup function first.
ensure_docker_is_ready

echo "✅ Docker is installed and permissions are correctly configured."
echo

# Create environment file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "Creating .env file from template..."
    cp .env.template .env
    echo "Generating a new secret key..."
    SECRET_KEY=$(openssl rand -hex 32)
    sed -i "s/^SECRET_KEY=.*/SECRET_KEY=${SECRET_KEY}/" .env
else
    echo ".env file already exists. Skipping creation."
fi

# Ask for installation mode
echo
PS3='Please select an installation mode: '
options=("Development (HTTP)" "Production (HTTPS with Let's Encrypt)")
select opt in "${options[@]}"
do
    case $opt in
        "Development (HTTP)")
            echo "Setting up for Development mode..."
            cp nginx/nginx.dev.conf.template nginx/default.conf
            MODE="dev"
            break
            ;;
        "Production (HTTPS with Let's Encrypt)")
            echo "Setting up for Production mode..."
            read -p "Enter your domain name (e.g., corpus.yourcompany.com): " DOMAIN
            read -p "Enter your email address (for Let's Encrypt renewal): " EMAIL

            if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
                echo "Domain and Email are required for production setup. Aborting."
                exit 1
            fi

            sed -i "s/^CORPUS_DOMAIN=.*/CORPUS_DOMAIN=${DOMAIN}/" .env
            sed -i "s/^CERTBOT_EMAIL=.*/CERTBOT_EMAIL=${EMAIL}/" .env

            echo "Configuring Nginx for domain: ${DOMAIN}"
            cp nginx/nginx.prod.conf.template nginx/default.conf
            sed -i "s/YOUR_DOMAIN_NAME/${DOMAIN}/g" nginx/default.conf

            echo "Initializing Let's Encrypt certificate..."
            docker compose up -d nginx
            docker compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot -d ${DOMAIN} --email ${EMAIL} --rsa-key-size 4096 --agree-tos --non-interactive --force-renewal
            docker compose down

            MODE="prod"
            break
            ;;
        *) echo "Invalid option $REPLY";;
    esac
done

echo
echo "Setup complete. Building and starting containers..."
echo "This might take several minutes..."

# Using modern 'docker compose' syntax
docker compose build
docker compose up -d

echo
echo "✅ Corpus App has been successfully deployed!"
if [ "$MODE" = "dev" ]; then
    echo "Access the dashboard at: http://localhost:8080"
else
    echo "Access the dashboard at: https://${DOMAIN}"
fi
echo "You can manage the services using 'docker compose [up|down|logs]'"