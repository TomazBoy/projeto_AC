    .equ    STACK_SIZE, 64
    .equ    INPORT_ADDRESS, 0xFF82
    .equ    OUTPORT_ADDRESS, 0xFFC2
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
    ldr R0, sw_addr
    ldr R1, sw_counter
    mov R2, #pTC_COUNT ; 200 * 5ms = 1sec
    cmp R1, R2 ; if 1 sec
    beq isr_end
    add R1, R1, #1
    str R1, [R0, #0]
    movs pc, lr
isr_end:
    add R6, R6, #1
    mov R0, #TIR
    movt R0, #pTC_ADDRESS & 0xFF
    mov R2, #0
    str R2 ,[R0, #0]
    movs pc, lr

sw_addr:
    .word sw_counter

outport_write:
	mov	R1, #OUTPORT_ADDRESS & 0xFF
	movt R1, #(OUTPORT_ADDRESS >> 8) & 0xFF
	strb R0, [R1, #0]
	mov	pc, lr

inport_read: ; 0-3 buttons 5-7 level switches
    mov R1, #INPORT_ADDRESS & 0xFF
    movt R1, #(INPORT_ADDRESS >> 8) & 0xFF
    ldrb R0, [R1, #0]
    mov pc, lr

stack_top_addr:
	.word	stack_top

    .data
sw_counter:; pTC t max = 5ms => if swC = 200, time = 1 sec
    .word 0x00 ; changed ONLY in ISR called whenever pTC reaches 250 (5ms)

    .stack
    .space  STACK_SIZE
stack_top:
