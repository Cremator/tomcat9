#!/bin/bash
# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Copyright (C) 2024 Georgi Chompalov & Stefan Nikolov  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#TOMCAT_USERS='admin1&password1&role1 user2&password2&role2,role3'
if [[ -n "$TOMCAT_USERS" ]]
    then
    usersarr=( $TOMCAT_USERS )
    CMD="xmlstarlet ed "
    for user in ${usersarr[@]}
        do
            userspec=( ${user//&/ } )
            CMD+="-s '/_:tomcat-users' -t elem -n user -s '/_:tomcat-users/user[not(@username)]' -t attr -n username -v ${userspec[0]} -s '/_:tomcat-users/user[not(@password)]' -t attr -n password -v ${userspec[1]} -s '/_:tomcat-users/user[not(@roles)]' -t attr -n roles -v ${userspec[2]} "
        done
    CMD+="/usr/local/tomcat/conf/tomcat-users.xml.dist > /usr/local/tomcat/conf/tomcat-users.xml"
    eval $CMD
else 
    echo "TOMCAT_USERS environment variable is not set."
fi
#TOMCAT_ALLOW='manager&.* host-manager&.* examples&.* docs&.*'
if [[ -n "$TOMCAT_ALLOW" ]]
    then
    allowarr=( $TOMCAT_ALLOW )
    for allow in ${allowarr[@]}
        do
            allowspec=( ${allow//&/ } )
            xmlstarlet ed -u '/Context/Valve[@allow]/@allow' -v "${allowspec[1]}" /usr/local/tomcat/webapps/${allowspec[0]}/META-INF/context.xml.dist > /usr/local/tomcat/webapps/${allowspec[0]}/META-INF/context.xml
        done
else 
    echo "TOMCAT_ALLOW environment variable is not set."
fi
#TOMCAT_APP='name&jdbc/ApplicationDS auth&Container type&javax.sql.DataSource driverClassName&oracle.jdbc.driver.OracleDriver url&jdbc:oracle:thin:@localhost:1521:ORCL1 username&someuser password&s3cr3t maxTotal&200 maxIdle&10'
if [[ -n "$TOMCAT_APP" ]]
    then
    apparr=( $TOMCAT_APP )
    CMD="xmlstarlet ed -s '/Context' -t elem -n JarScanner -s '/Context/JarScanner[not(@scanManifest)]' -t attr -n scanManifest -v 'false' -s '/Context' -t elem -n Resource "
    for app in ${apparr[@]}
        do
            appspec=( ${app//&/ } )
            CMD+="-s '/Context/Resource[not(@${appspec[0]})]' -t attr -n ${appspec[0]} -v '${appspec[1]}' "
        done
    CMD+="/usr/local/tomcat/conf/context.xml.dist > /usr/local/tomcat/conf/context.xml"
    eval $CMD
else 
    echo "TOMCAT_APP environment variable is not set."
fi
#TOMCAT_CONN='maxParameterCount&50000'
if [[ -n "$TOMCAT_CONN" ]]
    then
    connarr=( $TOMCAT_CONN )
    for conn in ${connarr[@]}
        do
            connspec=( ${conn//&/ } )
            xmlstarlet ed -u "/Server/Service/Connector[@${connspec[0]}]/@${connspec[0]}" -v "${connspec[1]}" /usr/local/tomcat/conf/server.xml.dist > /usr/local/tomcat/conf/server.xml
        done
else 
    echo "TOMCAT_ALLOW environment variable is not set."
fi