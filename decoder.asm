# Arithmetic Decoder (MIPS Assembly)
# Based on zpaq 1.10

.data
    low:    .word 1           # Initial low value
    high:   .word 0xffffffff  # Initial high value
    x:      .word 0           # Decoder state
    input_file:     .asciiz "input.txt"
    output_file:    .asciiz "output.enc"
    buffer:         .space 1024       # Buffer for reading file
    error_msg:      .asciiz "Error opening file\n"


.text
.globl decode

# decode function
# Parameters:
#   $a0 - p (0 to 65535, representing probability)
# Returns:
#   $v0 - decoded bit (0 or 1)
decode:
    # Function prologue
    addi $sp, $sp, -20
    sw $ra, 16($sp)
    sw $s0, 12($sp)
    sw $s1, 8($sp)
    sw $s2, 4($sp)
    sw $s3, 0($sp)

    # Load low, high, and x
    lw $s0, low
    lw $s1, high
    lw $s2, x

    # Calculate mid = low + ((high-low)>>16)*p + ((((high-low)&0xffff)*p)>>16)
    sub $t0, $s1, $s0         # high - low
    srl $t1, $t0, 16          # (high-low)>>16
    mul $t1, $t1, $a0         # ((high-low)>>16)*p
    and $t2, $t0, 0xffff      # (high-low)&0xffff
    mul $t2, $t2, $a0         # ((high-low)&0xffff)*p
    srl $t2, $t2, 16          # (((high-low)&0xffff)*p)>>16
    add $t1, $t1, $t2         # ((high-low)>>16)*p + ((((high-low)&0xffff)*p)>>16)
    add $s3, $s0, $t1         # mid = low + ...

    # Determine the decoded bit
    li $v0, 0                 # Default to 0
    bge $s2, $s3, decode_one

decode_zero:
    move $s0, $s3             # low = mid
    j decode_normalize

decode_one:
    li $v0, 1                 # Set return value to 1
    addi $s1, $s3, -1         # high = mid - 1

decode_normalize:
    # Normalize loop
normalize_loop:
    xor $t0, $s0, $s1         # high ^ low
    srl $t0, $t0, 24          # (high ^ low) >> 24
    bnez $t0, decode_end

    # Reading in bits should be done in C lol
    sll $s0, $s0, 8
    sll $s1, $s1, 8
    ori $s1, $s1, 0xff
    sll $s2, $s2, 8
    jal read_bit
    or $s2, $s2, $v0

    j normalize_loop

decode_end:
    # Store updated low, high, and x
    sw $s0, low
    sw $s1, high
    sw $s2, x

    # Cleanup
    lw $ra, 16($sp)
    lw $s0, 12($sp)
    lw $s1, 8($sp)
    lw $s2, 4($sp)
    lw $s3, 0($sp)
    addi $sp, $sp, 20
    jr $ra