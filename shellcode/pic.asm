; nasm -felf64 test.asm -o test.o && ld test.o -o test && chmod u+x test && ./test
SYS_WRITE equ 1
SYS_EXIT equ 60
STD_OUTPUT equ 1
 
section .text
global _start
 
_start:
  mov rax, SYS_WRITE
  mov rdi, STD_OUTPUT
  lea rsi, [rel msg]
  mov rdx, msglen
  syscall
  mov rax, SYS_EXIT
  mov rdi, 0
  syscall
  msg: db `Shellcode: "Hello world!"\n`
  msglen equ $-msg
