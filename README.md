# - Marathon - 


An Ubuntu based Marathon container with the capability of logging to both standard and json format. It comes packaged with Logstash-Forwarder and is managed via Supervisord.

##### Version Information:

* **Container Release:** 1.0.3
* **Mesos:** 0.23.1-0.2.61.ubuntu1404
* **Marathon:** 0.11.1-1.0.432.ubuntu1404

**Services Include**
* **[Marathon](#marathon)** - A cluster wide init framework for Mesos.
* **[Logstash-Forwarder](#logstash-forwarder)** - A lightweight log collector and shipper for use with [Logstash](https://www.elastic.co/products/logstash).
* **[Redpill](#redpill)** - A bash script and healthcheck for supervisord managed services. It is capable of running cleanup scripts that should be executed upon container termination.

---
---
### Index

* [Usage](#usage)
 * [Example Run Command](#example-run-command)
* [Modification and Anatomy of the Project](#modification-and-anatomy-of-the-project)
* [Important Environment Variables](#important-environment-variables)
* [Service Configuration](#service-configuration)
 * [Marathon](#marathon)
 * [Logstash-Forwarder](#logstash-forwarder)
 * [Redpill](#redpill)
* [Troubleshooting](#troubleshooting)

---
---

### Usage
When running the Marathon container in a `production` or `deveopment` environment, the container **MUST** be run with host networking and several environment variables should be specified to function correctly.

* `ENVIRONMENT` - `ENVIRONMENT` will enable or disable serivces and change the value of several other environment variables based on where the container is running (`prod`, `local` etc.). Please see the [Environment](#environment) section under [Important Environment Variables](#important-environment-variables).

* `LIBPROCESS_PORT` - The port that is used to communicate with Mesos. If running on a host with another Mesos framework or an instance of Mesos-Master or Mesos-Slave, this should be set to unique port (default `9000`).

* `MARATHON_MASTER` - The zk url of Mesos Masters.

* `MARATHON_ZK` - The zk url for the Marathon framework.

* `MARATHON_EVENT_SUBSCRIBER` - Enables or Disables event subscriber modules. Currently only `http_callback` is available. This should be set if you intend to use [Bamboo](https://github.com/QubitProducts/bamboo).

For further configuration information, please see the [Marathon](#marathon) service section.

---

### Example Run Command
```
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
```

---
---


### Modification and Anatomy of the Project

**File Structure**
The directory `skel` in the project root maps to the root of the filesystem once the container is built. Files and folders placed there will map to their corrisponding location within the container.

**Init**
The init script (`./init.sh`) found at the root of the directory is the entry process for the container. It's role is to simply set specific environment variables and modify any subsiquently required configuration files.

**Marathon**
The marathon configuration will automatically be generated at runtime, however logging options are specified in `/etc/marathon/log4j.properties`.

**Supervisord**
All supervisord configs can be found in `/etc/supervisor/conf.d/`. Services by default will redirect their stdout to `/dev/fd/1` and stderr to `/dev/fd/2` allowing for service's console output to be displayed. Most applications can log to both stdout and their respecively specified log file.

In some cases (such as with zookeeper), it is possible to specify different logging levels and formats for each location.

**Logstash-Forwarder**
The Logstash-Forwarder binary and default configuration file can be found in `/skel/opt/logstash-forwarder`. It is ideal to bake the Logstash Server certificate into the base container at this location. If the certificate is called `logstash-forwarder.crt`, the default supplied Logstash-Forwarder config should not need to be modified, and the server setting may be passed through the `SERICE_LOGSTASH_FORWARDER_ADDRESS` environment variable.

In practice, the supplied Logstash-Forwarder config should be used as an example to produce one tailored to each deployment.

---
---

### Important Environment Variables

#### Defaults

| **Variable**                      | **Default**                            |
|-----------------------------------|----------------------------------------|
| `ENVIRONMENT_INIT`                |                                        |
| `APP_NAME`                        | `marathon`                             |
| `ENVIRONMENT`                     | `local`                                |
| `PARENT_HOST`                     | `unknown`                              |
| `JAVA_OPTS`                       |                                        |
| `LIBPROCESS_IP`                   |                                        |
| `LIBPROCESS_PORT`                 | `9000`                                 |
| `MARATHON_LOG_DIR`                | `/var/log/marathon`                    |
| `MARATHON_LOG_FILE`               | `marathon.log`                         |
| `MARATHON_LOG_FILE_LAYOUT`        | `json`                                 |
| `MARATHON_LOG_FILE_THRESHOLD`     |                                        |
| `MARATHON_LOG_STDOUT_LAYOUT`      | `standard`                             |
| `MARATHON_LOG_STDOUT_THRESHOLD`   |                                        |
| `SERVICE_LOGSTASH_FORWARDER`      |                                        |
| `SERVICE_LOGSTASH_FORWARDER_CONF` | `/opt/logstash-forwarder/marathon.log` |
| `SERVICE_REDPILL`                 |                                        |
| `SERVICE_REDPILL_MONITOR`         | `marathon`                             |

#### Description

* `ENVIRONMENT_INIT` - If set, and the file path is valid. This will be sourced and executed before **ANYTHING** else. Useful if supplying an environment file or need to query a service such as consul to populate other variables.

* `APP_NAME` - A brief description of the container. If Logstash-Forwarder is enabled, this will populate the `app_name` field in the Logstash-Forwarder configuration file.

* `ENVIRONMENT` - Sets defaults for several other variables based on the current running environment. Please see the [environment](#environment) section for further information. If logstash-forwarder is enabled, this value will populate the `environment` field in the logstash-forwarder configuration file.

* `PARENT_HOST` - The name of the parent host. If Logstash-Forwarder is enabled, this will populate the `parent_host` field in the Logstash-Forwarder configuration file.

* `JAVA_OPTS` - The Java environment variables that will be passed to Marathon at runtime. Generally used for adjusting memory allocation (`-Xms` and `-Xmx`).

* `LIBPROCESS_IP` - The IP used to communicate with Mesos.

* `LIBPROCESS_PORT` - The port that will be used for communicating with Mesos.

* `MARATHON_LOG_DIR` - The directory in which the Marathon log files will be stored.

* `MARATHON_LOG_FILE` - The name of the Marathon log file.

* `MARATHON_LOG_FILE_LAYOUT` - The log format or layout to be used for the file logger. There are two available formats, `standard` and `json`. The `standard` format is more humanly readable and is the Marathon default. The `json` format is easier for log processing by applications such as logstash. (**Options:** `standard` or `json`).

* `MARATHON_LOG_FILE_THRESHOLD` - The log level to be used for the file logger. (**Options:** `FATAL`, `ERROR`, `WARN`, `INFO`, `DEBUG`, `TRACE`, and `ALL`)

* `MARATHON_LOG_STDOUT_LAYOUT` - The log format or layout to be used for console output. There are two available formats, `standard` and `json`. The `standard` format is more humanly readable and is the Marathon default. The `json` format is easier for log processing by applications such as logstash. (**Options:** `standard` or `json`).

* `MARATHON_LOG_STDOUT_THRESHOLD`  The log level to be used for console output. (**Options:** `FATAL`, `ERROR`, `WARN`, `INFO`, `DEBUG`, `TRACE`, and `ALL`)

* `SERVICE_LOGSTASH_FORWARDER` - Enables or disables the Logstash-Forwarder service. Set automatically depending on the `ENVIRONMENT`. See the Environment section below.  (**Options:** `enabled` or `disabled`)

* `SERVICE_LOGSTASH_FORWARDER_CONF` - The path to the logstash-forwarder configuration.

* `SERVICE_REDPILL` - Enables or disables the Redpill service. Set automatically depending on the `ENVIRONMENT`. See the Environment section below.  (**Options:** `enabled` or `disabled`)

* `SERVICE_REDPILL_MONITOR` - The name of the supervisord service(s) that the Redpill service check script should monitor.

---


#### Environment

* `local` (default)

| **Variable**                    | **Default**                |
|---------------------------------|----------------------------|
| `JAVA_OPTS`                     | `-Xmx256m`                 |
| `MARATHON_HOSTNAME`             | `<first ip bound to eth0>` |
| `MARATHON_LOG_FILE_THRESHOLD`   | `WARN`                     |
| `MARATHON_LOG_STDOUT_THRESHOLD` | `WARN`                     |
| `SERVICE_LOGSTASH_FORWARDER`    | `disabled`                 |
| `SERVICE_REDPILL`               | `enabled`                  |


* `prod`|`production`|`dev`|`development`

| **Variable**                    | **Default**         |
|---------------------------------|---------------------|
| `JAVA_OPTS`                     | `-Xms384m -Xmx512m` |
| `MARATHON_LOG_FILE_THRESHOLD`   | `WARN`              |
| `MARATHON_LOG_STDOUT_THRESHOLD` | `WARN`              |
| `SERVICE_LOGSTASH_FORWARDER`    | `enabled`           |
| `SERVICE_REDPILL`               | `enabled`           |


* `debug`

| **Variable**                    | **Default**         |
|---------------------------------|---------------------|
| `JAVA_OPTS`                     | `-Xms384m -Xmx512m` |
| `MARATHON_LOG_FILE_THRESHOLD`   | `DEBUG`             |
| `MARATHON_LOG_STDOUT_THRESHOLD` | `DEBUG`             |
| `SERVICE_LOGSTASH_FORWARDER`    | `disabled`          |
| `SERVICE_REDPILL`               | `disabled`          |


---
---

### Service Configuration

---

### Marathon
Marathon is a "cluster-wide init and control system for services in cgroups or Docker containers", and the team from [Mesophere](https://mesosphere.github.io/marathon/docs/command-line-flags.html) have done an outstanding job of [documenting it](https://mesosphere.github.io/marathon/).

A list of the Marathon command line flags can be found in their [Reference](https://mesosphere.github.io/marathon/docs/command-line-flags.html) docs.
Alternatively, you can execute the following command to print the available options with the container itself:

`docker run -it --rm marathon java -cp /usr/share/java:/usr/bin/marathon mesosphere.marathon.Main --help`

In addition to the above Marathon configuration, some specific logging options have been added via the following variables:

##### Defaults
| **Variable**                    | **Default**         |
|---------------------------------|---------------------|
| `MARATHON_LOG_DIR`              | `/var/log/marathon` |
| `MARATHON_LOG_FILE`             | `marathon.log`      |
| `MARATHON_LOG_FILE_LAYOUT`      | `json`              |
| `MARATHON_LOG_FILE_THRESHOLD`   |                     |
| `MARATHON_LOG_STDOUT_LAYOUT`    | `standard`          |
| `MARATHON_LOG_STDOUT_THRESHOLD` |                     |

##### Description
* `MARATHON_LOG_DIR` - The directory in which the Marathon log files will be stored.

* `MARATHON_LOG_FILE` - The name of the Marathon log file.

* `MARATHON_LOG_FILE_LAYOUT` - The log format or layout to be used for the file logger. There are two available formats, `standard` and `json`. The `standard` format is more humanly readable and is the marathon default. The `json` format is easier for log processing by applications such as logstash. (**Options:** `standard` or `json`).

* `MARATHON_LOG_FILE_THRESHOLD` - The log level to be used for the file logger. (**Options:** `FATAL`, `ERROR`, `WARN`, `INFO`, `DEBUG`, `TRACE`, and `ALL`)

* `MARATHON_LOG_STDOUT_LAYOUT` - The log format or layout to be used for console output. There are two available formats, `standard` and `json`. The `standard` format is more humanly readable and is the marathon default. The `json` format is easier for log processing by applications such as logstash. (**Options:** `standard` or `json`).

* `MARATHON_LOG_STDOUT_THRESHOLD`  The log level to be used for console output. (**Options:** `FATAL`, `ERROR`, `WARN`, `INFO`, `DEBUG`, `TRACE`, and `ALL`)


---

### Logstash-Forwarder

Logstash-Forwarder is a lightweight application that collects and forwards logs to a logstash server endpoint for further processing. For more information see the [Logstash-Forwarder](https://github.com/elastic/logstash-forwarder) project.


#### Logstash-Forwarder Environment Variables

##### Defaults

| **Variable**                         | **Default**                                                                             |
|--------------------------------------|-----------------------------------------------------------------------------------------|
| `SERVICE_LOGSTASH_FORWARDER`         |                                                                                         |
| `SERVICE_LOGSTASH_FORWARDER_CONF`    | `/opt/logstash-forwarer/marathon.conf`                                                  |
| `SERVICE_LOGSTASH_FORWARDER_ADDRESS` |                                                                                         |
| `SERVICE_LOGSTASH_FORWARDER_CERT`    |                                                                                         |
| `SERVICE_LOGSTASH_FORWARDER_CMD`     | `/opt/logstash-forwarder/logstash-forwarder -config=”$SERVICE_LOGSTASH_FORWARDER_CONF”` |

##### Description

* `SERVICE_LOGSTASH_FORWARDER` - Enables or disables the Logstash-Forwarder service. Set automatically depending on the `ENVIRONMENT`. See the Environment section.  (**Options:** `enabled` or `disabled`)

* `SERVICE_LOGSTASH_FORWARDER_CONF` - The path to the logstash-forwarder configuration.

* `SERVICE_LOGSTASH_FORWARDER_ADDRESS` - The address of the Logstash server.

* `SERVICE_LOGSTASH_FORWARDER_CERT` - The path to the Logstash-Forwarder server certificate.

* `SERVICE_LOGSTASH_FORWARDER_CMD` - The command that is passed to supervisor. If overriding, must be an escaped python string expression. Please see the [Supervisord Command Documentation](http://supervisord.org/configuration.html#program-x-section-settings) for further information.

---

### Redpill

Redpill is a small script that performs status checks on services managed through supervisor. In the event of a failed service (FATAL) Redpill optionally runs a cleanup script and then terminates the parent supervisor process.


#### Redpill Environment Variables

##### Defaults

| **Variable**               | **Default**  |
|----------------------------|--------------|
| `SERVICE_REDPILL`          |              |
| `SERVICE_REDPILL_MONITOR`  | `marathon`   |
| `SERVICE_REDPILL_INTERVAL` |              |
| `SERVICE_REDPILL_CLEANUP`  |              |

##### Description

* `SERVICE_REDPILL` - Enables or disables the Redpill service. Set automatically depending on the `ENVIRONMENT`. See the Environment section.  (**Options:** `enabled` or `disabled`)

* `SERVICE_REDPILL_MONITOR` - The name of the supervisord service(s) that the Redpill service check script should monitor. 

* `SERVICE_REDPILL_INTERVAL` - The interval in which Redpill polls supervisor for status checks. (Default for the script is 30 seconds)

* `SERVICE_REDPILL_CLEANUP` - The path to the script that will be executed upon container termination.


##### Redpill Script Help Text
```
root@c90c98ae31e1:/# /opt/scripts/redpill.sh --help
Redpill - Supervisor status monitor. Terminates the supervisor process if any specified service enters a FATAL state.

-c | --cleanup    Optional path to cleanup script that should be executed upon exit.
-h | --help       This help text.
-i | --inerval    Optional interval at which the service check is performed in seconds. (Default: 30)
-s | --service    A comma delimited list of the supervisor service names that should be monitored.
```

---
---

### Troubleshooting

In the event of an issue, the `ENVIRONMENT` variable can be set to `debug`.  This will stop the container from shipping logs and prevent it from terminating if one of the services enters a failed state.

If a higher level of logging is required, override either `MARATHON_LOG_FILE_THRESHOLD` or `MARATHON_LOG_STDOUT_THRESHOLD` with `TRACE` or `ALL`. Please note - this logging level is incredibly verbose. Only set it to that level if truly necessary.


