#!/bin/bash

# This script will install B2SHARE from scratch on a centos 6.5 x64 machine
# It uses invenio and B2SHARE sources from github
# It also uses the scripts in the invenio-scripts repository
# Running the script takes close to 2 hours (installs many packages)
# SEE ALSO the text at the end of this script

INVENIO_DIR=/tmp/opt/invenio
MYSQL_PASS="invenio"
WWW_USER=www-data
WWW_SERVICE=apache2

echo "************ Update Apt"
sudo DEBIAN_FRONTEND=noninteractive apt-get -q -y -o Dpkg::Options::="--force-confdef" update
sudo su vagrant -c "touch /home/vagrant/.Xauthority"
sudo updatedb

echo "************ Installing wget, git other pre-install deps"
sudo DEBIAN_FRONTEND=noninteractive apt-get -q -y -o Dpkg::Options::="--force-confdef" install \
	vim wget python python-pip git ghostscript

sudo pip install --upgrade setuptools
sudo pip install --upgrade pip

echo "************ Installing install dependencies"
sudo DEBIAN_FRONTEND=noninteractive apt-get -q -y -o Dpkg::Options::="--force-confdef" install \
	python-dev apache2-mpm-prefork ssl-cert python-simplejson \
    mysql-server mysql-client python-mysqldb \
    python-libxml2 python-libxslt1 gnuplot poppler-utils \
    antiword catdoc wv html2text ppthtml xlhtml \
    clisp gettext libapache2-mod-wsgi unzip python-numpy \
    python-rdflib python-gnuplot python-magic pdftk \
    html2text giflib-tools pstotext make sudo sbcl \
    pylint pychecker pyflakes python-profiler python-epydoc \
    libapache2-mod-xsendfile libmysqlclient-dev mysql-server \
    mysql-client python-mysqldb postfix automake1.9 make \
    python-openid python-magic ffmpeg libxml2-dev libxslt-dev \
    automake1.9 autoconf python-magic common-lisp-controller mediainfo \
    openoffice.org

echo "************ Reconfigure MySQL password"
mysql -u root --password="" -e "GRANT ALL PRIVILEGES ON invenio.*  TO root@localhost IDENTIFIED BY '$MYSQL_PASS';"

echo "************ Generate Apache self-signed cert"
sudo mkdir -p /etc/apache2/ssl/
sudo DEBIAN_FRONTEND=noninteractive /usr/sbin/make-ssl-cert \
	/usr/share/ssl-cert/ssleay.cnf /etc/apache2/ssl/apache.pem
sudo /usr/sbin/a2dissite default
sudo /usr/sbin/a2enmod ssl

echo "************ Git clone invenio"
cd /home/vagrant/
git config --global http.sslVerify false
git clone -v -b next https://github.com/EUDAT-B2SHARE/invenio.git
cd /home/vagrant/invenio
git fetch # just in case, to get then new tags
git checkout tags/b2share-v2 -b bshare-v2

echo "************ Installing Python dependencies"
sudo easy_install -U distribute
pip install --upgrade setuptools
pip install --upgrade distribute
pip install -r requirements.txt
pip install -r requirements-extras.txt
pip install -r requirements-flask.txt --allow-external=twill --allow-unverified=twill
pip install -r requirements-flask-ext.txt
pip install flower validate_email pyDNS
sudo updatedb

echo "************ Git clone invenio-scripts"
cd /home/vagrant/
git clone https://github.com/EUDAT-B2SHARE/invenio-scripts.git
cp invenio-scripts/install/invenio.conf invenio/config/
cp invenio-scripts/install/invenio-local.conf invenio/
cp invenio-scripts/install/collections.sql invenio/

# echo "************ Installing Invenio dependencies"
# sudo DEBIAN_FRONTEND=noninteractive apt-get -q -y -o Dpkg::Options::="--force-confdef" install \
# 	automake1.9 autoconf python-magic common-lisp-controller mediainfo openoffice.org

echo "************ Reinstall FFMPEG dependencies"
# remove ffmpeg
sudo DEBIAN_FRONTEND=noninteractive apt-get -q -y -o Dpkg::Options::="--force-confdef" remove \
	ffmpeg x264 libx264-dev debian-keyring
# add 3rd party site
sudo echo "\ndeb http://www.deb-multimedia.org/ wheezy main non-free" > /etc/apt/sources.lst
sudo DEBIAN_FRONTEND=noninteractive apt-get -q -y -o Dpkg::Options::="--force-confdef" update
gpg --keyserver pgp.mit.edu --recv-keys 1F41B907
gpg --armor --export 1F41B907 | sudo apt-key add -
sudo DEBIAN_FRONTEND=noninteractive apt-get -q -y -o Dpkg::Options::="--force-confdef" update
# install dependencies for ffmpeg
sudo DEBIAN_FRONTEND=noninteractive apt-get -q -y -o Dpkg::Options::="--force-confdef" install \
	build-essential subversion git-core checkinstall texi2html \
	libfaac-dev libopencore-amrnb-dev libopencore-amrwb-dev libsdl1.2-dev libtheora-dev \
	libvorbis-dev libx11-dev libxfixes-dev libxvidcore-dev zlib1g-dev libavcodec-dev \
	libogg-dev ffmpeg djvulibre-bin libtiff-tools mercurial
# install ocropus dependency
cd /home/vagrant/
hg clone -r ocropus-0.7 https://code.google.com/p/ocropus
cd ocropus/ocropy
sudo apt-get install curl python-scipy python-matplotlib python-tables iceweasel \
	imagemagick python-opencv python-bs4
python setup.py download_models
sudo python setup.py install

service $WWW_SERVICE stop

echo "************ Installing invenio base"
cd /home/vagrant/invenio
aclocal-1.9
automake-1.9 -a
autoconf
./configure --prefix=$INVENIO_DIR
make
# install Invenio with symlink fix
sudo make install
sudo ln -s $INVENIO_DIR/lib/python/invenio /usr/local/lib/python2.7/dist-packages/invenio
sudo ln -s $INVENIO_DIR/lib/python/invenio /usr/lib/python2.7/dist-packages/invenio
sudo make install
sudo ln -s $INVENIO_DIR/lib/python/invenio /usr/local/lib/python2.7/dist-packages/invenio
sudo ln -s $INVENIO_DIR/lib/python/invenio /usr/lib/python2.7/dist-packages/invenio
sudo make install
# BUG: cyclic include
sudo rm -rf $INVENIO_DIR/lib/python/invenio/
sudo make install

echo "************ Installing invenio extras"
sudo make install-bootstrap
sudo make install-mathjax-plugin
sudo make install-jquery-plugins
sudo make install-jquery-tokeninput
sudo make install-plupload-plugin
sudo make install-ckeditor-plugin
sudo make install-pdfa-helper-files
sudo make install-mediaelement
sudo make install-solrutils
sudo make install-js-test-driver

echo "************ Fix invenio ownership and permissions"
# configure invenio targets
sudo chown -R $WWW_USER: $INVENIO_DIR
sudo cp invenio-local.conf $INVENIO_DIR/etc/
sudo chown -R $WWW_USER:$WWW_USER $INVENIO_DIR

echo "************ Create new Invenio database"
mysql -u root --password=$MYSQL_PASS -e "drop database invenio;"
mysql -u root --password=$MYSQL_PASS -e "CREATE DATABASE invenio DEFAULT CHARACTER SET utf8;"
mysql -u root --password=$MYSQL_PASS -e "GRANT ALL PRIVILEGES ON invenio.*  TO root@localhost IDENTIFIED BY '$MYSQL_PASS';"

echo "************ Reconfigure Invenio"
# configure invenio config
sudo -u $WWW_USER $INVENIO_DIR/bin/inveniocfg --update-all
sudo -u $WWW_USER $INVENIO_DIR/bin/inveniocfg --create-tables --yes-i-know
sudo -u $WWW_USER $INVENIO_DIR/bin/inveniocfg --update-all
sudo -u $WWW_USER $INVENIO_DIR/bin/inveniocfg --update-config-py
sudo -u $WWW_USER $INVENIO_DIR/bin/inveniomanage bibfield config load
sudo -u $WWW_USER $INVENIO_DIR/bin/inveniocfg --load-webstat-conf
sudo -u $WWW_USER $INVENIO_DIR/bin/inveniomanage apache create-config
sudo -u $WWW_USER $INVENIO_DIR/bin/inveniocfg --update-all

mysql -u root -D invenio --password=$MYSQL_PASS < collections.sql

echo "************ Reconfigure Apache"
sudo ln -s $INVENIO_DIR/etc/apache/invenio-apache-vhost.conf \
    /etc/apache2/sites-available/invenio
sudo ln -s $INVENIO_DIR/etc/apache/invenio-apache-vhost-ssl.conf \
	/etc/apache2/sites-available/invenio-ssl
sudo /usr/sbin/a2dissite default
sudo /usr/sbin/a2ensite invenio
sudo /usr/sbin/a2ensite invenio-ssl
sudo /usr/sbin/a2enmod ssl
sudo /usr/sbin/a2enmod xsendfile
# sudo service $WWW_SERVICE restart

echo "************ Deploying b2share overlay"
cd /home/vagrant
git clone https://github.com/EUDAT-B2SHARE/b2share.git
(cd /home/vagrant/b2share && sudo ./deployment/deploy_overlay.sh)
(cd /home/vagrant/ && sudo ./invenio-scripts/install/start-daemons-deb.sh)
sudo -u $WWW_USER $INVENIO_DIR/bin/inveniogc -guests -s5m -uadmin

sudo service $WWW_SERVICE restart

echo
echo "*** If you are configuring a development environment, you should:"
echo "    1. disable the redis cache (SOME FUNCTIONS CANNOT RUN WITHOUT CACHE):"
echo '       edit $INVENIO_DIR/lib/python/invenio/config.py and set CFG_FLASK_CACHE_TYPE = "null"'
echo "    2. reduce the number of apache processes:"
echo '       edit $INVENIO_DIR/etc/apache/invenio-apache-vhost.conf and replace "processes=5" with "processes=1"'
echo '    Restart'
echo '    3. configure invenio processes to run automatically: '
echo '       run sudo su -c "sudo -u apache $INVENIO_DIR/bin/bibsched"'
echo '       wait for the UI to show up, then press A (switch to auto), wait, press Q (quit)'
echo '    Restart'
