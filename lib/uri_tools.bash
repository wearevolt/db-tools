#!/bin/bash

#
# URI parsing function
#
# The function creates global variables with the parsed results.
# It returns 0 if parsing was successful or non-zero otherwise.
#
# [schema://][user[:password]@]host[:port][/path][?[arg1=val1]...][#fragment]
#
# from http://vpalos.com/537/uri-parsing-using-bash-built-in-features/
#
function parse_uri() {
    # uri capture
    uri="$@"

    # safe escaping
    uri="${uri//\`/%60}"
    uri="${uri//\"/%22}"

    # top level parsing
    pattern='^(([a-z]+)://)?((([^:\/]+)(:([^@\/]*))?@)?([^:\/?]+)(:([0-9]+))?)(\/[^?]*)?(\?[^#]*)?(#.*)?$'
    [[ "$uri" =~ $pattern ]] || return 1;

    # component extraction
    uri=${BASH_REMATCH[0]}
    uri_schema=${BASH_REMATCH[2]}
    uri_address=${BASH_REMATCH[3]}
    uri_user=${BASH_REMATCH[5]}
    uri_password=${BASH_REMATCH[7]}
    uri_host=${BASH_REMATCH[8]}
    uri_port=${BASH_REMATCH[10]}
    uri_path=${BASH_REMATCH[11]}
    uri_query=${BASH_REMATCH[12]}
    uri_fragment=${BASH_REMATCH[13]}

    # path parsing
    count=0
    path="$uri_path"
    pattern='^/+([^/]+)'
    while [[ $path =~ $pattern ]]; do
        eval "uri_parts[$count]=\"${BASH_REMATCH[1]}\""
        path="${path:${#BASH_REMATCH[0]}}"
        let count++
    done

    # query parsing
    count=0
    query="$uri_query"
    pattern='^[?&]+([^= ]+)(=([^&]*))?'
    while [[ $query =~ $pattern ]]; do
        eval "uri_args[$count]=\"${BASH_REMATCH[1]}\""
        eval "uri_arg_${BASH_REMATCH[1]}=\"${BASH_REMATCH[3]}\""
        query="${query:${#BASH_REMATCH[0]}}"
        let count++
    done

    # return success
    return 0
}

function store_password_to_pgpass() {
  parse_uri "$@"

  touch $HOME/.pgpass
  chmod 0600 $HOME/.pgpass

  clean_pgpass "$@"

  echo "${uri_host}:${uri_port:-5432}:${uri_path#/}:${uri_user}:${uri_password}" > $HOME/.pgpass

  local uri="${uri_schema}://${uri_user}@${uri_host}:${uri_port:-5432}${uri_path}"
  if [[ -n "${uri_query}" ]]; then
    uri=$uri?${uri_query}
  fi
  if [[ -n "${uri_fragment}" ]]; then
    uri=$uri#${uri_fragment}
  fi
  echo "${uri}"
}

function clean_pgpass() {
  parse_uri "$@"

  touch $HOME/.pgpass
  chmod 0600 $HOME/.pgpass

  local user_key="${uri_host}:${uri_port:-5432}:${uri_path#/}:${uri_user}:"

  sed -i "s/^$(echo $user_key | sed 's/[\.\-\[\]\(\)]/\\\0/g').*\$//g" $HOME/.pgpass
}