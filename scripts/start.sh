#!/bin/bash

# Install Extras
if [ ! -z "$RPMS" ]; then
 yum install -y $RPMS
fi

# Display PHP error's or not
if [[ "$ERRORS" == "true" ]] ; then
  sed -i -e "s/error_reporting =.*/error_reporting = E_ALL/g" /etc/php.ini
  sed -i -e "s/display_errors =.*/display_errors = On/g" /etc/php.ini
fi

# Create path for PHP sessions
mkdir -p -m 0777 /var/lib/php/session

# Set PHP timezone
if [ -z "$PHPTZ" ]; then
  PHPTZ="Europe/London"
fi
echo date.timezone = $PHPTZ >>/etc/php.ini

# Tweak nginx to match the workers to cpu's

procs=$(cat /proc/cpuinfo |grep processor | wc -l)
sed -i -e "s/worker_processes 5/worker_processes $procs/" /etc/nginx/nginx.conf

# Install the correct ionCube loader and WHMCS
if [ ! -e /.first-run-complete ]; then
  PHPVERSION=$(php --version | grep '^PHP' | sed 's/PHP \([0-9]\.[0-9]*\).*$/\1/')
  mkdir /usr/local/ioncube
  cp /tmp/ioncube/ioncube_loader_lin_$PHPVERSION.so /usr/local/ioncube
  echo zend_extension = /usr/local/ioncube/ioncube_loader_lin_$PHPVERSION.so >>/etc/php.ini

  rm -f /usr/share/nginx/html/*.html
  unzip /whmcs.zip -d /usr/share/nginx/html && mv /usr/share/nginx/html/whmcs/* /usr/share/nginx/html && rmdir /usr/share/nginx/html/whmcs
  touch /usr/share/nginx/html/configuration.php && chown nginx:nginx /usr/share/nginx/html/configuration.php && chmod 0777 /usr/share/nginx/html/configuration.php
  rm -f /whmcs.zip

  echo "Do not remove this file." > /.first-run-complete
fi

# Again set the right permissions (needed when mounting from a volume)
chown -Rf nginx.nginx /usr/share/nginx/html/

# Start supervisord and services
/usr/bin/supervisord -n -c /etc/supervisord.conf
