#!/bin/bash
set -e

echo "Welcome to the Corpus App Installer!"
echo "===================================="
echo "This script will check for dependencies and set up the application."

# --- Helper Function to Check for Commands ---
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Docker Installation Logic ---
install_docker() {
    echo "Docker not found. Starting installation..."
    echo "You will be prompted for your password to install packages."
    
    # 1. Set up the repository
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
    
    # 2. Install Docker Engine, CLI, Containerd, and Compose plugin
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo "✅ Docker installation complete."
    
    # 3. Add current user to the docker group
    if ! getent group docker | grep -q "\b$USER\b"; then
        echo "Adding current user ($USER) to the 'docker' group..."
        sudo usermod -aG docker $USER
        echo "--------------------------------------------------------------------"
        echo "IMPORTANT: You must log out and log back in for the group"
        echo "           changes to take effect."
        echo "           After logging back in, please re-run this script."
        echo "--------------------------------------------------------------------"
        exit 1
    fi
}

# --- Main Script ---

# Check for Docker and Docker Compose
if ! command_exists docker || ! docker compose version >/dev/null 2>&1; then
    install_docker
fi

# If we get here, Docker is installed and the user has permissions.
echo "✅ Docker and Docker Compose are installed and configured."

# Create environment file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "Creating .env file from template..."
    cp .env.template .env
    # Generate a strong secret key for JWT
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

            # Update .env file
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