#!/usr/bin/env bash

if [ -z "${1}" ];then
	echo "What username?" >&2
	exit 1
fi
if [ -z "${TMP}" ]; then
	if [ -w '/tmp' ]; then
		TMP='/tmp/'
	else
		echo "Unable to find temp space, please set \$TMP manually" >&2
		exit 1
	fi
fi
for p in curl jq echo date;do
	if ! command -v "${p}" &>> /dev/null; then
		echo "Unable to find ${p}" >&2
		exit 1
	fi
done
if [ -e "${TMP}/mrtg.reddit.${1}.lock" ]; then
	START=$(< "${TMP}/mrtg.reddit.${1}.lock" )
	if ! [ "${START}" -gt 0 ]; then
		echo "Garbled lock file, fast cycle warning" >&2
		rm "${TMP}/mrtg.reddit.${1}.lock"
		exit 1
	fi
	NOW=$( date +%s )
	DIFF=$(( NOW - START ))
	if [ "${DIFF}" -gt 900 ]; then
		rm "${TMP}/mrtg.reddit.${1}.lock"
	else
		echo 'Throttling' >&2
		exit 1
	fi
fi
URL="https://www.reddit.com/user/${1}/about.json"
about="$( curl -ks --user-agent "mrtg-reddit-sh-v1" "${URL}" )"
error="$( jq .message <<< "${about}" )"
if [ "${error}" == '"Too Many Requests"' ]; then
	date +%s > "${TMP}/mrtg.reddit.${1}.lock"
fi
karma=$( jq .data.comment_karma <<< "${about}" )
link=$( jq .data.link_karma <<< "${about}" )
if ! [ "${karma}" -gt 0 ];then
	if ! [ "${karma}" -le 0 ]; then
		echo "Noninteger response, aborting" >&2
		exit 1
	fi
fi
if ! [ "${link}" -gt 0 ];then
	if ! [ "${link}" -le 0 ]; then
		echo "Noninteger response, aborting" >&2
		exit 1
	fi
fi
echo -e "${karma}\n${link}\n0\n0"
