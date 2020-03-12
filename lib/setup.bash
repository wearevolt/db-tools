#!/usr/bin/env bash

set -e

trap 'on_error $LINENO' ERR

on_error() {
  LINE=$1
  printf "Error at LINE NUMBER: $LINE"
}

. ${SCRIPT_DIR}/lib/uri_tools.bash

# Configuration
# following configuration parameters required:
# DB_BACKUP_AWS_ACCESS_KEY_ID=
# DB_BACKUP_AWS_SECRET_ACCESS_KEY=
# DB_BACKUP_AWS_DEFAULT_REGION=
# DB_BACKUP_TARGET_BUCKET=
# DB_BACKUP_ROOT=
# DB_BACKUP_BASE_NAME=

# 1. Take base working dir
BASE_DIR="$( git rev-parse --show-toplevel 2>/dev/null || echo $PWD)"

# 2. Set temp dir
if [[ -z "${TMPDIR}" ]]; then
  if [[ -d $BASE_DIR/tmp  ]]; then
    TMPDIR=$BASE_DIR/tmp
  else
    TMPDIR=/tmp
  fi
fi

# 3. Set working environment
if [[ -z "$WORKING_ENV" ]]; then
  WORKING_ENV=${RAILS_ENV}
fi

if [[ -z "$WORKING_ENV" ]]; then
  WORKING_ENV=${RACK_ENV}
fi

if [[ -z "$WORKING_ENV" ]]; then
  WORKING_ENV=development
fi


# 3. load .env files for non production environments
if [[ "$WORKING_ENV" != "production" ]]; then
  if [[ -f ${PWD}/.env ]]; then
    . ${PWD}/.env
  fi

  if [[ -f ${BASE_DIR}/.env ]]; then
    . ${BASE_DIR}/.env
  fi

  if [[ -f ${PWD}/.env.${WORKING_ENV} ]]; then
    . ${PWD}/.env.${WORKING_ENV}
  fi

  if [[ -f ${BASE_DIR}/.env.${WORKING_ENV} ]]; then
    . ${BASE_DIR}/.env.${WORKING_ENV}
  fi

if [[ -f ${PWD}/.env.db_tools ]]; then
    . ${PWD}/.env.db_tools
  fi

  if [[ -f ${BASE_DIR}/.env.db_tools ]]; then
    . ${BASE_DIR}/.env.db_tools
  fi
fi

# 4. Export vars for AWS CLI
export AWS_ACCESS_KEY_ID=${DB_BACKUP_AWS_ACCESS_KEY_ID}
export AWS_SECRET_ACCESS_KEY=${DB_BACKUP_AWS_SECRET_ACCESS_KEY}
export AWS_DEFAULT_REGION=${DB_BACKUP_AWS_DEFAULT_REGION}


if [[ -z "${DB_BACKUP_DUMPS_DIR}" ]]; then
  DB_BACKUP_DUMPS_DIR=$TMPDIR/dumps
  mkdir -p "${DB_BACKUP_DUMPS_DIR}"
fi

# 5. Setup cache
if [[ -z "${DB_TOOLS_CACHE}" ]]; then
  DB_TOOLS_CACHE=$HOME/.dbtools/cache
fi

mkdir -p $HOME/.dbtools/cache
chmod 0700 $HOME/.dbtools/cache

# 6. Use custom .pgpass file
if [[ -d /dev/shm ]]; then
  export PGPASSFILE="$(mktemp --tmpdir=/dev/shm .pgpass.dbtools.XXXXXXXXXX)"
else
  echo "No /dev/shm present in your system, will use \$HOME/.pgass.dbtools intead" >&2
  export PGPASSFILE="$HOME/.pgpass.dbtools"
fi


cleanup_pgpass() {
  rm $PGPASSFILE || :
}
trap 'cleanup_pgpass' 0