#!/bin/bash
set -e

echo "Welcome to the Corpus App Installer!"
echo "===================================="

# Check for dependencies
if ! [ -x "$(command -v docker)" ]; then
  echo >&2 "Error: Docker is not installed. Please install Docker and run this script again."
  exit 1
fi
if ! [ -x "$(command -v docker-compose)" ]; then
  echo >&2 "Error: docker-compose is not installed. Please install it and run this script again."
  exit 1
fi

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
            # We need to run a temporary Nginx to solve the ACME challenge
            docker-compose up -d nginx
            docker-compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot -d ${DOMAIN} --email ${EMAIL} --rsa-key-size 4096 --agree-tos --non-interactive --force-renewal
            docker-compose down # Stop the temporary Nginx

            MODE="prod"
            break
            ;;
        *) echo "Invalid option $REPLY";;
    esac
done

echo
echo "Setup complete. Building and starting containers..."
echo "This might take several minutes..."

docker-compose build
docker-compose up -d

echo
echo "✅ Corpus App has been successfully deployed!"
if [ "$MODE" = "dev" ]; then
    echo "Access the dashboard at: http://localhost:8080"
else
    echo "Access the dashboard at: https://${DOMAIN}"
fi
echo "You can manage the services using 'docker-compose [up|down|logs]'"