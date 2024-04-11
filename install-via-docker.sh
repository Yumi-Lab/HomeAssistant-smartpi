#!/bin/bash

# Docker Installation
echo "1. Installation de Docker..."
sudo apt-get install -y docker.io

# Vérification de l'installation Docker
echo "2. Vérification de l'installation Docker..."
sudo systemctl start docker
sudo systemctl enable docker
docker --version

# Installation d'AppArmor
echo "Installation d'AppArmor..."
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y apparmor

# Vérification de l'installation d'AppArmor
echo "Vérification de l'installation d'AppArmor..."
if [ -x "$(command -v apparmor_parser)" ]; then
    echo "AppArmor est installé et accessible."
else
    echo "AppArmor n'est pas installé correctement. Tentative d'installation..."
    # Tentative d'installation d'AppArmor
    # La commande varie selon la distribution Linux
    # Pour Debian/Ubuntu :
    sudo apt-get update && sudo apt-get install -y apparmor apparmor-utils

    # Vérifier de nouveau après l'installation
    if [ -x "$(command -v apparmor_parser)" ]; then
        echo "AppArmor a été installé avec succès."
    else
        echo "Échec de l'installation d'AppArmor. Veuillez vérifier votre gestionnaire de paquets et vos sources de paquets."
        exit 1
    fi
fi

# Installation de Portainer
echo "Installation de Portainer..."
# Créer le volume pour Portainer
echo "Création du volume pour Portainer..."
docker volume create portainer_data

# Télécharger et installer le conteneur Portainer Server
echo "Installation de Portainer Server..."
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data \
  portainer/portainer-ce:latest

# Vérifier si le conteneur Portainer Server a démarré
echo "Vérification de l'installation de Portainer Server..."
if docker ps | grep -q portainer; then
  echo "Portainer Server a été installé avec succès."
else
  echo "L'installation de Portainer Server a échoué."
  exit 1
fi

# Exécutez la commande pour générer le mot de passe htpasswd
HTPASSWD=$(docker run --rm httpd:2.4-alpine htpasswd -nbB admin "portainer_root" | cut -d ":" -f 2)
docker stop portainer
docker run -d -p 9443:9443 -p 8000:8000 -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer-ce:latest --admin-password=$HTPASSWD

echo "Configuration de Portainer terminée."

#preparation pour Home Assistant
sudo adduser --system --group homeassistant
sudo mkdir -p /home/homeassistant/.homeassistant
sudo chown -R homeassistant:homeassistant /home/homeassistant/.homeassistant

# noter que le répertoire .homeassistant est caché (précédé d'un point)
# pour le garder propre et pour éviter une manipulation accidentelle 
# puisqu'il contient des fichiers de configuration importants.

docker run -d \
  --name="home-assistant" \
  -v /home/homeassistant/.homeassistant:/config \
  -e TZ="Europe/Paris" \
  --net=host \
  homeassistant/home-assistant:stable

docker restart home-assistant



# Affichage de l'URL d'accès à Portainer Server
echo "Pour accéder à Portainer Server, ouvrez un navigateur et allez à :"
echo "https://localhost:9443"

# Récupération de l'adresse IP de la machine hôte
HOST_IP=$(hostname -I | awk '{print $1}')
echo "https://${HOST_IP}:9443"
echo "Utilisateur Admin et mot de passe - root_portainer"

echo "Installation terminée."
