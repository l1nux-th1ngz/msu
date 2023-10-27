#!/usr/bin/env bash

if [ -z "$BASH_VERSION" ]; then
	printf '%s\n' "$0: Not a bash shell"
	exit 1
fi

declare -rx SH_UTIL_VERSION='0.1'

# {{{ Environment
# better globs
shopt -s failglob globstar extglob
# }}}

declare -a SH_UTIL_log_colors
SH_UTIL_log_colors=(31 39 33 36 32) # red reset yellow cyan green
sh_util::log(){ # {{{ [level] [msg] [context]
	local context="${3:-${FUNCNAME[1]:-$0}}"
	if [[ -t 2 ]]; then
		(( ${#SH_UTIL_log_colors[@]} > $1 )) && local color=$'\e['"${SH_UTIL_log_colors[$1]}m"
		echo >&2 "${color}${context} [$1]: $2"$'\e[39m'
	else
		echo >&2 "${context} [$1]: $2"
	fi
}
# {{{
declare -A SH_UTIL_args_handler
sh_util::args(){
	case $1 in
	setup|add)
		shift
		while (($#)); do
			SH_UTIL_args_handler[$1]="${2/#S:/sh_util::args::}"
			shift 2
		done
	;;
	parse)
		shift
		local -; set -f
		local -a args=("$@")
		while
			local -i _args_count="${#args[@]}"
			[[ -n "${args[0]#'--'}" ]]
		do
			eval set -- "${SH_UTIL_args_handler[${args[0]}]}"
			if (($# != 0)); then
				# exact match
				"$@"
			elif [[ "${args[0]}" == [+-][!-]* ]]; then
				# beginning of short flag list: -abc
				# either -a takes an argument: -abc == -a bc
				# or not: -abc == -a -bc
				(( _args_count += 1 ))
				local _flagtype="${args[0]:0:1}"
				args=("${args[0]:0:2}" "${args[0]:2}" "${args[@]:1}")
				eval set -- "${SH_UTIL_args_handler[${args[0]}]}"
				"$@"
				if (( _args_count <= 1 + ${#args[@]} )); then
					args=("${_flagtype}${args[0]}" "${args[@]:1}")
				fi
			elif [[ "${args[0]}" == ?*=* ]]; then
				# possible --key=value
				local key="${args[0]%%=*}"
				eval set -- "${SH_UTIL_args_handler[$key]}"
				if (($# != 0)); then
					args=("$key" "${args[0]#"${key}="}" "${args[@]:1}")
					"$@"
				fi
			fi
			if (( _args_count == ${#args[@]} )); then
				# if argument was not consumed
				# add it to the remainder args list
				SH_UTIL_args+=("${args[0]}")
				args=("${args[@]:1}")
			fi
		done
		SH_UTIL_args+=("${args[@]:1}")
	;;
	esac
}

sh_util::args::count(){ # $1:val
	(( $# )) || return 1
	# no need for nameref
	# arithmetic context will deref for us
	if [[ ${args[0]:0:1} == '+' ]]
	then (($1--))
	else (($1++))
	fi
	args=("${args[@]:1}")
}

sh_util::args::toggle(){ # $1:val
	(( $# )) || return 1
	# no need for nameref
	# arithmetic context will deref for us
	if [[ ${args[0]:0:1} == '+' ]]
	then (($1 = 0))
	else (($1 = 1))
	fi
	args=("${args[@]:1}")
}

sh_util::args::value(){ # $1:key
	(( $# && ${#args[@]} > 1 )) || return 1
	# -n: name reference to another array
	#shellcheck disable=2178
	local -n ref="$1"
	ref="${args[1]}"
	args=("${args[@]:2}")
}

sh_util::args::values(){ # $1:key [$2:count]
	local -i count="${2:-1}"
	(( count && $# && ${#args[@]} > count )) || return 1
	# -n: name reference to another array
	#shellcheck disable=2178
	local -n ref="$1"
	ref=("${args[@]:1:count}")
	args=("${args[@]:1+count}")
}

sh_util::args::append(){ # $1:array name, [$2:count]
	local -i count="${2:-1}"
	(( count && $# && ${#args[@]} > count )) || return 1
	# -n: name reference to another array
	#shellcheck disable=2178
	local -n ref="$1"
	ref+=("${args[@]:1:count}")
	args=("${args[@]:1+count}")
}

sh_util::args::list(){ # $1:array name, [$2:terminator]
	(( $# && ${#args[@]} )) || return 1
	local term="${2:-';'}"
	local -i count=0
	#shellcheck disable=2178
	local -n ref="$1"
	while [[ -n "${args[1+count]#$term}"  ]]; do
		((count++))
	done
	ref=("${args[@]:1:count}")
	args=("${args[@]:2+count}")
}
# }}}
