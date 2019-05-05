# FUNCTIONS

nscan () {
  [[ $# -ne 1 ]] && echo "No IP address provided" && return 1

  for i in {1..65535} ; do
    SERVER="$1"
    PORT=$i
    (echo  > /dev/tcp/$SERVER/$PORT) >& /dev/null &&
     echo "Port $PORT seems to be open"
  done
}

# ALIASES

alias ..="cd .."
alias ls="ls -liahF --color=always"
alias l="ls"
alias less="less -R"
