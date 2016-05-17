FROM centos:7
MAINTAINER Kat Andry (kat@cadence.net.uk)

ENV container docker

# Install supervisord
RUN \
  yum update -y && \
  yum install -y epel-release && \
  yum install -y iproute python-setuptools hostname inotify-tools yum-utils which && \
  yum clean all && \
  easy_install supervisor

# Install nginx
RUN rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm && \
yum -y install nginx

# Install php-fpm etc as well as wget/unzip
RUN yum -y install php-fpm php-mysql php-ldap php-cli php-mbstring php-pdo php-pear php-xml php-soap php-gd wget unzip

# Get & extract ionCube Loader
RUN wget -O /tmp/ioncube.tgz http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64_5.1.2.tar.gz && tar -zxf /tmp/ioncube.tgz -C /tmp

# tweak php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php.ini && \
sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php.ini && \
sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php.ini && \
sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php-fpm.conf && \
sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php-fpm.d/www.conf && \
sed -i -e "s/pm.max_children = 5/pm.max_children = 9/g" /etc/php-fpm.d/www.conf && \
sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" /etc/php-fpm.d/www.conf && \
sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" /etc/php-fpm.d/www.conf && \
sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" /etc/php-fpm.d/www.conf && \
sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" /etc/php-fpm.d/www.conf
# tweak nginx config
RUN sed -i -e"s/worker_processes  1/worker_processes 5/" /etc/nginx/nginx.conf && \
sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf && \
sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf && \
echo "daemon off;" >> /etc/nginx/nginx.conf

# nginx site conf
RUN rm -Rf /etc/nginx/conf.d/* && \
mkdir -p /etc/nginx/ssl/
ADD conf/nginx-site.conf /etc/nginx/conf.d/default.conf

# Add git commands to allow container updating
ADD scripts/pull /usr/bin/pull
ADD scripts/push /usr/bin/push
RUN chmod 755 /usr/bin/pull && chmod 755 /usr/bin/push

# Supervisor Config
ADD conf/supervisord.conf /etc/supervisord.conf

# Start Supervisord
ADD scripts/start.sh /start.sh
RUN chmod 755 /start.sh

# Setup Volume
VOLUME ["/usr/share/nginx/html"]

# copy in WHMCS archive
ADD src/whmcs_v631_full.zip /usr/share/nginx/html/whmcs.zip
RUN chown -Rf nginx.nginx /usr/share/nginx/html/

# Expose Ports
EXPOSE 443
EXPOSE 80

CMD ["/bin/bash", "/start.sh"]
