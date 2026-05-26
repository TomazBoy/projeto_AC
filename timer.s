    .equ    STACK_SIZE, 64
    .equ    pTC_ADDRESS, 0xFF
    .equ    TCR, 0x00
    .equ    TMR, 0x01
    .equ    TC, 0x02
    .equ    TIR, 0x03
    .equ    pTC_MAX_VAL, 0xFA ; 5ms of iterations 

    .text
    b   program
    b   isr

program:
    ldr sp, stack_top_addr
    b main

main:; R4 = led_r R5 = led_g R6 = n/2 seconds counter
    mrs R0, CPSR ; move cpsr to r0
    mov R1, #0x10
    orr R0, R0, R1 ; enable interrupt bit 4
    msr CPSR, R0 ; save CPSR
    mov R0, #TMR ; select TMR
    mov R1, #pTC_MAX_VAL
    bl pTC_sel
    mov R6, #2 ; 1 second
    mov R0, #TCR; ; select TCR
    mov R1, #1
    bl pTC_sel ; reset and stop counter
    sub R1, R1, R1
    bl pTC_sel ; restart counter
main_start:
    mov R0, #0
    cmp R0, R6
    beq main_end
    b main_start
main_end:
    mov R0, #TCR
    mov R1, #1
    bl pTC_sel ; reset and stop counter
    b   .
pTC_sel:
    movt R0, #pTC_ADDRESS
    str R1 , [R0, #0]
    mov pc, lr
isr:
    mov R0, #TIR ; select TIR
    mov R1, #0
    bl pTC_sel ; stop interrupt request
    ldr R0, sw_counter
    mov R1, #0x64 ; 100 * 5ms = 0.5s
    cmp R0, R1 ; if 0.5s
    beq isr_end
    add R0, R0, #1 ; if R0 != 100 R0++
    ldr R1, sw_addr
    str R0, [R1, #0]; store sw_counter
    movs pc, lr
isr_end:
    sub R6, R6, #1 ; .5 secs have passed
    mov R0, #0 
    str R0, [R1, #0] ; sw_counter back to zero
    movs pc, lr

sw_addr:
    .word sw_counter

stack_top_addr:
	.word	stack_top

    .data
sw_counter:; pTC t max = 5ms => if swC = 200, time = 1 sec
    .word 0x00 ; changed ONLY in ISR called whenever pTC reaches 250 (5ms)

    .stack
    .space  STACK_SIZE
stack_top:
