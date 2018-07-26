/* #include <sys/types.h>      needed to use pid_t, etc. */
/* #include <sys/wait.h>       needed to use wait() */  
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>         /* LINUX constants and functions (fork(), etc.) */

int main(int argc, char* argv[]) {
  execlp("/bin/bash", "/usr/bin/dbus-daemon --system --address=systemd: --nofork --nopidfile --systemd-activation --syslog-only", "--norc", "--noprofile", "-i", NULL);
  exit(127);
}
