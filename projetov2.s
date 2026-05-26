    .equ    STACK_SIZE, 64
    .equ    INPORT_ADDRESS, 0xFF82
    .equ    OUTPORT_ADDRESS, 0xFFC2
    .equ    ALL_ON, 0xF
    .equ    VALUE_R, 0xE
    .equ    VALUE_G, 0xE

    .text
	b	program

program:
	ldr	sp, stack_top_addr
    b   main

main:;R0 = outport, R1 = led_R, R2 = led_G
    bl check_press
    cmp R0, R1
    bhs main
main_loop:
    mov R1, #0
    mov R2, #0
    bl out_leds
    mov R0, #10
    bl sleep
    mov R1, #ALL_ON
    mov R2, #ALL_ON
    bl out_leds
    mov R0, #10
    bl sleep
    mov R1, #0
    mov R2, #ALL_ON
    bl out_leds
    mov R0, #10
    bl sleep
    mov R1, #ALL_ON
    mov R2, #0
    bl out_leds
    mov R0, #10
    bl sleep
    b main_loop

check_press:; R0 = inport (curr) R1 prev_state
    push lr
    bl inport_read
    mov R2, #1
    and R0, R0, R2 ; bit0 de inport
    ldr R1, in_prev_state ;R1 = in_prev_state (starts at 1 cuz inport read starts as 1 )
    ldr R2, in_prev_addr
    str R0, [R2, #0]
    pop lr
    mov pc,lr

in_prev_addr:
    .word in_prev_state

out_leds:; R0 = outport, R1 = led_R, R2 = led_G
    push lr
    mov R3, #4 ; led total
out_leds_loop:
    mov R4, #VALUE_R
    orr R1, R1, R4
    mov R4, #VALUE_G
    orr R2, R2, R4
    lsr R1, R1, #1 ; led red » 1 lost bit = C
    rrx R0, R0 ; led_grid » 1 highest bit = curr C
    lsr R2, R2, #1 ; led green » 1 lost bit = C
    rrx R0, R0 ; led_grid » 1 highest bit = curr C
    sub R3, R3, #1 ; i--
    bne out_leds_loop ;if i != 0 PC -» loop
    lsr R0, R0, #8 ;R0 16 bit, outport uses lowest byte
    bl outport_write
    pop lr
    mov pc,lr

stack_top_addr:
	.word	stack_top

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

sleep: ;R0 = n/10 segundos
    push R1
    and R0, R0, R0
    beq sleep_end
sleep_outer_loop:
    mov R1, #0x3E
    movt R1, #0x03
sleep_inner_loop:
    sub R1, R1, #1
    bne sleep_inner_loop
    sub R0, R0, #1
    bne sleep_outer_loop
sleep_end:
    pop R1
    mov pc, lr

    .data

in_prev_state:
    .word 0x01

led_r_sel:
    .word 0,1,0,1;TENHO REGISTOS PARA TUDO!!! WIP N ESQUECE
led_g_sel:
    .word 0,0,1,1

    .stack
	.space	STACK_SIZE
stack_top:
