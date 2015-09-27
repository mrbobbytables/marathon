#!/bin/bash
docker run -d --net=host \
-e ENVIRONMENT=production \
-e PARENT_HOST=$(hostname) \
-e LIBPROCESS_PORT=9100 \
-e MARATHON_MASTER=zk://10.10.0.11:2181,10.10.0.12:2181,10.10.0.13:2181/mesos \
-e MARATHON_ZK=zk://10.10.0.11:2181,10.10.0.12:2181,10.10.0.13:2181/marathon \
-e MARATHON_FRAMEWORK_NAME=marathon \
-e MARATHON_HOSTNAME=192.168.0.11 \
-e MARATHON_EVENT_SUBSCRIBER=http_callback \
-e MARATHON_ZK_MAX_VERSIONS=5 \
marathon
