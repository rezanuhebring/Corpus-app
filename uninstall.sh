#!/bin/bash
set -e

echo "Corpus App Uninstaller"
echo "======================"
echo
echo "WARNING: This script will permanently delete all Corpus application containers,"
echo "         networks, and data volumes, including:"
echo "         - The Elasticsearch database (all indexed documents)"
echo "         - All stored original document files"
echo "         - SSL/TLS certificates from Let's Encrypt"
echo
echo "This action cannot be undone."
echo

# Confirmation prompt
read -p "Are you sure you want to proceed? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 1
fi

echo "Stopping and removing containers..."
# The --volumes flag is crucial. It removes the named volumes defined in docker-compose.yml
# The -v flag is an alias for --volumes.
docker compose down --volumes

echo
echo "Pruning unused Docker assets to clean up..."
# This command is safe and removes dangling images, build caches, and unused networks.
docker system prune -f

echo
read -p "Do you also want to remove the specific Corpus Docker images (corpus-backend, corpus-frontend, etc.)? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing Corpus-specific Docker images..."
    # The image names are based on the directory name by default: 'corpus-app-backend', etc.
    # We use a wildcard to catch them all safely.
    docker rmi $(docker images 'corpus-app-*' -q) 2>/dev/null || echo "No Corpus-specific images found to remove."
    echo "Images removed."
fi

echo
echo "✅ Corpus application has been successfully uninstalled."
echo "The project folder 'corpus-app' has not been deleted. You can remove it manually with 'rm -rf corpus-app'."