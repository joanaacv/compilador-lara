    .text
    .globl main

    .section .rodata
_fmt_int:   .string "%ld\n"
_fmt_float: .string "%g\n"
_fmt_str:   .string "%s\n"
_fmt_read:  .string "%ld"

    .text

fatorial:
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $32, %rsp

    movq    0(%rbp), %rax
    cmpq    $1, %rax
    setle   %al
    movzbq  %al, %rax
    movq    %rax, -8(%rbp)
    cmpq    $0, -8(%rbp)
    jne     _L1
    cmpq    $0, -8(%rbp)
    je      _L3
_L1:
    movq    $1, %rax
    movq    %rbp, %rsp
    popq    %rbp
    ret
    jmp     _L2
_L3:
    movq    0(%rbp), %rax
    subq    $1, %rax
    movq    %rax, -16(%rbp)
    movq    -16(%rbp), %rdi
    call    fatorial
    movq    %rax, -24(%rbp)
    movq    -24(%rbp), %rax
    movq    %rax, -8(%rbp)
    movq    0(%rbp), %rax
    movq    -8(%rbp), %rcx
    imulq   %rcx, %rax
    movq    %rax, -32(%rbp)
    movq    -32(%rbp), %rax
    movq    %rbp, %rsp
    popq    %rbp
    ret
_L2:

main:
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $16, %rsp

    movq    $5, %rdi
    call    fatorial
    movq    %rax, -16(%rbp)
    movq    -16(%rbp), %rax
    movq    %rax, -8(%rbp)
    movq    -8(%rbp), %rsi
    leaq    _fmt_int(%rip), %rdi
    xorq    %rax, %rax
    call    printf


    .bss
