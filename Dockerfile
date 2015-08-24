# vim:set ft=dockerfile:
FROM ubuntu:vivid

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r mysql && useradd -r -g mysql mysql

RUN mkdir /docker-entrypoint-initdb.d

#Install Webscale 

RUN apt-get update
#RUN apt-get upgrade
RUN apt-get install -y bison cmake g++ gcc git libaio-dev libncurses5-dev libreadline-dev make

RUN git clone https://github.com/webscalesql/webscalesql-5.6.git
RUN cd webscalesql-5.6 && \
    cmake . -DBUILD_CONFIG=mysql_release -DENABLE_DOWNLOADS=1 && \
    make && \
    make install && \
    cd .. && \
    rm -rf webscalesql-5.6
RUN cd /usr/local/mysql && \
    chown -R mysql . && \
    chgrp -R mysql . && \
    scripts/mysql_install_db --user=mysql && \
    chown -R root . && \
    chown -R mysql data && \
    echo "bind-address = 0.0.0.0" >> my.cnf && \
    cp support-files/mysql.server /etc/init.d/mysql.server


# comment out a few problematic configuration values
# don't reverse lookup hostnames, they are usually another container
RUN sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/my.cnf \
	&& echo 'skip-host-cache\nskip-name-resolve' | awk '{ print } $1 == "[mysqld]" && c == 0 { c = 1; system("cat") }' /etc/mysql/my.cnf > /tmp/my.cnf \
	&& mv /tmp/my.cnf /etc/mysql/my.cnf

VOLUME /var/lib/mysql

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 3306
CMD ["mysqld"]
