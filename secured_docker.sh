#!/bin/bash

# Creation reseau docker de type bridge
#docker network create -d bridge my_network
#docker network ls

# Creation du dossier pour les certificats 
mkdir /root/.docker
cd /root/.docker

# Securisation des communications client/serveur docker

# Creation cles de notre CA
openssl genrsa -aes256 -out ca-key.pem 4096
openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem

# Creation cle et demande de signature certificat identite demon docker
openssl genrsa -out server-key.pem 4096
openssl req -subj "/CN=`hostname`" -sha256 -new -key server-key.pem -out server.csr

# Signature certificat identite demon docker par CA
echo subjectAltName = DNS:`hostname`,IP:172.18.0.1,IP:127.0.0.1 > extfile.cnf
# 172.18.0.1 = IP reseau docker my_network
openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -extfile extfile.cnf

# Creation cle et demande de signature certificat identite client docker
openssl genrsa -out key.pem 4096
openssl req -subj "/CN=client" -new -key key.pem -out client.csr
echo extendedKeyUsage = clientAuth > extfile.cnf 
# Signature certificat identite client docker par CA
openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out cert.pem -extfile extfile.cnf

# Suppression demande de signature certificat identite
rm -v client.csr server.csr

# Modification permissions cles et certificats
chmod -v 0400 ca-key.pem key.pem server-key.pem
chmod -v 0444 ca.pem server-cert.pem cert.pem

# Configuration du daemon docker pour accepter uniquement les connexions provenant de clients valides par notre CA
sed -i 's/dockerd/dockerd -H tcp:\/\/0.0.0.0:2376 --tlsverify --tlscacert=\/root\/.docker\/ca.pem --tlscert=\/root\/.docker\/server-cert.pem --tlskey=\/root\/.docker\/server-key.pem/' /usr/lib/systemd/system/docker.service

# Redemarrage du daemon docker
systemctl daemon-reload
systemctl restart docker

# Copie des cle dans le home directory vagrant
mkdir /home/vagrant/.docker
cp /root/.docker/{ca,cert,key}.pem /home/vagrant/.docker/
chown vagrant:vagrant /home/vagrant/.docker/*

# Parametrage des clients docker pour chaque utilisateur de la machine
# Compte root
echo "export DOCKER_HOST=tcp://localhost.localdomain:2376" >> /root/.bashrc
echo "export DOCKER_TLS_VERIFY=1" >> /root/.bashrc

# Compte vagrant
echo "export DOCKER_HOST=tcp://localhost.localdomain:2376" >> /home/vagrant/.bashrc
echo "export DOCKER_TLS_VERIFY=1" >> /home/vagrant/.bashrc


