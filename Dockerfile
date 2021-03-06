#FROM python:2.7.12
FROM ubuntu:latest
MAINTAINER = Joy Rahman <joyrahman@gmail.com>
ENV DEBIAN_FRONTEND noninteractive

#shall mention base?

EXPOSE 5000 35357
ENV KEYSTONE_VERSION 10.0.0
ENV KEYSTONE_ADMIN_PASSWORD passw0rd
ENV KEYSTONE_DB_ROOT_PASSWD passw0rd
ENV KEYSTONE_DB_PASSWD passw0rd

LABEL version="$KEYSTONE_VERSION"
LABEL description="Openstack Keystone Docker Image"

#RUN apt-get -y update
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils
RUN apt-get install -y apt-utils




RUN export DEBIAN_FRONTEND="noninteractive" \
    && echo "mysql-server mysql-server/root_password password $KEYSTONE_DB_ROOT_PASSWD" | debconf-set-selections \
    && echo "mysql-server mysql-server/root_password_again password $KEYSTONE_DB_ROOT_PASSWD" | debconf-set-selections \
    && apt-get -y update && apt-get install -y mysql-server && apt-get -y clean

RUN apt-get install -y software-properties-common
RUN add-apt-repository cloud-archive:newton -y
RUN apt-get -y update
RUN apt-get install python-openstackclient mysql-client  -y
RUN apt-get -y clean

RUN apt-get install -y keystone


WORKDIR /keystone

#
COPY ./etc/keystone.conf /etc/keystone/keystone.conf
#complete these two files
COPY keystone.sql /root/keystone.sql  
COPY bootstrap.sh /root/bootstrap.sh
ENV DEBIAN_FRONTEND teletype
RUN chown root:root /root/bootstrap.sh
RUN chmod 700 /root/bootstrap.sh
WORKDIR /root
#CMD sh -x /root/bootstrap.sh
#CMD ["/root/bootstrap.sh", "-d"]

CMD ["/root/bootstrap.sh", "-bash"]
