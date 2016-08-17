#!/bin/bash
USAGE="user.sh

Usage:
  user.sh create <username>
  user.sh delete <userid>
  user.sh list <userid>
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
  local hue_host result code userid
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
  userid=$(jshon -Q -e 0 -e success -e username -u <<< "$result")
  if [[ $? != 0 ]]; then
    printf "%s\n" "$result" >&2
    return 1
  fi
  printf "%s\n" "$userid"
  return $code
}

function list_users {
  local result code
  result=$(hue_get "config")
  code=$?
  [[ $code == 0 ]] || return $code
  local userids username
  userids=$(jshon -Q -e whitelist -k <<< "$result")
  for userid in ${userids[*]}; do
    username=$(jshon -Q -e whitelist -e "$userid" -e name -u <<< "$result")
    printf "%-40s %s\n" "$userid" "$username"
  done
}

function delete_user {
  local username=$1
  hue_delete "config/whitelist/$username"
}


case $1 in
  create) create_user "$2"; ;;
  delete) delete_user "$2"; ;;
  list) list_users "$2"; ;;
  -h) usage "$USAGE"; ;;
  *) usage_err "$USAGE"; ;;
esac
