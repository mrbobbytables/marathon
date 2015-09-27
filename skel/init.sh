#!/bin/bash

########## Marathon ##########
# Init script for Marathon
########## Marathon ##########

source /opt/scripts/container_functions.lib.sh

init_vars() {

  if [[ $ENVIRONMENT_INIT && -f $ENVIRONMENT_INIT ]]; then
      source "$ENVIRONMENT_INIT"
  fi 

  if [[ ! $PARENT_HOST && $HOST ]]; then
    export PARENT_HOST="$HOST"
  fi

  export APP_NAME=${APP_NAME:-marathon}
  export ENVIRONMENT=${ENVIRONMENT:-local}
  export PARENT_HOST=${PARENT_HOST:-unknown}

  export LIBPROCESS_PORT=${LIBPROCESS_PORT:-9000}

  export MARATHON_LOG_STDOUT_LAYOUT=${MARATHON_LOG_STDOUT_LAYOUT:-standard}
  export MARATHON_LOG_DIR=${MARATHON_LOG_DIR:-/var/log/marathon}
  export MARATHON_LOG_FILE=${MARATHON_LOG_FILE:-marathon.log}
  export MARATHON_LOG_FILE_LAYOUT=${MARATHON_LOG_FILE_LAYOUT:-json}


  case "${ENVIRONMENT,,}" in
    prod|production|dev|development)
      export JAVA_OPTS=${JAVA_OPTS:-"-Xms384m -Xmx512m"}
      export MARATHON_LOG_STDOUT_THRESHOLD=${MARATHON_LOG_STDOUT_THRESHOLD:-INFO}
      export MARATHON_LOG_FILE_THRESHOLD=${MARATHON_LOG_FILE_THRESHOLD:-INFO}
      export SERVICE_LOGSTASH_FORWARDER=${SERVICE_LOGSTASH_FORWARDER:-enabled}
      export SERVICE_REDPILL=${SERVICE_REDPILL:-enabled}
      ;;
    debug)
      export JAVA_OPTS=${JAVA_OPTS:-"-Xms384m -Xmx512m"}
      export MARATHON_LOG_STDOUT_THRESHOLD=${MARATHON_LOG_STDOUT_THRESHOLD:-DEBUG}
      export MARATHON_LOG_FILE_THRESHOLD=${MARATHON_LOG_FILE_THRESHOLD:-DEBUG}
      export SERVICE_LOGSTASH_FORWARDER=${SERVICE_LOGSTASH_FORWARDER:-disabled}
      export SERVICE_REDPILL=${SERVICE_REDPILL:-disabled}
      ;;
   local|*)
      local local_ip="$(ip addr show eth0 | grep -m 1 -P -o '(?<=inet )[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')"
      export JAVA_OPTS=${JAVA_OPTS:-"-Xmx256m"}
      export MARATHON_HOSTNAME=${MARATHON_HOSTNAME:-"$local_ip"}
      export MARATHON_LOG_STDOUT_THRESHOLD=${MARATHON_LOG_STDOUT_THRESHOLD:-INFO}
      export MARATHON_LOG_FILE_THRESHOLD=${MARATHON_LOG_FILE_THRESHOLD:-INFO}
      export SERVICE_LOGSTASH_FORWARDER=${SERVICE_LOGSTASH_FORWARDER:-disabled}
      export SERVICE_REDPILL=${SERVICE_REDPILL:-enabled}
      ;;
  esac 

 export SERVICE_LOGSTASH_FORWARDER_CONF=${SERVICE_LOGSTASH_FORWARDER_CONF:-/opt/logstash-forwarder/marathon.conf}
 export SERVICE_REDPILL_MONITOR=${SERVICE_REDPILL_MONITOR:-marathon}

}


config_marathon() {
  #logging settings for log4j and default JAVA_OPTS
  local log_stdout_layout=""
  local log_file_layout=""
  local marathon_cmd=""

  case "${MARATHON_LOG_STDOUT_LAYOUT,,}" in
    json) log_stdout_layout="net.logstash.log4j.JSONEventLayoutV1";;
    standard|*) log_stdout_layout="org.apache.log4j.PatternLayout";;
  esac

  case "${MARATHON_LOG_FILE_LAYOUT,,}" in
    json) log_file_layout="net.logstash.log4j.JSONEventLayoutV1";;
    standard|*) log_file_layout="org.apache.log4j.PatternLayout";;
  esac

jvm_opts=( "-Djava.library.path=/usr/local/lib:/usr/lib64:/usr/lib"
           "-Dlog4j.configuration=file:/etc/marathon/log4j.properties"
           "-Dlog.stdout.layout=$log_stdout_layout"
           "-Dlog.stdout.threshold=$MARATHON_LOG_STDOUT_THRESHOLD"
           "-Dlog.file.layout=$log_file_layout"
           "-Dlog.file.threshold=$MARATHON_LOG_FILE_THRESHOLD"
           "-Dlog.file.dir=$MARATHON_LOG_DIR"
           "-Dlog.file.name=$MARATHON_LOG_FILE")

  # Append extra JAVA_OPTS to jvm_opts
  for j_opt in $JAVA_OPTS; do
    jvm_opts+=( ${j_opt} )
  done


  # assembles the marathon flags and escape them for supervisor e.g. escape ", % etc.
  # MARATHON_APP is ignored, see this https://github.com/mesosphere/marathon/issues/1143
  for i in $(compgen -A variable | awk '/^MARATHON_/ && !/^MARATHON_APP/ && !/MARATHON_LOG_/'); do
    var_name="--$(echo "${i:9}" | awk '{print tolower($0)}')"
    cmd_flags+=( "$var_name" )
    cmd_flags+=( "${!i}" )
  done
 
  marathon_cmd="java ${jvm_opts[@]}  -cp $JSONLOG4JCP:/usr/bin/marathon mesosphere.marathon.Main ${cmd_flags[@]}"
  export SERVICE_MARATHON_CMD=${SERVICE_MARATHON_CMD:-"$(__escape_svsr_txt "$marathon_cmd")"}
}

main() {

  init_vars

  echo "[$(date)[App-Name] $APP_NAME"
  echo "[$(date)][Environment] $ENVIRONMENT"

  __config_service_logstash_forwarder
  __config_service_redpill

  config_marathon

  echo "[$(date)][Marathon][Start-Command] $SERVICE_MARATHON_CMD" 

  exec supervisord -n -c /etc/supervisor/supervisord.conf

}

main "$@"
