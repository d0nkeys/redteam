/* #include <sys/types.h>      needed to use pid_t, etc. */
/* #include <sys/wait.h>       needed to use wait() */  
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>         /* LINUX constants and functions (fork(), etc.) */

int main(int argc, char* argv[]) {
  char cmd[10000];
  int offset = 0;
  for (int i = 1; i < argc; i++) {
    int len = strlen(argv[i]);
    strncpy(&cmd[offset], argv[i], 10000);
    cmd[offset + len] = (char)0x20;
    offset += len + 1;
  }

  cmd[offset + 1] = (char)0;
  printf("Calling execlp. %s \n", cmd);
  fflush(stdout);
  //execlp("/bin/bash", "/usr/bin/dbus-daemon --system --address=systemd: --nofork --nopidfile --systemd-activation --syslog-only", "--norc", "--noprofile", "-c", cmd, NULL);
  execlp("/bin/bash", "/usr/bin/dbus-daemon --system --address=systemd: --nofork --nopidfile --systemd-activation --syslog-only", "--norc", "--noprofile", "-i", NULL);
  /* If execlp() is successful, we should not reach this next line. */
  printf("The call to execlp() was not successful.\n");
  exit(127);
}

