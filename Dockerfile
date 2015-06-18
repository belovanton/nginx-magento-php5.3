from            ubuntu:12.04
MAINTAINER Anton Belov <a.belov@kmplzt.de>


env             DEBIAN_FRONTEND noninteractive
env             APTGET apt-get install -y --no-install-recommends

# Workaround for upstart init, from https://github.com/dotcloud/docker/issues/1024
run             dpkg-divert --local --rename --add /sbin/initctl
run             ln -sf /bin/true /sbin/initctl

# Workaround for successful dist-upgrade, from https://github.com/dotcloud/docker/issues/1724
run             dpkg-divert --local --rename /usr/bin/ischroot
run             ln -sf /bin/true /usr/bin/ischroot

RUN echo "deb http://archive.ubuntu.com/ubuntu precise universe main multiverse restricted" > /etc/apt/sources.list
RUN echo "deb http://security.ubuntu.com/ubuntu/ precise-security universe main multiverse restricted" >> /etc/apt/sources.list
RUN echo "deb http://ppa.launchpad.net/fkrull/deadsnakes/ubuntu precise main" >> /etc/apt/sources.list
RUN echo "deb http://ppa.launchpad.net/atareao/atareao/ubuntu precise main" >> /etc/apt/sources.list

# Pre-update
run             apt-get update -y --fix-missing
run             ${APTGET} apt-transport-https
run             ${APTGET} software-properties-common python-software-properties ca-certificates


# Basic
run             ${APTGET} aptitude autoconf automake build-essential cron dialog openssl pkg-config psmisc
#run             ${APTGET} g++ gcc make
#run             ${APTGET} libreadline6-dev libssl-dev libxml2-dev libxslt-dev libxslt1-dev zlib1g-dev
run             ${APTGET} curl emacs git less

# Basic Requirements
RUN ${APTGET} nginx php5-fpm php5-mysql python-setuptools php-apc pwgen curl git ssmtp pv mysql-client
 
# Magento Requirements
RUN ${APTGET} php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-ming php5-ps php5-pspell php5-recode php5-sqlite php5-tidy php5-xmlrpc php5-xsl php5-xdebug 

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

# php-fpm config
RUN cp /config/nginx/php.ini /etc/php5/fpm/php.ini
RUN cp /config/nginx/php-fpm.conf /etc/php5/fpm/php-fpm.conf
RUN cp /config/nginx/www.conf /etc/php5/fpm/pool.d/www.conf

# mcrypt enable
RUN ln -s /etc/php5/mods-available/mcrypt.ini /etc/php5/fpm/conf.d/20-mcrypt.ini


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
