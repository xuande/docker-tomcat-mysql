FROM openjdk:7-jdk
MAINTAINER Manuel de la Peña <manuel.delapenya@liferay.com>

ENV DEBIAN_FRONTEND noninteractive
ENV TOMCAT_MAJOR_VERSION=7
ENV TOMCAT_VERSION=7.0.94
ENV TOMCAT_HOME=/opt/apache-tomcat-$TOMCAT_VERSION

# Prepare the installation of mysql-server and tomcat 7
RUN mkdir -p $TOMCAT_HOME && cd /opt && \
  wget https://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-$TOMCAT_MAJOR_VERSION/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz && \
  tar -xvf apache-tomcat-$TOMCAT_VERSION.tar.gz && rm -f apache-tomcat-$TOMCAT_VERSION.tar.gz

RUN set -ex; \
# gpg: key 5072E1F5: public key "MySQL Release Engineering <mysql-build@oss.oracle.com>" imported
	key='A4A9406876FCBD3C456770C88C718D3B5072E1F5'; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
	gpg --batch --export "$key" > /etc/apt/trusted.gpg.d/mysql.gpg; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME"; \
	apt-key list > /dev/null

ENV MYSQL_MAJOR 5.6
ENV MYSQL_VERSION 5.6.44-1debian9

RUN echo "deb http://repo.mysql.com/apt/debian/ stretch mysql-${MYSQL_MAJOR}" > /etc/apt/sources.list.d/mysql.list


# Install packages
RUN apt-get update && \
  apt-get -y install mysql-server pwgen supervisor && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add image configuration and scripts
ADD start-tomcat.sh /start-tomcat.sh
ADD start-mysqld.sh /start-mysqld.sh
ADD run.sh /run.sh
RUN chmod 755 /*.sh
ADD my.cnf /etc/mysql/conf.d/my.cnf
RUN chmod 644 /etc/mysql/conf.d/my.cnf
ADD supervisord-tomcat.conf /etc/supervisor/conf.d/supervisord-tomcat.conf
ADD supervisord-mysqld.conf /etc/supervisor/conf.d/supervisord-mysqld.conf

# Remove pre-installed database
RUN rm -rf /var/lib/mysql/*

# Add MySQL utils
ADD create_mysql_admin_user.sh /create_mysql_admin_user.sh
ADD mysql-setup.sh /mysql-setup.sh
RUN chmod 755 /*.sh

WORKDIR $TOMCAT_HOME

# Add volumes for MySQL 
VOLUME  ["/etc/mysql", "/var/lib/mysql"]

EXPOSE 8080 3306

ENTRYPOINT ["/run.sh"]
