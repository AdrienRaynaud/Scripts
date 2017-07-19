#!/bin/bash

# Installation de docker
sudo curl -sSL https://get.docker.com | sh
sudo usermod -aG docker vagrant
sudo systemctl start docker
sudo systemctl enable docker

# Installation de docker-compose
sudo su
curl -sL https://github.com/docker/compose/releases/download/1.12.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
exit







