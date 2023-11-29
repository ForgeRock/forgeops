runOrPrint() {
  local result=0
  if [ "$DRYRUN" = true ] || [ "$VERBOSE" = true ] || [ "$DEBUG" = true ] ; then
    echo "$*"
  fi

  if [ "$DRYRUN" = false ] ; then
    eval "$*"
    result=$?
  fi

  return $result
}

message() {
  if [ "$DEBUG" = true ] && [ "$2" == "debug" ] ; then
    echo "$1"
  elif [ "$DRYRUN" = true ] || [ "$VERBOSE" = true ] || [ "$DEBUG" = true ] && [ "$2" != "debug" ] ; then
    echo "$1"
  fi
  if [ "$AUTO" = true ] && [ "$2" == "auto" ] ; then
    echo "$1"
  fi
}

# From http://stackoverflow.com/questions/3685970/check-if-an-array-contains-a-value
containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

# Setup sed based on our system
sedDetect() {
  local bsd_systems=( "Darwin" )
  SED_CMD=$(type -P sed)
  SED_I="-i"
  if containsElement $(uname -s) ${bsd_systems[@]} ; then
    SED_I="-i .bak"
  fi
}
