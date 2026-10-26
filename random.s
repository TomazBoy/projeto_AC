    .equ    STACK_SIZE, 64

    .text 
    b    program
    
program:
    ldr sp, stack_top_addr
    b    main

stack_top_addr:
    .word stack_top

main:
    push r2
    push r1
    mov     r2, #0       ; Inicializa p = 0
    cmp     r1, r0       ; Compara m e M
    blo     while        ; Se m <= M, segue normalmente
    mov     r3, r0       ; Troca os valores para garantir que m seja o menor
    mov     r0, r1
    mov     r1, r3

while:
    mov r3, #0   ; Load 0 into a register
    cmp r1, r3   ; Compare r1 with 0
    beq     while_end    ; Se m for 0, sai do loop
    add     r2, r2, r0   ; p = p + M
    sub     r1, r1, #1   ; m = m - 1
    b       while        ; Volta para o início do loop

while_end:
    pop r1
    pop r2
    b       .            ; Fim do programa

    .stack
    .space    STACK_SIZE
stack_top:
