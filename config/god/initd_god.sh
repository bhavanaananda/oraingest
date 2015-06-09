#!/bin/bash
#
# god       Startup script for god (<a href="http://god.rubyforge.org">http://god.rubyforge.org</a>)
#
# chkconfig: - 99 1
# description: God is an easy to configure, easy to extend monitoring \
#              framework written in Ruby.
#
 
CONF_FILE=/home/oraadmin/ora-hydra/config/god/master.conf
DAEMON=/home/oraadmin/.rvm/bin/boot_god
PIDFILE=/var/run/god.pid
LOGFILE=/var/log/god.log
SCRIPTNAME=/etc/init.d/god
 
#DEBUG_OPTIONS="--log-level debug"
DEBUG_OPTIONS=""
 
# Gracefully exit if 'god' gem is not available.
test -x $DAEMON || exit 0
 
RETVAL=0
 
god_start() {
      start_cmd="$DAEMON -l $LOGFILE -P $PIDFILE $DEBUG_OPTIONS -c $CONF_FILE"
      echo $start_cmd
      $start_cmd || echo -en "god already running"
      RETVAL=$?
      return $RETVAL
}
 
god_stop() {
      stop_cmd="$DAEMON terminate"
      #stop_cmd="kill -QUIT `cat $PIDFILE`"
      echo $stop_cmd
      $stop_cmd || echo -en "god not running"
}
 
case "$1" in
    start)
      god_start
      RETVAL=$?
  ;;
    stop)
      god_stop
      RETVAL=$?
  ;;
    restart)
      god_stop
      god_start
      RETVAL=$?
  ;;
    status)
      $DAEMON status
      RETVAL=$?
  ;;
    *)
      echo "Usage: god {start|stop|restart|status}"
      exit 1
  ;;
esac
 
exit $RETVAL
