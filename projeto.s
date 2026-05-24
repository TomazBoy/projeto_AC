
    .equ    STACK_SIZE, 64
    .equ    INPORT_ADDRESS, 0xFF82
    .equ    OUTPORT_ADDRESS, 0xFFC2

    .text
	b	program

program:
	ldr	sp, stack_top_addr
    b   main

stack_top_addr:
	.word	stack_top

main: ; R0 = retorno R4 = HOLE_R R5 = HOLE_G
    mov R1, #0xF
    mov R2, #0xF 
    bl out_hole_leds
    bl inport_read
    mov R3, #1
    and R0, R0, R3
    cmp R3, R0
    beq main ;loop if no input to start
    bl check_level
    b main_loop

main_loop:
    bl check_hit ;check if there is a hit on the hole
    bl out_hole_leds ; output hit
    b main_loop
end_loop:
    b victory_check

victory_check:
    mov R0, #11
    ldr R1, rounds
    sub R0, R1, R0
    bne loss
    mov R2, #0xF
    mov R0, #1
    bl out_hole_leds
    bl sleep
    mov R2, #0
    mov R0, #1
    bl out_hole_leds
    bl sleep
    mov R2, #0xF
    mov R0, #1
    bl sleep
    bl out_hole_leds
    mov R2, #0
    mov R0, #1
    bl out_hole_leds
    bl sleep
    mov R2, #0xF
    mov R0, #1
    bl out_hole_leds
    bl sleep
    mov R2, #0
    mov R0, #1
    bl out_hole_leds
    bl sleep
    str R0, [R3, #0] ;reset rounds to zero in the end of the loop
loss:
    b main

check_hit:
    push lr
    bl inport_read; R0 = inport
    mov R3, #0xF ; 1111
    and R0, R0, R3 ; inport first 4 bits
    mov R1, R0 
    and R0, R0, R0 ; if R0 = 0
    beq no_input
    and R0, R0, R2 ; hits
    eor R2, R0, R2; led_g xor hit = remaining green
    bl out_hole_leds
    mov R3, #0
    and R2, R2, R3
    bl round_check; check curr round to load holes
no_input:
    pop lr
    mov pc,lr

out_hole_leds:;R0 = outport, R1 = led_r
    push lr
    push R2
    mov R3, #4 ; led total
out_hole_leds_loop:
    lsr R1, R1, #1 ; led red » 1 lost bit = C
    rrx R0, R0 ; led_grid » 1 highest bit = curr C
    lsr R2, R2, #1 ; led green » 1 lost bit = C
    rrx R0, R0 ; led_grid » 1 highest bit = curr C
    sub R3, R3, #1 ; i--
    bne out_hole_leds_loop ;if i != 0 PC -» loop
    lsr R0, R0, #8 ;R0 16 bit, outport uses lowest byte
    bl outport_write
    pop R2
    pop lr
    mov pc,lr

round_check:
    push lr
    push R1
    push R0
    mov R0, #0
    and R0, R2, R0
    beq end_check
    mov R0, #1
    ldr R1, rounds
    add R1, R1, #1
    mov R3, #4
    cmp R3, R1
    bge end_check
    lsl R0, R0, #1
    add R0, R0, #1
    mov R3, #7
    cmp R3, R1
    bge end_check
    lsl R0, R0, #1
    add R0, R0, #1
    mov R3, #11
    cmp R3, R1
    bge end_level
end_check:
    ldr R3, rounds_addr
    str R1, [R3, #0]
    mov R2, R0
    pop R0
    pop R1
    pop lr
end_level:
    ldr R3, rounds_addr
    str R1, [R3, #0]
    mov R2, R0
    pop R0
    pop R1
    b end_loop

outport_write:
    push R1
	mov	R1, #OUTPORT_ADDRESS & 0xFF
	movt R1, #(OUTPORT_ADDRESS >> 8) & 0xFF
	strb R0, [R1, #0]
    pop R1
	mov	pc, lr

check_level:
    push lr
    push R1

    bl inport_read
    mov R1, #0xE0
    and R0, R0, R1 ; inport last 3 bits
    lsr R0, R0, #5 ;to work with lowest bits
    ldr R2, timer_addr
    str R0, [R2, #0]

inport_read: ; 0-3 buttons 5-7 level switches
    push R1
    mov R1, #INPORT_ADDRESS & 0xFF
    movt R1, #(INPORT_ADDRESS >> 8) & 0xFF
    ldrb R0, [R1, #0]
    pop R1
    mov pc, lr

sleep: ;R0 = n segundos
    push R1
    and R0, R0, R0
    beq sleep_end
sleep_outer_loop:
    mov R1, #0x3E ;to change
    movt R1, #0x03; to change
sleep_inner_loop:
    sub R1, R1, #1
    bne sleep_inner_loop
    sub R0, R0, #1
    bne sleep_outer_loop
sleep_end:
    pop R1
    mov pc, lr

rounds_addr:
    .word rounds
; Seccao:    data
; Descricao: Guarda as variaveis globais
	.data
rounds:
    .word 0x0
timer_addr:
    .word timer
timer:
    .space 1

    .stack
	.space	STACK_SIZE
stack_top:
