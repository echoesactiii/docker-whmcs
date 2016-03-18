#!/bin/bash

# Disable Strict Host checking for non interactive git clones, set permissions for SSH key if it exists.

mkdir -p -m 0700 /root/.ssh
if [ ! -e "/root/.ssh/config" ]; then
  echo -e "Host *\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config
else
  grep "StrictHostKeyChecking no" /root/.ssh/config || echo -e "Host *\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config
fi
if [ -e "/root/.ssh/id_rsa" ]; then
  chmod 0600 /root/.ssh/id_rsa
fi


# Setup git variables
if [ ! -z "$GIT_EMAIL" ]; then
 git config --global user.email "$GIT_EMAIL"
fi
if [ ! -z "$GIT_NAME" ]; then
 git config --global user.name "$GIT_NAME"
 git config --global push.default simple
fi

# Install Extras
if [ ! -z "$RPMS" ]; then
 yum install -y $RPMS
fi

# Install Composer globally
php -r "readfile('https://getcomposer.org/installer');" > /tmp/composer-setup.php
php /tmp/composer-setup.php -- --install-dir=/usr/bin --filename=composer
php -r "unlink('/tmp/composer-setup.php');"

# Pull down code form git for our site!
if [ ! -z "$GIT_REPO" ]; then
  rm /usr/share/nginx/html/*
  if [ ! -z "$GIT_BRANCH" ]; then
    git clone -b $GIT_BRANCH $GIT_REPO /usr/share/nginx/html/
  else
    git clone $GIT_REPO /usr/share/nginx/html/
  fi
  chown -Rf nginx.nginx /usr/share/nginx/*
fi

if [ ! -z "$RUN_COMPOSER" ]; then
  cd /usr/share/nginx/html && composer -n install
fi

# Display PHP error's or not
if [[ "$ERRORS" != "true" ]] ; then
  sed -i -e "s/error_reporting =.*=/error_reporting = E_ALL/g" /etc/php.ini
  sed -i -e "s/display_errors =.*/display_errors = On/g" /etc/php.ini
fi

# Tweak nginx to match the workers to cpu's

procs=$(cat /proc/cpuinfo |grep processor | wc -l)
sed -i -e "s/worker_processes 5/worker_processes $procs/" /etc/nginx/nginx.conf

# Very dirty hack to replace variables in code with ENVIRONMENT values
if [[ "$TEMPLATE_NGINX_HTML" == "1" ]] ; then
  for i in $(env)
  do
    variable=$(echo "$i" | cut -d'=' -f1)
    value=$(echo "$i" | cut -d'=' -f2)
    if [[ "$variable" != '%s' ]] ; then
      replace='\$\$_'${variable}'_\$\$'
      find /usr/share/nginx/html -type f -exec sed -i -e 's/'${replace}'/'${value}'/g' {} \;
    fi
  done
fi

# Again set the right permissions (needed when mounting from a volume)
chown -Rf nginx.nginx /usr/share/nginx/html/

# Start supervisord and services
/usr/bin/supervisord -n -c /etc/supervisord.conf
