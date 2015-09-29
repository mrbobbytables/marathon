################################################################################
# marathon:1.1.0
# Date: 9/29/2015
# Marathon Version: 0.10.1-1.0.416.ubuntu1404
# Mesos Version: 0.24.1-0.2.35.ubuntu1404
#
# Description:
# Marathon Mesos framework. Made for executing long running processes
################################################################################

FROM mrbobbytables/mesos-base:1.1.0
MAINTAINER Bob Killen / killen.bob@gmail.com / @mrbobbytables


ENV VERSION_MARATHON=0.10.1-1.0.416.ubuntu1404

RUN apt-get -y update                   \
 && apt-get -y install                  \
    marathon=0.10.1-1.0.416.ubuntu1404  \
 && mkdir -p /etc/marathon/conf         \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
   
COPY ./skel /

RUN chmod +x init.sh  \
 && chown -R logstash-forwarder:logstash-forwarder /opt/logstash-forwarder                                                      \
 && wget -P /usr/share/java http://central.maven.org/maven2/net/logstash/log4j/jsonevent-layout/1.7/jsonevent-layout-1.7.jar    \
 && wget -P /usr/share/java http://central.maven.org/maven2/commons-lang/commons-lang/2.6/commons-lang-2.6.jar                  \
 && wget -P /usr/share/java http://central.maven.org/maven2/junit/junit/4.12/junit-4.12.jar                                     \
 && wget -P /usr/share/java https://json-smart.googlecode.com/files/json-smart-1.2.jar

ENV JSONLOG4JCP=$JAVACPROOT/jsonevent-layout-1.7.jar:$JAVACPROOT/junit-4.12.jar/:$JAVACPROOT/commons-lang-2.6.jar:$JAVACPROOT/json-smart-1.2.jar 

#marathon web and LIBPROCESS_PORT
EXPOSE 8080 9000

CMD ["./init.sh"]
