#!/bin/bash

# install
sudo apt-get -y update && apt-get upgrade
sudo apt-get -y install apache2 php5 libapache2-mod-php5 php5-mcrypt php5-curl php5-mysql php5-gd php5-cli php5-dev mysql-client
php5enmod mcrypt

curl -sS http://install.phpcomposer.com/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
composer config -g repo.packagist composer http://packagist.phpcomposer.com

#setup
echo -n "MySQL root password: "
read -s rootpw
echo -n "Flarum database username: "
read dbuser
echo -n "Database user password: "
read -s dbpw
echo -n "Database name: "
read dbname

sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $dbpw"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $dbpw"
sudo apt-get -y install mysql-server

echo "ServerName localhost" | sudo tee /etc/apache2/conf-available/fqdn.conf
sudo a2enconf fqdn

sudo mkdir /var/www/flarum
cd /var/www/flarum
composer create-project flarum/flarum . --stability=beta
composer require vingle/flarum-configure-smtp
composer require lazyboywu/oauth2-qq
composer require lazyboywu/flarum-ext-auth-qq
composer require matpompili/flarum-favicon
composer require davis/flarum-ext-socialprofile
composer require flagrow/flarum-ext-image-upload
composer require santiagobiali/flarum-ext-logo
composer require davis/flarum-animatedtag
composer require flagrow/flarum-ext-guardian
composer require hyn/flarum-default-group
composer require s9e/flarum-ext-mediaembed

sudo chown -R www-data:www-data /var/www/flarum

sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/flarum-beta.conf
sudo ln -s /etc/apache2/sites-available/flarum-beta.conf /etc/apache2/sites-enabled
sudo rm -f /etc/apache2/sites-enabled/000-default.conf
sudo sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/flarum|' /etc/apache2/sites-available/flarum-beta.conf
sudo a2enmod rewrite
echo "<Directory "/var/www/flarum">" >> /etc/apache2/sites-enabled/flarum-beta.conf
echo "AllowOverride All" >> /etc/apache2/sites-enabled/flarum-beta.conf
echo "</Directory>" >> /etc/apache2/sites-enabled/flarum-beta.conf
 
db="create database $dbname;GRANT ALL PRIVILEGES ON $dbname.* TO $dbuser@localhost IDENTIFIED BY '$dbpw';FLUSH PRIVILEGES;"
mysql -u root -p$rootpw -e "$db"
 
if [ $? != "0" ]; then
 echo "[Error]: Database creation failed"
 exit 1
else
 echo "------------------------------------------"
 echo " Database has been created successfully "
 echo "------------------------------------------"
 echo " DB Info: "
 echo ""
 echo " DB Name: $dbname"
 echo " DB User: $dbuser"
 echo " DB Pass: $dbpw"
 echo ""
 echo "------------------------------------------"
fi

echo -e "\n"

service apache2 restart && service mysql restart > /dev/null
echo -e "\n"

if [ $? -ne 0 ]; then
   echo "Please Check the Installed Services, There are some $(tput bold)$(tput setaf 1)Problems$(tput sgr0)"
else
   echo "Installed Services run $(tput bold)$(tput setaf 2)Sucessfully$(tput sgr0)"
fi
