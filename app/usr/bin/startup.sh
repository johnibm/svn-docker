#!/bin/sh
# Perform startup tasks here
echo "Running startup script"
echo "Apache - run"
#!/usr/bin/with-contenv sh

# From https://github.com/smebberson/docker-alpine/tree/master/alpine-apache

# avoid 'already pid is running' error
rm -f /run/apache2/httpd.pid

#fix bug in exec 
#exec /usr/sbin/apachectl -DFOREGROUND;
/usr/sbin/httpd -DBACKGROUND


echo "subversion - run"
#!/usr/bin/with-contenv sh

# From https://github.com/smebberson/docker-alpine/tree/master/alpine-apache

#exec /usr/bin/svnserve -d --foreground -r /home/svn --listen-port 3690;
/usr/bin/svnserve -d -r /home/svn --listen-port 3690;


# Run the main container command (CMD)
exec "$@"

