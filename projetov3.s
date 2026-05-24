    .equ    STACK_SIZE, 64
    .equ    INPORT_ADDRESS, 0xFF82
    .equ    OUTPORT_ADDRESS, 0xFFC2
    .equ    pTC_ADDRESS, 0xFF00
    .equ    INIT_VAL, 0xF

    .text
	b	program

program:
	ldr	sp, stack_top_addr
    b   main

stack_top_addr:
	.word	stack_top

main:; R4 = led_r R5 = led_g lets see if this works
    bl inport_read
    lsr R0, R0, #5
    mov R6, #8
    sub R6, R6, R0
    mov R4, #INIT_VAL
    mov R5, #INIT_VAL
    bl  out_hole_leds
main_check:
    bl check_press
    cmp R1, R0
    bhs main_check ; check if first bit pressed
game_loop:
    ;all game logic here
game_end:
    b   main
out_hole_leds:;
    push lr
    mov R1, R4
    mov R2, R5
    mov R3, #4 ; for i in range 4
out_hole_leds_loop:
    lsr R1, R1, #1 ; led red » 1 lost bit = C
    rrx R0, R0 ; led_grid » 1 highest bit = curr C
    lsr R2, R2, #1 ; led green » 1 lost bit = C
    rrx R0, R0 ; led_grid » 1 highest bit = curr C
    sub R3, R3, #1 ; i--
    bne out_hole_leds_loop ;if i != 0 PC -» loop
    lsr R0, R0, #8 ;R0 16 bit, outport uses lowest byte
    bl outport_write
    pop lr
    mov pc,lr

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

sleep: ;R0 = 10 * n seconds
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
sw_counter:; pTC t max = 5ms => if swC = 200, time = 1 sec
    .word 0x00 ; changed ONLY in ISR called whenever pTC reaches 250 (5ms)

    .stack
	.space	STACK_SIZE
stack_top:
