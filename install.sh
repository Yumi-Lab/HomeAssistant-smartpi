#!/bin/bash

# Mettre à jour le système
sudo apt-get update && sudo apt-get upgrade -y

# Installer les outils et bibliothèques de compilation nécessaires, y compris libssl-dev pour cryptography
sudo apt-get install -y build-essential libssl-dev libffi-dev python3-dev cargo

# Installer les dépendances système nécessaires pour Home Assistant
sudo apt-get install -y python3 python3-venv python3-pip

# Vérifier et créer le groupe gpio si nécessaire
if [ ! $(getent group gpio) ]; then
    sudo groupadd gpio
    echo "Groupe gpio créé."
fi

# Créer un utilisateur pour Home Assistant sans dossier home mais avec un shell
if [ ! $(getent passwd homeassistant) ]; then
    sudo useradd -rm homeassistant -G dialout,i2c,gpio
    echo "Utilisateur homeassistant créé avec succès."
else
    echo "L'utilisateur homeassistant existe déjà."
fi

# Créer un dossier pour l'installation de Home Assistant et attribuer les permissions
sudo mkdir -p /srv/homeassistant
sudo chown homeassistant:homeassistant /srv/homeassistant

# Installer Home Assistant dans un environnement virtuel
sudo -u homeassistant -H -s <<EOF
cd /srv/homeassistant
python3 -m venv .
source bin/activate
pip install --upgrade pip setuptools wheel
pip install homeassistant
deactivate
EOF

# Créer un service systemd pour Home Assistant
cat <<EOF | sudo tee /etc/systemd/system/home-assistant@homeassistant.service > /dev/null
[Unit]
Description=Home Assistant
After=network-online.target

[Service]
Type=simple
User=homeassistant
ExecStart=/srv/homeassistant/bin/hass -c "/home/homeassistant/.homeassistant"

[Install]
WantedBy=multi-user.target
EOF

# Activer et démarrer le service Home Assistant
sudo systemctl enable --now home-assistant@homeassistant

echo "Installation de Home Assistant terminée. Vous pouvez y accéder via votre navigateur web à l'adresse http://<votre-adresse-ip>:8123"
