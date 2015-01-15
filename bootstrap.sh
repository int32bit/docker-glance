#!/bin/bash
# create database for glance
export MYSQL_ROOT_PASSWORD=${MYSQL_ENV_MYSQL_ROOT_PASSWORD}
export MYSQL_HOST=mysql
SQL_SCRIPT=/root/glance.sql
mysql -uroot -p$MYSQL_ROOT_PASSWORD -h $MYSQL_HOST <$SQL_SCRIPT

# To create the Identity service credentials
KEYSTONE_HOST=${KEYSTONE_HOST:-keystone}
GLANCE_USER_NAME=${GLANCE_USER_NAME:-glance}
GLANCE_PASSWORD=${GLANCE_PASSWORD:-GLANCE_PASS}
GLANCE_HOST=${GLANCE_HOST:-$HOSTNAME}
export OS_USERNAME=${OS_USERNAME:-admin}
export OS_PASSWORD=${OS_PASSWORD:-ADMIN_PASS}
export OS_TENANT_NAME=${OS_TENANT_NAME:-admin}
export OS_AUTH_URL=${OS_AUTH_URL:-http://${KEYSTONE_HOST}:35357/v2.0}
keystone user-create --name $GLANCE_USER_NAME --pass $GLANCE_PASSWORD
keystone user-role-add --user glance --tenant service --role admin
keystone service-create --name glance --type image --description "OpenStack Image Service"
keystone endpoint-create \
	--service-id $(keystone service-list | awk '/ image / {print $2}') \
	--publicurl http://${GLANCE_HOST}:9292 \
	--internalurl http://${GLANCE_HOST}:9292 \
	--adminurl http://${GLANCE_HOST}:9292 \
	--region regionOne


# update glance-api.conf
API_CONFIG_FILE=/etc/glance/glance-api.conf
sed -i "s#^connection.*=.*#connection = mysql://glance:GLANCE_DBPASS@${MYSQL_HOST}/glance#" $API_CONFIG_FILE
sed -i "s#^auth_uri.*=.*#auth_uri = http://${KEYSTONE_HOST}:5000/v2.0#" $API_CONFIG_FILE
sed -i "s#^identity_uri.*=.*#identity_uri = http://${KEYSTONE_HOST}:35357#" $API_CONFIG_FILE
sed -i "s#^admin_user.*=.*#admin_user = ${GLANCE_USER_NAME}#" $API_CONFIG_FILE
sed -i "s#^admin_password.*=.*#admin_password = ${GLANCE_PASSWORD}#" $API_CONFIG_FILE

# update glance-registry.conf
REGISTRY_CONFIG_FILE=/etc/glance/glance-registry.conf
sed -i "s#^connection.*=.*#connection = mysql://glance:GLANCE_DBPASS@${MYSQL_HOST}/glance#" $REGISTRY_CONFIG_FILE
sed -i "s#^auth_uri.*=.*#auth_uri = http://${KEYSTONE_HOST}:5000/v2.0#" $REGISTRY_CONFIG_FILE
sed -i "s#^identity_uri.*=.*#identity_uri = http://${KEYSTONE_HOST}:35357#" $REGISTRY_CONFIG_FILE
sed -i "s#^admin_user.*=.*#admin_user = ${GLANCE_USER_NAME}#" $REGISTRY_CONFIG_FILE
sed -i "s#^admin_password.*=.*#admin_password = ${GLANCE_PASSWORD}#" $REGISTRY_CONFIG_FILE

# sync the database
su -s /bin/sh -c "glance-manage db_sync" glance

# create a admin-openrc.sh file
ADMIN_OPENRC=/root/admin-openrc.sh
cat >$ADMIN_OPENRC <<EOF
export OS_TENANT_NAME=$OS_TENANT_NAME
export OS_USERNAME=$OS_USERNAME
export OS_PASSWORD=$OS_PASSWORD
export OS_AUTH_URL=$OS_AUTH_URL
EOF

# start glance service
glance-registry &
sleep 5
glance-api

