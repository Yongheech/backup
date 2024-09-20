#!/bin/bash
apt-get install -y apt-transport-https curl
mkdir -p /etc/apt/keyrings
curl -o /etc/apt/keyrings/mariadb-keyring.pgp 'https://mariadb.org/mariadb_release_signing_key.pgp'

cat <<EOL > /etc/apt/sources.list.d/mariadb.sources
# MariaDB 10.11 repository list - created 2024-09-10 01:09 UTC
# https://mariadb.org/download/
X-Repolib-Name: MariaDB
Types: deb
# deb.mariadb.org is a dynamic mirror if your preferred mirror goes offline. See https://mariadb.org/mirrorbits/ for details.
# URIs: https://deb.mariadb.org/10.11/ubuntu
URIs: https://tw1.mirror.blendbyte.net/mariadb/repo/10.11/ubuntu
Suites: jammy
Components: main main/debug
Signed-By: /etc/apt/keyrings/mariadb-keyring.pgp
EOL
apt-get update
apt-get install -y mariadb-server

sudo mariadb-secure-installation << EOF

y
y
ubuntu
ubuntu
y
n
y
y
EOF

mysql -e "create database ubuntu;"
mysql -e "create user ubuntu identified by 'ubuntu';"
mysql -e "grant all privileges on ubuntu.* to 'ubuntu'@'%' identified by 'ubuntu';"
mysql -e "flush privileges;"

# MariaDB 원격 접속 허용
sed -i 's/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

sudo systemctl restart mariadb
sudo systemctl enable mariadb
