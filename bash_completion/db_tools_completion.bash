_db_tools_list_remote_files() {
  local full_prefix=$1
  local dir_prefix=$full_prefix
  local grep_full_prefix="grep $full_prefix"

  if [[ -z "$full_prefix" ]]; then
    grep_full_prefix="cat -"
  fi

  if [[ ( -n "$dir_prefix" ) && ( "${dir_prefix:(-1)}" != '/' ) ]]; then
    dir_prefix=$(dirname $dir_prefix)/
  fi

  if [[ ($dir_prefix == './') || ($dir_prefix == '') ]]; then
    dir_prefix='/'
  fi

  mapfile -t COMPREPLY < <(
    (
      db_ls_backups -p $dir_prefix --output=json \
        | jq '[((.Contents // []) | map(.Key)), ((.CommonPrefixes // []) | map(.Prefix))] | flatten | .[]' \
          --raw-output \
        | $grep_full_prefix
    )
  )

  if [[ ( ${#COMPREPLY[@]} -eq 1 ) && ( "${COMPREPLY[0]:(-1)}" == '/' ) ]]; then
    _db_tools_list_remote_files "${COMPREPLY[0]}"
  fi
}

_db_tools_list_remote_dirs() {
  # List files and dirs
  _db_tools_list_remote_files $1

  # Convert files to dirs
  mapfile -t COMPREPLY < <(
    ( IFS=$'\n'; echo "${COMPREPLY[*]}" ) \
      | sed 's#/[^\/]*$#/#' \
      | sort -h \
      | uniq
  )
}

_db_ls_backups() {
  COMPREPLY=();
	local keys="-p"
  local prev="${COMP_WORDS[$COMP_CWORD-1]}";
  local cur="${COMP_WORDS[COMP_CWORD]}"

  if [[ ${cur:1} == '-' ]]; then
    COMPREPLY+=( $(compgen -W "${keys}" -- ${cur}) );
  else
    case $prev in
      -p|--prefix)
        _db_tools_list_remote_dirs "${cur}" 'dirs_only'
      ;;
    esac
  fi
}

_db_backup_restore() {
  COMPREPLY=();
	local keys="--remote-file -rf"
  local prev="${COMP_WORDS[$COMP_CWORD-1]}";
  local cur="${COMP_WORDS[COMP_CWORD]}"

  if [[ ${cur:1} == '-' ]]; then
    COMPREPLY+=( $(compgen -W "${keys}" -- ${cur}) );
  else
    case $prev in
      --remote-file|-rf)
        _db_tools_list_remote_files ${cur}
      ;;
    esac
  fi
}

complete -F _db_ls_backups db_ls_backups
complete -F _db_backup_restore db_backup_restore
