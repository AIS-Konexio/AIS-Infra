#!/bin/bash

# Script d'installation de GLPI
# Auteur : Garance Defrel 
# Date : 21/02/2025
# Version : 1.0

# Paramètres prédéfinis
DB_NAME=garance_glpi
DB_USER=garance
GLPI_VERSION=10.0.18
GLPI_URL=https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/glpi-${GLPI_VERSION}.tgz
SERVER_NAME=garance.glpi

# Demande d'informations 
read -sp "Entrez le mot de passe MySQL pour l'utilisateur GLPI : " MYSQL_PASS
echo
read -p "Entrez le nom de domaine ou l'IP du serveur (ex: glpi.exemple.com) : " SERVER_NAME

# Fonction : Mise à jour du système et installations des dépendances

function update_system(){
    #Maj"
    echo "Mise à jour du système en cours..."
    sudo apt update && sudo apt upgrade -y
    #Installation packages"
    echo "Installation des packages requis..."
    sudo apt-get install -y apache2 libapache2-mod-php mariadb-server php php-{curl,gd,imagick,intl,apcu,memcache,imap,mysql,cas,ldap,tidy,pear,xmlrpc,pspell,mbstring,json,iconv,xml,xsl,zip,bz2}

    #Vérification de l'installation des paquets
    if dpkg -l apache2 libapache2-mod-php mariadb-server php php-{curl,gd,imagick,intl,apcu,memcache,imap,mysql,cas,ldap,tidy,pear,xmlrpc,pspell,mbstring,json,iconv,xml,xsl,zip,bz2}; then
        echo "Tous les paquets ont été installés avec succès !"
    else
        echo "Une erreur est survenue lors de l'installation des paquets."
    exit 1
    fi
}

# Fonction : Sécurisation de MariaDB
function secure_mariaDB(){
    echo "Automatisation de mysql_secure_installation..."
    sudo mysql_secure_installation <<EOF

Y
Y
$MYSQL_PASS
$MYSQL_PASS
Y
Y
Y
Y
EOF
    echo "Etape 2 terminée : Sécurisation de MariaDB"
    exit 1
}

# Fonction : Configuration de la base de données
function config_database(){
    echo "Configuration de la base de données"
    sudo mysql -u root -p$MYSQL_PASS -e "
    CREATE DATABASE IF NOT EXISTS $DB_NAME;
    CREATE USER  $DB_USER@localhost IDENTIFIED BY '$MYSQL_PASS';
    GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASS';
    FLUSH PRIVILEGES;"
    echo "Etape 3 terminée : Configuration de la base de données."
}

# Fonction : Installation de GLPI
function install_glpi(){
    echo "Téléchargement et installation de GLPI..."
    if ! wget $GLPI_URL && sudo tar -xvzf glpi-${GLPI_VERSION}.tgz -C /var/www/; then
        echo "Téléchargement et extraction de GLPI réussi !"
        echo "Configuration de GLPI..."
        sudo chown -R www-data:www-data /var/www/glpi
        # Création du dossier de configuration
        sudo mkdir /etc/glpi && sudo chown -R www-data:www-data /etc/glpi && sudo cp -r /var/www/glpi/config /etc/glpi 
        # Création du fichier de configuration
        sudo mkdir /var/lib/glpi && sudo chown -R www-data:www-data /var/lib/glpi && sudo cp -r /var/www/glpi/files/* /var/lib/glpi
        # Création du fichier de configuration
        sudo mkdir  /var/log/glpi && sudo chown -R www-data:www-data /var/log/glpi        
        echo "Etape 4 terminée : Installation de GLPI."
    else
    echo "Erreur lors du téléchargement ou de l'extraction de GLPI."
    exit 1
    fi
}

# Fonction : Configuration de GLPI
function config_files(){
    echo "Configuration de GLPI..."
#Création du fichier downstream.php    
echo "<?php
define('GLPI_CONFIG_DIR', '/etc/glpi/');

if (file_exists(GLPI_CONFIG_DIR . '/local_define.php')) {
   require_once GLPI_CONFIG_DIR . '/local_define.php';
}" | sudo tee /var/www/glpi/inc/downstream.php
#Création du fichier local_define.php
echo "<?php
define('GLPI_VAR_DIR', '/var/lib/glpi');
define('GLPI_LOG_DIR', '/var/log/glpi');
" | sudo tee /etc/glpi/local_define.php
#Création du fichier de configuration pour le serveur web
echo "<VirtualHost *:80>
    ServerName $SERVER_NAME

    DocumentRoot /var/www/glpi/public

    # If you want to place GLPI in a subfolder of your site (e.g. your virtual host is serving multiple applications),
    # you can use an Alias directive. If you do this, the DocumentRoot directive MUST NOT target the GLPI directory itself.
    # Alias "/glpi" "/var/www/glpi/public"

    <Directory /var/www/glpi/public>
        Require all granted

        RewriteEngine On

        # Redirect all requests to GLPI router, unless file exists.
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>
</VirtualHost>" | sudo tee /etc/apache2/sites-available/$SERVER_NAME.com.conf

#Activation du site
sudo a2enmod rewrite
sudo a2dissite 000-default.conf
sudo a2ensite $SERVER_NAME.com.conf
#Redémarrage de Apache
sudo systemctl restart apache2
echo "Etape 5 terminée : Configuration de GLPI."
}


# Boucle interactive pour choisir les étapes à exécuter
while true; do
    read -n1 -p "Installation GLPI [1] :MAJ, [2] : Sécuriser MariaDB, [3] : Configurer DB, [4] : Installation GLPI, [5] : Configuration fichiers, [q] : quit" choice
    echo
    case $choice in
        [1]) echo "Mise à jour du système et installation des dépendances"; update_system; continue;;
        [2]) echo "Sécurisation du serveur MariaDB"; secure_mariaDB; continue;;
        [3]) echo "Configuration de la base de données"; config_database; continue;;
        [4]) echo "Téléchargement et installation de GLPI. Création des dossiers nécéssaires et accès."; install_glpi; continue;;
        [5]) echo "Configuration des fichiers pour accèder à GLPI"; config_files; continue;;
        [qQ]) echo "Fin"; break;;
        *) echo "Invalid input..."; continue;;
    esac
done
