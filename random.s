    .equ STACK_SIZE, 64
    .text 
    b program
    
program:
    ldr sp, stack_top_addr
    b main

stack_top_addr:
    .word stack_top

main:
    b    .

    .stack
stack_top:
