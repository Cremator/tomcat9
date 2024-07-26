ARG TOMCAT_VERSION
ARG TOMCAT_FROM_IMAGE="tomcat:${TOMCAT_VERSION}"
FROM ${TOMCAT_FROM_IMAGE}
LABEL org.opencontainers.image.authors="gchompalov@bulmag.bg,snikolov@telehouse.bg"
RUN set -ex \
&& apt-get update \
&& echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections \
&& echo ttf-mscorefonts-installer msttcorefonts/present-mscorefonts-eula note | debconf-set-selections \
&& apt-get install -y ttf-mscorefonts-installer xmlstarlet
RUN cp /usr/local/tomcat/conf/tomcat-users.xml /usr/local/tomcat/conf/tomcat-users.xml.dist
RUN cp /usr/local/tomcat/conf/context.xml /usr/local/tomcat/conf/context.xml.dist
RUN cp -r /usr/local/tomcat/webapps.dist/* /usr/local/tomcat/webapps/
RUN cp /usr/local/tomcat/webapps/manager/META-INF/context.xml /usr/local/tomcat/webapps/manager/META-INF/context.xml.dist
RUN cp /usr/local/tomcat/webapps/host-manager/META-INF/context.xml /usr/local/tomcat/webapps/host-manager/META-INF/context.xml.dist
RUN cp /usr/local/tomcat/webapps/examples/META-INF/context.xml /usr/local/tomcat/webapps/examples/META-INF/context.xml.dist
RUN cp /usr/local/tomcat/webapps/docs/META-INF/context.xml /usr/local/tomcat/webapps/docs/META-INF/context.xml.dist
COPY libs/*.jar /usr/local/tomcat/lib/
COPY --chmod=0755 populate-xml-from-env.sh /usr/local/bin/
CMD ["/bin/bash", "-c", "/usr/local/bin/populate-xml-from-env.sh && catalina.sh run"]
