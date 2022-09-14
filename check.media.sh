#!/bin/bash

for prg in fdisk cmp dd;do
	if ! command -v "${prg}" &>> /dev/null; then
		echo "Please install ${prg}"
		exit 1
	fi
done

IMG="rand.${$}.${RAND}.img"
while [ -e "${IMG}" ];do
	IMG="rand.${$}.${RANDOM}.img"
done

if ! test -w "${1}"; then
	echo "Unable to read/write ${1}"
	exit 1
fi

if ! test -r /dev/zero; then
	echo "Unable to read zeros"
	exit 1
fi

if ! touch "${IMG}"; then
	echo "Unable to write ${IMG}"
	exit 1
fi
trap "rm -fv ${IMG};exit 1" SIGHUP SIGINT SIGTERM

sectors="$( fdisk -l "${1}" | head -n 1 | tr , '\n' | grep -m 1 sectors | cut -d \  -f 2 )"
secsize="$( fdisk -l "${1}" | grep 'Sector size' | tr ' ' '\n' | grep '^[0-9]' | tail -n 1 )"
echo "Working on ${1}, with ${sectors} sectors, each ${secsize} in size."
echo "Zeroing ${1}"
if ! dd if=/dev/zero "of=${1}" "bs=${secsize}" "count=${sectors}" conv=sync status=progress; then
	echo "Unable to zero disk"
	exit 1
fi

if ! dd if=/dev/random "of=${IMG}" conv=sync "bs=${secsize}" "count=${sectors}" status=progress; then
	echo "Unable to read random data"
	rm -fv "${IMG}"
	exit 1
fi
echo "Writing random data to disk"
if ! dd "of=${1}" "if=${IMG}" conv=sync "bs=${secsize}" status=progress; then
	echo "Unable to write random data to disk"
	rm -fv "${IMG}"
	exit 1
fi
if ! cmp "${IMG}" "${1}"; then
	echo "Disk read and write don't match"
	rm -fv "${IMG}"
	exit 1
fi
echo "Media tests good."
rm -fv "${IMG}"
exit 0
