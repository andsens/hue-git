#!/bin/bash

function init_vars {
  HUE_HOST=$(jshon -e hostname -u < $HUE_GIT/config.json)
  [[ $? == 0 ]] || error "No hue hostname was found in the config"
  export HUE_HOST
  HUE_USERNAME=$(jshon -e username -u < $HUE_GIT/config.json)
  [[ $? == 0 ]] || error "No username was found in the config"
  export HUE_USERNAME
}


function hue_get {
  local api_path=$1
  hue_send GET "$api_path"
}

function hue_post {
  local api_path=$1
  local data
  data=$(cat)
  hue_send POST "$api_path" "$data"
}

function hue_put {
  local api_path=$1
  local data
  data=$(cat)
  hue_send PUT "$api_path" "$data"
}

function hue_delete {
  local api_path=$1
  hue_send DELETE "$api_path"
}

function hue_send {
  local method=$1
  local api_path=$2
  local data=$3

  local result code
  result=$(send "$method" "http://$HUE_HOST/api/$HUE_USERNAME/$api_path" "$data")
  code=$?
  if [[ $code != 0 ]]; then
    print_hue_error "$result"
    return $code
  else
    if is_hue_error "$result"; then
      print_hue_error "$result"
      return 1
    fi
  fi
  printf "%s\n" "$result"
  return $code
}

function send {
  local address method data http_status
  method="-X$1"
  address=$2
  data=$3
  exec 3>&1
  http_status=$(curl \
    "$method" \
    --silent \
    --header 'Content-Type:application/json' \
    --data "$data" \
    --write-out "%{http_code}" \
    --output >(cat >&3) "$address")
  if [[ $http_status -ge 400 ]]; then
    return 1
  fi

}

function is_hue_error {
  local data code
  data=$1
  jshon -Q -e 0 -e error <<< "$data" >/dev/null
}

function print_hue_error {
  local data err_type description
  data=$1
  err_type=$(jshon -Q -e 0 -e error -e type -u <<< "$data")
  description=$(jshon -Q -e 0 -e error -e description -u <<< "$data")
  printf "Error (%s): %s\n" "$err_type" "$description" >&2
}

function error {
  local message=$1
  printf "%s\n" "$message" >&2
  exit "${2:-1}"
}

function usage_err {
  usage "$@" >&2
  return 64
}

function usage {
  local usage_str=$1
  printf "%s" "$usage_str"
}

init_vars
