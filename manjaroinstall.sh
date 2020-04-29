
#!/bin/bash

echo "Renaming home directories"
mv Videos vid
mv Pictures pic
mv Desktop desk
mv Documents doc
mv Music music
mv Public pub
mv Videos vid
mv Templates temp

echo "Backup grub file"
cp /etc/grub.d /etc/grub.d.bak
cp /etc/default/grub.cfg /etc/default/grub.cfg.bak

echo "Setting up grub conf"
sed -i 's/GRUB_CMD_LINE_DEFAULT="quiet/GRUB_CMD_LINE_DEFAULT="/g'
sed -i 's/#GRUB_HIDDEN_TIMEOUT=5/GRUB_HIDDEN_TIMEOUT=5/g'
sed -i 's/#GRUB_HIDDEN_TIMEOUT_QUIET=true/GRUB_HIDDEN_TIMEOUT_QUIET=true/g'

#if status
#0 => okay
#3 => not started
#4 => not installed
#https://www.archlinux.org/packages

echo "Launch as root"

echo "Kernel up 2 date ?"
read var
if var == 'N' || var == 'n'; then
echo "Upgrade kernel first"
exit 0
fi

echo "Sync & upgrade"
pacman -Syu --noconfirm

echo "Installing official pkg"
pacman -S --noconfirm - < pkglist.lst

echo "Config zsh"
# OMZ
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
chsh -s /bin/zsh

echo "Config LAMP"
# LAMP: https://forum.manjaro.org/t/install-apache-mariadb-php-lamp-2016/1243

# APACHE
sed -i 's/LoadModule unique_id_module/#LoadModule unique_id_module/g' /etc/httpd/conf/httpd.conf
sudo systemctl enable httpd
sudo systemctl restart httpd
echo "<html><h1>Apache</h1></html>" >> /srv/http/index.html
lynx -dump localhost >> ~/.apache.html
if ... grep Apache ~/.apache.html
rm ~/.apache.html

# MySQL
sudo mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
sudo systemctl enable mysqld
sudo systemctl start mysqld
mysql_secure_installation > enter y pwd pwd y y y y

# PHP
sed -i 's/LoadModule mpm_event_module/#LoadModule mpm_event_module/g' /etc/httpd/conf/httpd.conf
sed -i 's/#LoadModule mpm_prefork_module/LoadModule mpm_prefork_module/g' /etc/httpd/conf/httpd.conf
echo "LoadModule php7_module modules/libphp7.so" >> /etc/httpd/conf/httpd.conf
echo "AddHandler php7-script php" >> /etc/httpd/conf/httpd.conf
echo "Include conf/extra/php7_module.conf" >> /etc/httpd/conf/httpd.conf
echo "<?php phpinfo(); ?>" >> /srv/http/php.php
sudo systemctl restart httpd
lynx -dump localhost >> ~/.php.php
if ... grep Apache ~/.php.php
rm ~/.php.php

# PHPMYADMIN
sed -i 's/#extension=bz2.so/extension=bz2.so/g' /etc/php/php.ini
sed -i 's/#extension=mysqli.so/extension=mysqli.so/g' /etc/php/php.ini
cat <<EOF > /etc/httpd/conf/extra/phpmyadmin.conf
Alias /phpmyadmin "/usr/share/webapps/phpMyAdmin"
<Directory "/usr/share/webapps/phpMyAdmin">
DirectoryIndex index.php
AllowOverride All
Options FollowSymlinks
Require all granted
</Directory>
EOF
echo "Include conf/extra/phpmyadmin.conf" >> /etc/httpd/conf/httpd.conf
sudo systemctl restart httpd

systemctl enable sshd

echo "Installing AUR"
exit
yay -S --noconfirm - < pkgaur.lst
chsh -s /bin/zsh
