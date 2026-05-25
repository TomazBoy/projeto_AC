    .equ    STACK_SIZE, 64
    .equ    pTC_ADDRESS, 0xFF
    .equ    TCR, 0x00
    .equ    TMR, 0x01
    .equ    TC, 0x02
    .equ    TIR, 0x03
    .equ    pTC_COUNT, 0xFA

    .text
    b   program
    b   isr

program:
    ldr sp, stack_top_addr
    b main

main:; R4 = led_r R5 = led_g R6 = n/2 seconds counte
    mrs R0, CPSR ; move cpsr to r0
    mov R1, #0x10
    orr R0, R0, R1 ; enable interrupt bit 4
    msr CPSR, R0 ; save CPSR
    mov R0, #TMR
    movt R0, #pTC_ADDRESS
    mov R1, #pTC_COUNT
    str R1 , [R0, #0];stores match value in TMR
main_start:
    b main_start

isr:
    mov R0, #TIR
    movt R0, #pTC_ADDRESS
    mov R1, #0
    str R1 ,[R0, #0]
    ldr R0, sw_counter
    mov R1, #0x64 ; 100 * 5ms = 0.5s
    cmp R0, R1 ; if 0.5sec
    beq isr_end
    add R0, R0, #1
    ldr R1, sw_addr
    str R0, [R1, #0]
    movs pc, lr
isr_end:
    add R6, R6, #1 ; .5 secs have passed
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
