#!/bin/bash

# Mettre à jour le système
sudo apt update && sudo apt upgrade -y

# Installer les dépendances nécessaires
sudo apt install -y python3 python3-venv python3-pip libffi-dev libssl-dev autoconf build-essential

# Créer un utilisateur pour Home Assistant sans dossier home mais avec un shell
sudo useradd -rm homeassistant -G dialout,gpio,i2c

# Créer un dossier pour l'installation de Home Assistant et attribuer les permissions
sudo mkdir -p /srv/homeassistant
sudo chown homeassistant:homeassistant /srv/homeassistant

# Passer à l'utilisateur homeassistant et créer un environnement virtuel
sudo -u homeassistant -H -s <<EOF
cd /srv/homeassistant
python3 -m venv .
source bin/activate
python3 -m pip install wheel
python3 -m pip install homeassistant
deactivate
EOF

# Créer un service systemd pour Home Assistant
cat <<EOF | sudo tee /etc/systemd/system/home-assistant@homeassistant.service > /dev/null
[Unit]
Description=Home Assistant
After=network-online.target

[Service]
Type=simple
User=%i
ExecStart=/srv/homeassistant/bin/hass -c "/home/%i/.homeassistant"

[Install]
WantedBy=multi-user.target
EOF

# Activer et démarrer le service Home Assistant
sudo systemctl enable --now home-assistant@homeassistant

echo "Home Assistant installation is complete. You can access it via your web browser at http://<your-pi-ip-address>:8123"
