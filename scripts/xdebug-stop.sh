#!/bin/sh
rm /etc/php5/conf.d/xdebug.ini
service php5-fpm stop
service php5-fpm start