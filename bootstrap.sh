#!/usr/bin/env bash

HTTP="http"
KEYSTONE_DB_HOST="localhost"
HOSTNAME="controller"
echo "127.0.0.1 $HOSTNAME" >> /etc/hosts



service mysql restart
cat > ~/.my.cnf  <<EOF 
[client]
user = root
password = $KEYSTONE_DB_ROOT_PASSWD
EOF

# ### related to user creation and permission (not necessary)
# addgroup --system keystone >/dev/null || true
# adduser --quiet --system --home /var/lib/keystone \
#         --no-create-home --ingroup keystone --shell /bin/false \
#         keystone || true

# if [ "$(id -gn keystone)"  = "nogroup" ]
# then
#     usermod -g keystone keystone
# fi

# # create appropriate directories
# mkdir -p /var/lib/keystone/ /etc/keystone/ /var/log/keystone/

# # change the permissions on key directories
# chown keystone:keystone -R /var/lib/keystone/ /etc/keystone/ /var/log/keystone/
# chmod 0700 /var/lib/keystone/ /var/log/keystone/ /etc/keystone/




# Keystone Database and user
sed -i 's|KEYSTONE_DB_PASSWD|'"$KEYSTONE_DB_PASSWD"'|g' /keystone.sql
mysql -uroot -p$KEYSTONE_DB_ROOT_PASSWD -h $KEYSTONE_DB_HOST < /keystone.sql

# Update keystone.conf
sed -i "s/KEYSTONE_DB_PASSWORD/$KEYSTONE_DB_PASSWD/g" /etc/keystone/keystone.conf
sed -i "s/KEYSTONE_DB_HOST/$KEYSTONE_DB_HOST/g" /etc/keystone/keystone.conf

#  Populate keystone database & Bootstrap keystone
su -s /bin/sh -c "keystone-manage db_sync" keystone

keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
keystone-manage bootstrap --bootstrap-username admin \
        --bootstrap-password $KEYSTONE_ADMIN_PASSWORD \
        --bootstrap-project-name admin \
        --bootstrap-role-name admin \
        --bootstrap-service-name keystone \
        --bootstrap-admin-url "$HTTP://$HOSTNAME:35357/v3" \
        --bootstrap-public-url "$HTTP://$HOSTNAME:5000/v3" \
        --bootstrap-internal-url "$HTTP://$HOSTNAME:5000/v3"\
        --bootstrap-region-id RegionOne


# [joy] Write openrc to disk
cat > /root/openrc <<EOF
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=${KEYSTONE_ADMIN_PASSWORD}
export OS_AUTH_URL=$HTTP://${HOSTNAME}:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

# Configure Apache2
echo "ServerName $HOSTNAME" >> /etc/apache2/apache2.conf
service apache2 restart
rm -f /var/lib/keystone/keystone.db


# ensite keystone and start apache2
#a2ensite keystone
#apache2ctl -D FOREGROUND

if [[ $1 == "-d" ]]; then
  while true; do sleep 1000; done
fi

if [[ $1 == "-bash" ]]; then
  /bin/bash
fi
