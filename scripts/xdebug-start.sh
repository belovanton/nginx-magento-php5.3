#!/bin/sh
cp -fr /config/xdebug.ini /etc/php5/conf.d/
service php5-fpm stop
service php5-fpm start