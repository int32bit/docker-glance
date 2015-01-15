# How to build
```bash
docker  build --rm -t="krystism/glance"
```

# Start a instance
Before start a glance instance, mysql and keystone service are required, we need mysql image and 
keystone image, you can pull these images before start a glance instance! 
```bash
docker run -d -e MYSQL_ROOT_PASSWORD=MYSQL_DBPASS -h mysql --name mysql -d mariadb:latest
docker rm -f glance
docker run -d\
      	--link mysql:mysql \
       	--link keystone:keystone \
	-e OS_USERNAME=admin \
	-e OS_PASSWORD=ADMIN_PASS \
	-e OS_AUTH_URL=http://keystone:5000/v2.0 \
	-e OS_TENANT_NAME=admin \
	--name glance \
	-h glance \
	krystism/glance:latest
```
It may takes some time to execute initscript, you just need to do is wait about 5s, you can use docker logs to fetch
some info from the instance, once the work is done, you can check if it really works:
```bash
docker exec -t -i glance bash
cd /root
source admin-openrc.sh
glance image-list
wget http://cdn.download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img
glance image-create --name "cirros-0.3.3-x86_64" --file cirros-0.3.3-x86_64-disk.img \
--disk-format qcow2 --container-format bare --is-public True --progress
glance image-list
```
