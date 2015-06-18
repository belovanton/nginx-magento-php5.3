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

# Pre-update
run          apt-get update -y --fix-missing && \
             ${APTGET} apt-transport-https && \
             ${APTGET} software-properties-common python-software-properties ca-certificates && \
             ${APTGET} aptitude autoconf automake build-essential cron dialog openssl pkg-config psmisc && \
             ${APTGET} curl emacs git less && \
             ${APTGET} nginx php5-fpm php5-mysql python-setuptools php-apc pwgen curl git ssmtp pv mysql-client && \
			 ${APTGET} php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-ming php5-ps php5-pspell php5-recode php5-sqlite php5-tidy php5-xmlrpc php5-xsl php5-xdebug gdb php5-dbg && \
			 apt-get clean && \
			 rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* /download/directory

#run             ${APTGET} g++ gcc make
#run             ${APTGET} libreadline6-dev libssl-dev libxml2-dev libxslt-dev libxslt1-dev zlib1g-dev


# Install Composer
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer.phar
# Install n98-magerun
RUN curl -o n98-magerun.phar https://raw.githubusercontent.com/netz98/n98-magerun/master/n98-magerun.phar && chmod +x ./n98-magerun.phar && mv n98-magerun.phar /usr/local/bin/n98-magerun.phar

# Magento Initialization and Startup Script
ADD /scripts /scripts
ADD /config /config
RUN chmod 755 /scripts/*.sh

# nginx config
RUN cp /config/nginx/nginx.conf /etc/nginx/nginx.conf && cp /config/nginx/nginx-host.conf /etc/nginx/sites-available/default && cp /config/xdebug.ini /etc/php5/conf.d/xdebug.ini

# php-fpm config
RUN cp /config/nginx/php.ini /etc/php5/fpm/php.ini && cp /config/nginx/php-fpm.conf /etc/php5/fpm/php-fpm.conf && cp /config/nginx/www.conf /etc/php5/fpm/pool.d/www.conf

# mcrypt enable
RUN ln -s /etc/php5/mods-available/mcrypt.ini /etc/php5/fpm/conf.d/20-mcrypt.ini

# Supervisor Config
RUN /usr/bin/easy_install supervisor && \
    /usr/bin/easy_install supervisor-stdout
ADD /config/supervisor/supervisord.conf /etc/supervisord.conf

VOLUME /var/www
EXPOSE 80

ENTRYPOINT ["/scripts/entrypoint.sh"]
CMD ["/bin/bash", "/scripts/start.sh"]
