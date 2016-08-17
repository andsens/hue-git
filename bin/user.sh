#!/bin/bash
USAGE="user.sh

Usage:
  user.sh create <username>
  user.sh delete <userid>
  user.sh -h

Options:
  -h --help     Show this screen.
"

export HUE_GIT=${HUE_GIT:-'.'}
if [[ ! -f "$HUE_GIT/hue-git/lib/lib.sh" ]]; then
  printf "\$HUE_GIT invalid or not defined, please set the path to hue-git\n" >&2
  exit 1
fi

if [[ $1 != 'create' ]]; then
  source "$HUE_GIT/hue-git/lib/lib.sh"
fi

function create_user {
  local username=$1
  local hue_host result code
  hue_host=$(jshon -e hostname -u < config.json)
  if [[ $? != 0 ]]; then
   printf "No hue hostname was found in the config\n" >&2
   exit 1
  fi
  result=$(curl -s -XPOST \
    -H'Content-Type:application/json' \
    -d"{\"devicetype\":\"hue-git#$username\"}" \
    "http://$hue_host/api")
  code=$?
  printf "%s\n" "$result"
  return $code
}

function delete_user {
  local username=$1
  hue_delete "config/whitelist/$username"
}


case $1 in
  create) create_user "$2"; ;;
  delete) delete_user "$2"; ;;
  -h) usage "$USAGE"; ;;
  *) usage_err "$USAGE"; ;;
esac
