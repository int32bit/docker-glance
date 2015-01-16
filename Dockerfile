FROM krystism/openstack_base:juno
MAINTAINER krystism "krystism@gmail.com"
# install packages
RUN apt-get -y install glance python-glanceclient python-keystoneclient

# remove the SQLite database file
#
RUN rm -f /var/lib/glance/glance.sqlite

EXPOSE 9191 9292
#copy sql script
COPY glance.sql /root/glance.sql

#copy glance config file
COPY glance-api.conf /etc/glance/glance-api.conf
COPY glance-registry.conf /etc/glance/glance-registry.conf

# add bootstrap script and make it executable
COPY bootstrap.sh /etc/bootstrap.sh
RUN chown root.root /etc/bootstrap.sh
RUN chmod 744 /etc/bootstrap.sh

ENTRYPOINT ["/etc/bootstrap.sh"]
