#!/bin/bash

basedir=/vagrant

# install terminfo for termite
curl -O https://raw.githubusercontent.com/thestinger/termite/master/termite.terminfo
tic -x termite.terminfo -o /usr/share/terminfo
rm termite.terminfo

# install aurweb deps
pacman -Syu nginx \
            php-fpm \
            phpmyadmin \
            php-mcrypt \
            mariadb \
            python-mysql-connector \
            python-pygit2 \
            git --noconfirm

# start db
mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
systemctl start mysqld
systemctl enable mysqld

# instead of mysql_secure_installation

# Make sure that NOBODY can access the server without a password
mysql -e "UPDATE mysql.user SET Password = PASSWORD('secure') WHERE User = 'root'"
# Kill the anonymous users
mysql -e "DROP USER ''@'localhost'"
# Because our hostname varies we'll use some Bash magic here.
mysql -e "DROP USER ''@'$(hostname)'"
# Kill off the demo database
mysql -e "DROP DATABASE test"
# Make our changes take effect
mysql -e "FLUSH PRIVILEGES"
# Any subsequent tries to run queries this way will get access denied because lack of usr/pwd param

# setup mysql db and dbuser
mysql -u root -p'secure' -e "CREATE DATABASE AUR;"
mysql -u root -p'secure' -e "CREATE USER 'aur'@'localhost' IDENTIFIED BY 'aur';"
mysql -u root -p'secure' -e "GRANT ALL PRIVILEGES ON AUR . * TO 'aur'@'localhost';FLUSH PRIVILEGES"

# setup nginx
echo "
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;

    keepalive_timeout  65;

    server {
        listen       80;
        server_name  localhost;
        root   $basedir/web/html;
        index  index.html index.htm index.php;

        location ~ ^/[^/]+\.php($|/) {
            fastcgi_pass   unix:/run/php-fpm/php-fpm.sock;
            fastcgi_index  index.php;
            fastcgi_split_path_info ^(/[^/]+\.php)(/.*)$;
            fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
            fastcgi_param  PATH_INFO        \$fastcgi_path_info;
            include        fastcgi_params;
        }

        location ~ .* {
            rewrite ^/(.*)$ /index.php/\$1 last;
        }

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }
    }

    # phpmyadmin
    server {
        listen 81;
        server_name     localhost;

        root    /usr/share/webapps/phpMyAdmin;
        index   index.php;

        location ~ \.php$ {
            try_files      \$uri =404;
            fastcgi_pass   unix:/run/php-fpm/php-fpm.sock;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
            fastcgi_param  PATH_INFO        \$fastcgi_path_info;
            include        fastcgi_params;
        }
    }
}" > /etc/nginx/nginx.conf

# enable extensions in php
sed -i "s/;extension=mcrypt.so/extension=mcrypt.so/" /etc/php/php.ini
sed -i "s/;extension=mysqli.so/extension=mysqli.so/" /etc/php/php.ini

# php-fpm
echo "php_admin_value[open_basedir] = /tmp:$basedir:/etc/webapps:/usr/share/webapps" >> /etc/php/php-fpm.conf
echo "php_admin_value[extension] = pdo_mysql.so" >> /etc/php/php-fpm.conf

# start nginx and php-fpm
systemctl start nginx php-fpm
systemctl enable nginx php-fpm

# aur setup
# aur shcema
mysql -uaur -p'aur' AUR < $basedir/schema/aur-schema.sql

# create aur user
useradd -U -d $basedir -c 'AUR user' aur

# git repo
mkdir /srv/aur.git/
cd /srv/aur.git/
git init --bare
ln -s $basedir/git-interface/git-update.py hooks/update
chown -R aur .

# git-auth wrapper
cd $basedir/git-interface/
make
make install

# sshd
echo "
Match User aur
    PasswordAuthentication no
    AuthorizedKeysCommand /usr/local/bin/aur-git-auth "%t" "%k"
    AuthorizedKeysCommandUser aur" >> /etc/ssh/sshd_config

systemctl daemon-reload
systemctl restart sshd
