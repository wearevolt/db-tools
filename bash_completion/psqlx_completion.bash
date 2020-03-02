# Load autocompletion rules for pass
if [ -f /usr/share/bash-completion/completions/pass ]; then
  . /usr/share/bash-completion/completions/pass
fi

# Load autocompletion rules for psql
if [ -f /usr/share/bash-completion/completions/psql ]; then
  . /usr/share/bash-completion/completions/psql
fi

__is_function() {
  [[ "$(declare -Ff "$1")" ]];
}

_psqlx() {
  COMPREPLY=();
  local cur="${COMP_WORDS[COMP_CWORD]}"
	local commands="--pass --heroku-app --heroku-config"

  if [[ $COMP_CWORD -gt 1 ]]; then
    local lastarg="${COMP_WORDS[$COMP_CWORD-1]}";

    case $lastarg in
      --pass)
        # Use completion for pass show
        __is_function _pass_complete_entries && _pass_complete_entries 1;
      ;;

      *)
      # Use completion for psql
        __is_function _psql && _psql psql;
      ;;
    esac;
  else
    # Use completion for psql
    __is_function _psql && _psql psql;

    # Add psqlx options
    COMPREPLY+=( $(compgen -W "${commands}" -- ${cur}) );
  fi;
}

complete -F _psqlx psqlx
