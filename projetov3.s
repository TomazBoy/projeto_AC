    .equ    STACK_SIZE, 64
    .equ    INPORT_ADDRESS, 0xFF82
    .equ    OUTPORT_ADDRESS, 0xFFC2
    .equ    INIT_VAL, 0xF

    .text
	b	program

program:
	ldr	sp, stack_top_addr
    b   main

stack_top_addr:
	.word	stack_top

out_hole_leds:
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

main:; R4 = led_r R5 = led_g R6 = level_timer
    mrs R0, CPSR ; move cpsr to r0
    mov R1, #0x10
    orr R0, R0, R1 ; enable interrupt bit 4
    msr CPSR, R0 ; save cpsr
    mov R7, #9 ; round counter
main_start:
    mov R4, #INIT_VAL
    mov R5, #INIT_VAL
    bl  out_hole_leds ; yellow leds to start
main_check:
    bl check_press
    mov R1, #1
    cmp R0, R1
    bne main_check ; if inport bit0 = 1 start game
    bl inport_read
    mvn R0, R0 ; invert inport bits to work with them
    mov R1, #0xFF
    and R0, R0, R1;select only bits that care
    lsr R0, R0, #5 ; get bits 5..7 to 0..2
    mov R1, #8
    sub R6, R1, R0 ; get number of seconds of level, 
    add R6, R6, R6 ; n * 2 cuz increments .5 sec
    mov R4, #0
    mov R5, #0
    bl  out_hole_leds ;output nothing
    mov R0, #5
    bl  sleep;wait .5s
game_setup:
    ldr R0, moles_addr
    add R1, R7, R7
    ldrb R5, [R0, R1]
    bl  out_hole_leds 
game_loop:
    bl check_press ; checks wich key is pressed
    and R0, R5, R0 ; saves on R7 the hole that was pressed and has a mole
    beq game_loop ; if no mole pressed continue checking
    eor R5, R5, R0 ; else remove pressed mole from mole list
    mov R4, R2; hole where was mole red
    bl  out_hole_leds ; output hit
    mov R0, #1 ; wait .5 sec
    bl  sleep
    mov R4, #0 ;clear hit
    bl  out_hole_leds ; output curr game state
    cmp R5, R4 ; check if there is any mole left
    bne game_loop ; if has moles (!= 0) continue loop
game_outer_loop:
    mov R2, #0
    cmp R7, R2 ; check if there is any more rounds left
    beq game_end
    sub R7, R7, #1
    b   game_setup
game_end:
    mov R0, #2
    bl sleep
    b   main_start

check_press:; R0 = inport (curr) R1 prev_state
    push lr
check_press_inn:
    bl inport_read
    mov R2, #0xF
    and R0, R0, R2 ; bit de inport
    ldr R1, in_prev_state ;R1 = in_prev_state (starts at 1 cuz inport read starts as 1 )
    ldr R2, in_prev_addr
    str R0, [R2, #0]
    cmp R1, R0
    bhs check_press_inn
    mov R2, #0xF
    eor R0, R1, R2
    pop lr
    mov pc,lr
moles_addr:
    .word   moles
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
    .word 0xF
moles:
    .word 7, 13, 11, 9, 10, 5, 3, 1, 8, 2

    .stack
	.space	STACK_SIZE
stack_top:
