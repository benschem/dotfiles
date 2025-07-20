## For when you try to drop a postges db and it won't let you.
killdb() {
  if [ -z "$1" ]; then
    echo "Usage: killdb YourAppName"
  else
    ps -ef | grep postgres | grep "$1" | awk '{print $2}' | xargs -r kill -9
    # ps -ef
    # Lists all processes
    #
    # | grep postgres
    # Filters for PostgreSQL processes
    #
    # | grep YourAppName
    # Further filters for YourAppName processes
    #
    # | awk '{print $2}'
    # get the PID from the second field of each line
    #
    # | xargs kill -9:
    # Passes the PID to kill -9 to terminate
  fi
}
