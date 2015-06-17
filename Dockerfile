FROM ubuntu:latest
MAINTAINER Anton Belov <a.belov@kmplzt.de>


# Add libraries directory
ADD ./lib /home/lib

# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl

# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get -y upgrade

# Basic Requirements
RUN apt-get -y install nginx  php-apc pwgen python-setuptools curl git ssmtp pv mysql-client vim tree
 
##########################
## INSTALL DEPENDENCIES ##
##########################

# Install packages
RUN DEBIAN_FRONTEND=noninteractive \
 && apt-get install -y \
	autoconf \
	build-essential \
	imagemagick \
	libgd3 \
	libgd-dev \
	libfreetype6-dev \
	mcrypt \
	libmcrypt-dev \
	libbz2-dev \
	libcurl4-openssl-dev \
	libevent-dev \
	libffi-dev \
	libglib2.0-dev \
	libjpeg-dev \
	libmagickcore-dev \
	libmagickwand-dev \
	libmysqlclient-dev \
	libncurses-dev \
	libpq-dev \
	libreadline-dev \
	libsqlite3-dev \
	libssl-dev \
	libxml2-dev \
	libxslt-dev \
	libyaml-dev \
	zlib1g-dev

# Build and install PHP
WORKDIR /home/lib/php-5.3
RUN tar -xvf php-5.3.29.tar.gz
WORKDIR /home/lib/php-5.3/php-5.3.29
RUN ./configure --enable-fpm --with-mysql --with-mysqli --with-zlib --with-jpeg-dir --with-gd --with-freetype-dir --with-curl --with-openssl --with-pdo-mysql --with-mcrypt
RUN make clean
RUN make
RUN make install
RUN cp sapi/fpm/php-fpm /usr/local/bin

###############
## CONFIGURE ##
###############

# PHP config files
ADD ./conf/php/php.ini /usr/local/php/php.ini
ADD ./conf/php/php-fpm.conf /usr/local/etc/php-fpm.conf

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer.phar

# Install n98-magerun
RUN curl -o n98-magerun.phar https://raw.githubusercontent.com/netz98/n98-magerun/master/n98-magerun.phar
RUN chmod +x ./n98-magerun.phar
RUN mv n98-magerun.phar /usr/local/bin/n98-magerun.phar

# Install Modman
# RUN bash < <(curl -s -L https://raw.github.com/colinmollenhour/modman/master/modman-installer) 
# RUN chmod +x modman
# RUN mv modman /usr/local/bin/

# Magento Initialization and Startup Script
ADD /scripts /scripts
ADD /config /config
RUN chmod 755 /scripts/*.sh

# nginx config
RUN cp /config/nginx/nginx.conf /etc/nginx/nginx.conf
RUN cp /config/nginx/nginx-host.conf /etc/nginx/sites-available/default
RUN cp /config/nginx/apc.ini /etc/php5/mods-available/apcu.ini

# php-fpm config
RUN cp /config/nginx/php.ini /etc/php5/fpm/php.ini
RUN cp /config/nginx/php-fpm.conf /etc/php5/fpm/php-fpm.conf
RUN cp /config/nginx/www.conf /etc/php5/fpm/pool.d/www.conf

# mcrypt enable
RUN ln -s /etc/php5/mods-available/mcrypt.ini /etc/php5/fpm/conf.d/20-mcrypt.ini
RUN ln -s /etc/php5/mods-available/mcrypt.ini /etc/php5/cli/conf.d/20-mcrypt.ini

# Enabling SSH
RUN rm -f /etc/service/sshd/down

# Create .ssh folder
RUN mkdir -p /root/.ssh

# Enabling session files
RUN mkdir -p /tmp/sessions/
RUN chown www-data.www-data /tmp/sessions -Rf
RUN sed -i -e "s:;\s*session.save_path\s*=\s*\"N;/path\":session.save_path = /tmp/sessions:g" /etc/php5/fpm/php.ini

# Supervisor Config
RUN /usr/bin/easy_install supervisor
RUN /usr/bin/easy_install supervisor-stdout
ADD /config/supervisor/supervisord.conf /etc/supervisord.conf

VOLUME /var/www
EXPOSE 80

ENTRYPOINT ["/scripts/entrypoint.sh"]
CMD ["/bin/bash", "/scripts/start.sh"]



