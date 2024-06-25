# Arithmetic Encoder (MIPS Assembly)
# Based on zpaq 1.10

.data
    low:            .word 1           # Initial low value
    high:           .word 0xffffffff  # Initial high value
    input_file:     .asciiz "input.txt"
    output_file:    .asciiz "output.enc"
    buffer:         .space 1024       # Buffer for reading file
    error_msg:      .asciiz "Error opening file\n"

.text
.globl main

main:
    

# encode function
# Parameters:
#   $a0 - y (0 or 1)
#   $a1 - p (0 to 65535)
encode:
    addi $sp, $sp, -20
    sw $ra, 16($sp)
    sw $s0, 12($sp)
    sw $s1, 8($sp)
    sw $s2, 4($sp)
    sw $s3, 0($sp)

    lw $s0, low
    lw $s1, high

    # Calculate mid = low + ((high-low)>>16)*p + ((((high-low)&0xffff)*p)>>16)
    sub $t0, $s1, $s0         # high - low
    srl $t1, $t0, 16          # (high-low)>>16
    mul $t1, $t1, $a1         # ((high-low)>>16)*p
    and $t2, $t0, 0xffff      # (high-low)&0xffff
    mul $t2, $t2, $a1         # ((high-low)&0xffff)*p
    srl $t2, $t2, 16          # (((high-low)&0xffff)*p)>>16
    add $t1, $t1, $t2         # ((high-low)>>16)*p + ((((high-low)&0xffff)*p)>>16)
    add $s2, $s0, $t1         # mid = low + ...

    # Update range based on y
    beq $a0, $zero, encode_zero
    move $s1, $s2             # if (y) high = mid
    j encode_normalize
encode_zero:
    addi $s0, $s2, 1          # else low = mid + 1

encode_normalize:
    # Normalize loop
normalize_loop:
    xor $t0, $s0, $s1         # high ^ low
    srl $t0, $t0, 24          # (high ^ low) >> 24
    bne $t0, $zero, encode_end

    # Output byte
    srl $a0, $s1, 24
    li $v0, 11
    syscall

    # Shift high and low
    sll $s1, $s1, 8
    ori $s1, $s1, 0xff
    sll $s0, $s0, 8
    beq $s0, $zero, increment_low
    j normalize_loop

increment_low:
    addi $s0, $s0, 1
    j normalize_loop

encode_end:
    # Store updated low and high
    sw $s0, low
    sw $s1, high

    # Function epilogue
    lw $ra, 16($sp)
    lw $s0, 12($sp)
    lw $s1, 8($sp)
    lw $s2, 4($sp)
    lw $s3, 0($sp)
    addi $sp, $sp, 20
    jr $ra