#!/usr/bin/env groovy

import ch.qos.logback.classic.encoder.PatternLayoutEncoder
import ch.qos.logback.classic.filter.ThresholdFilter
import ch.qos.logback.core.ConsoleAppender
import ch.qos.logback.core.rolling.FixedWindowRollingPolicy
import ch.qos.logback.core.rolling.RollingFileAppender
import ch.qos.logback.core.rolling.SizeBasedTriggeringPolicy
import ch.qos.logback.classic.Level
import net.logstash.logback.encoder.LogstashEncoder


def configStdOutAppender(env) {
  def stdOutLogLevel = env['MARATHON_LOG_STDOUT_THRESHOLD'] ?: 'INFO'
  def stdOutLogLayout = env['MARATHON_LOG_STDOUT_LAYOUT'] ?: 'standard'

  appender("STDOUT", ConsoleAppender) {
    target = "System.out"
    if (stdOutLogLayout == 'standard') {
      encoder(PatternLayoutEncoder) {
        pattern = "[%date] %level %message \\(%logger:%thread\\)%n"
      }
    } else if (stdOutLogLayout == 'json') {
      encoder(LogstashEncoder)
    }
    filter(ThresholdFilter) {
      level = Level."$stdOutLogLevel"
    }
  }
}

def configFileAppender(env) {
  def fileLogLevel = env['MARATHON_LOG_FILE_THRESHOLD'] ?: 'INFO'
  def fileLogDir = env['MARATHON_LOG_DIR'] ?: '/var/log/marathon'
  def fileLogName = env['MARATHON_LOG_FILE'] ?: 'marathon.log'
  def fileLogLayout = env['MARATHON_LOG_FILE_LAYOUT'] ?: 'json'

  appender("ROLLINGFILE", RollingFileAppender) {
    file = "${fileLogDir}/${fileLogName}"
    if (fileLogLayout == 'standard') {
      encoder(PatternLayoutEncoder) {
        pattern = "[%date] %level %message \\(%logger:%thread\\)%n"
      }
    } else if (fileLogLayout == 'json') {
      encoder(LogstashEncoder)
    }
    filter(ThresholdFilter) {
      level = Level."$fileLogLevel"
    }
    rollingPolicy(FixedWindowRollingPolicy) {
      maxIndex = 5
      fileNamePattern = "${fileLogDir}/${fileLogName}.%i"
    }
    triggeringPolicy(SizeBasedTriggeringPolicy) {
      maxFileSize = "10MB"
    }
  }
}

def env = System.getenv()

configStdOutAppender(env)
configFileAppender(env)

root(INFO, ["STDOUT", "ROLLINGFILE"])

