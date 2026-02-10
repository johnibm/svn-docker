# Alpine Linux with s6 service management
# FROM smebberson/alpine-base:3.2.0
# Updated to build from scratch
FROM alpine:3.9
LABEL Scott Mebberson (https://github.com/smebberson/docker-alpine)

# Add s6-overlay
ENV S6_OVERLAY_VERSION=v1.22.1.0 \
    GO_DNSMASQ_VERSION=1.0.7

RUN apk add --update --no-cache bind-tools curl libcap && \
    curl -sSL https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-amd64.tar.gz \
    | tar xfz - -C / && \
    curl -sSL https://github.com/janeczku/go-dnsmasq/releases/download/${GO_DNSMASQ_VERSION}/go-dnsmasq-min_linux-amd64 -o /bin/go-dnsmasq && \
    chmod +x /bin/go-dnsmasq && \
    apk del curl && \
    # create user and give binary permissions to bind to lower port
    addgroup go-dnsmasq && \
    adduser -D -g "" -s /bin/sh -G go-dnsmasq go-dnsmasq && \
    setcap CAP_NET_BIND_SERVICE=+eip /bin/go-dnsmasq

# Modified to run on OpenShift
#COPY --chmod=0755 root / 
#COPY --chmod=0755 app /app
# Change the group ownership of the directory to root (GID 0) 
# and grant group read/write/execute permissions (g=u copies owner permissions, which should work in most base images)
#RUN chgrp -R 0 /app && \
#    chmod -R g=u /app && \
    # Ensure the startup script is executable
#    chmod +x /app/usr/bin/startup.sh

# Create a non-root user and group
# OpenShift usually runs containers with an arbitrary UID,
# but providing a specific non-root user aids compatibility 
RUN addgroup -S svngroup -g 3001 && adduser -S svnuser -G svngroup -u 1001


# 2. Set working directory
WORKDIR /app

# 3. Copy application files and set permissions
# Change ownership to the new non-root user 
COPY --chown=svnuser:svngroup app /app

# 4. Ensure permissions are correct (executable if needed)
RUN chmod 775 /app
RUN chgrp -R 0 /app && \
    chmod -R g=u /app && \
    # Ensure the startup script is executable
    chmod +x /app/usr/bin/startup.sh

# Old entries
#ENTRYPOINT ["/init"]
#CMD []


	# Install Apache2 and other stuff needed to access svn via WebDav
	# Install svn
	# Installing utilities for SVNADMIN frontend
	# Create required folders
	# Create the authentication file for http access
	# Getting SVNADMIN interface
RUN apk add --no-cache apache2 apache2-utils apache2-webdav mod_dav_svn &&\
	apk add --no-cache subversion &&\
	apk add --no-cache wget unzip php7 php7-apache2 php7-session php7-json php7-ldap &&\
	apk add --no-cache php7-xml &&\	
	sed -i 's/;extension=ldap/extension=ldap/' /etc/php7/php.ini &&\
	mkdir -p /run/apache2/ &&\
	mkdir /home/svn/ &&\
	mkdir /etc/subversion &&\
	touch /etc/subversion/passwd &&\
    wget --no-check-certificate https://github.com/mfreiholz/iF.SVNAdmin/archive/stable-1.6.2.zip &&\
	unzip stable-1.6.2.zip -d /opt &&\
	rm stable-1.6.2.zip &&\
	mv /opt/iF.SVNAdmin-stable-1.6.2 /opt/svnadmin &&\
	ln -s /opt/svnadmin /var/www/localhost/htdocs/svnadmin &&\
	chmod -R 777 /opt/svnadmin/data 

# Solve a security issue (https://alpinelinux.org/posts/Docker-image-vulnerability-CVE-2019-5021.html)	
RUN sed -i -e 's/^root::/root:!:/' /etc/shadow

# Fixing https://github.com/mfreiholz/iF.SVNAdmin/issues/118
ADD svnadmin/classes/util/global.func.php /opt/svnadmin/classes/util/global.func.php

# Add services configurations
ADD apache/ /etc/services.d/apache/
ADD subversion/ /etc/services.d/subversion/

# Add SVNAuth file
ADD subversion-access-control /etc/subversion/subversion-access-control
RUN chmod a+w /etc/subversion/* && chmod a+w /home/svn

# Add WebDav configuration
ADD dav_svn.conf /etc/apache2/conf.d/dav_svn.conf

# Update Apache config file
ADD /app/etc/apache2/httpd.conf /etc/apache2/httpd.conf

# Add subversion passwd
ADD /subversion/passwd /etc/subversion/passwd

# Fix permissions issue
#RUN chmod 644 /etc/apache2/conf.d/dav_svn.conf
RUN chmod -R 0777 /etc/apache2 &&\
    chown -R svnuser:svngroup /etc/apache2 &&\
	chmod -R 0777 /var/www &&\
	chmod -R 0777 /var/log/apache2 &&\
	chown -R svnuser:svngroup /run/apache2
	chown -R svnuser:svngroup /etc/subversion/passwd



# Set HOME in non /root folder
ENV HOME /home/svnuser

# Switch to a non-root user (security best practice)
USER svnuser

# Expose ports for http and custom protocol access
EXPOSE 8080 3690

ENTRYPOINT ["./usr/bin/startup.sh"]

# Set the default command (e.g., to keep the container running)
CMD ["sleep", "infinity"] 
