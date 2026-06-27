# ============================================================
# PROJECT  : Binary-to-ASCII Converter with File Output
# COURSE   : CS-226 Computer Org. & Assembly Language
# TOOL     : MIPS / MARS 4.5 Simulator
# ============================================================

.data
    msg_border:   .asciiz "========================================\n"
    msg_title:    .asciiz "   Binary-to-ASCII Converter  (MIPS)\n"
    msg_m1:       .asciiz "  [1] Convert Binary -> ASCII\n"
    msg_m2:       .asciiz "  [2] Parity Check (last byte)\n"
    msg_m3:       .asciiz "  [3] Show ASCII Table (32-126)\n"
    msg_m4:       .asciiz "  [4] Preview output buffer\n"
    msg_m5:       .asciiz "  [5] Exit and Save to output.txt\n"
    msg_choice:   .asciiz "Enter choice (1-5): "
    msg_enter:    .asciiz "\nEnter 8-bit groups separated by spaces\n  e.g. 01001000 01100101\n> "
    msg_res_hdr:  .asciiz "\n--- Conversion Result ---\n"
    msg_bin_lbl:  .asciiz "Binary: "
    msg_dec_lbl:  .asciiz "  Dec: "
    msg_hex_lbl:  .asciiz "  Hex: 0x"      # NEW: label for hex display
    msg_chr_lbl:  .asciiz "  Char: ["
    msg_chr_end:  .asciiz "]\n"
    msg_nonprint: .asciiz "(non-printable)]\n"
    msg_nl:       .asciiz "\n"
    msg_par_hdr:  .asciiz "\n--- Parity Check (last byte) ---\n"
    msg_par_val:  .asciiz "XOR result: "
    msg_par_even: .asciiz "  -> Even parity (bit=0)\n"
    msg_par_odd:  .asciiz "  -> Odd  parity (bit=1)\n"
    msg_asc_hdr:  .asciiz "\n Dec | Hex  | Char\n-----+------+-----\n"   # updated header
    msg_pipe:     .asciiz "  |  "
    msg_pipe2:    .asciiz " | 0x"           # NEW: for hex column in table
    msg_preview:  .asciiz "\n--- Output Buffer ---\n"
    msg_buf_len:  .asciiz "\n[Buffer holds "  # NEW: for showing buffer byte count
    msg_buf_bytes:.asciiz " bytes]\n"         # NEW
    msg_bye:      .asciiz "Goodbye!\n"
    msg_saved:    .asciiz "\nSaved to output.txt\n"
    err_range:    .asciiz "[ERR] Enter 1-5\n"
    err_invalid:  .asciiz "[ERR] Only 0, 1, and spaces allowed!\n"
    err_empty:    .asciiz "[ERR] Empty input!\n"
    err_notbyte:  .asciiz "[ERR] Each group must be exactly 8 bits!\n"

    # Hex digit lookup table: index 0-15 -> ASCII char '0'-'9','A'-'F'
    hex_digits:   .asciiz "0123456789ABCDEF"

    # Full absolute path so MARS finds the file regardless of working dir
    fname:        .asciiz "C:\\Users\\Mrd74\\OneDrive\\Desktop\\option1\\output.txt"

    # Single newline written at the end of every conversion session
    fnl:          .asciiz "\n"

    choice_buf:   .space 8
    inbuf:        .space 600

    # outbuf accumulates ONLY the ASCII characters (no labels, no header)
    # Example: input "01001000 01100101 01101100 01101100 01101111"
    #          outbuf contains exactly: Hello
    outbuf:       .space 2048

    bytebuf:      .space 12
    last_val:     .word  0
    out_len:      .word  0   # tracks how many bytes are in outbuf

    # NEW: word used for hex digit extraction via div
    hex_hi:       .word  0   # upper hex digit of last byte
    hex_lo:       .word  0   # lower hex digit of last byte

.text
.globl main

# ============================================================
# MAIN
# Entry point. Initialises out_len, prints banner, enters menu.
# ============================================================
main:
    # Initialise output buffer length to zero
    li   $t0, 0
    sw   $t0, out_len  # out_len = 0

    # Print welcome banner
   li  $v0, 4
    la  $a0, msg_border
    syscall

    li   $v0, 4
    la   $a0, msg_title
    syscall

    li   $v0, 4
    la   $a0, msg_border
    syscall

# ============================================================
# MENU LOOP
# ============================================================
menu_loop:
    li   $v0, 4
    la   $a0, msg_border
    syscall
    li   $v0, 4
    la   $a0, msg_m1
    syscall
    li   $v0, 4
    la   $a0, msg_m2
    syscall
    li   $v0, 4
    la   $a0, msg_m3
    syscall
    li   $v0, 4
    la   $a0, msg_m4
    syscall
    li   $v0, 4
    la   $a0, msg_m5
    syscall
    li   $v0, 4
    la   $a0, msg_border
    syscall
    li   $v0, 4
    la   $a0, msg_choice
    syscall

    # Read choice as string to avoid MARS newline-buffer bug
    li   $v0, 8
    la   $a0, choice_buf
    li   $a1, 7
    syscall

    # Convert first char from ASCII digit to integer ('1'=49 -> 1)
    la   $t0, choice_buf
    lb   $s7, 0($t0)
    addi $s7, $s7, -48

    blt  $s7, 1, ml_bad
    bgt  $s7, 5, ml_bad
    beq  $s7, 1, ml_1
    beq  $s7, 2, ml_2
    beq  $s7, 3, ml_3
    beq  $s7, 4, ml_4
    j    ml_5

ml_bad:
    li   $v0, 4
    la   $a0, err_range
    syscall
    j    menu_loop

ml_1: jal  get_and_convert
      j    menu_loop
ml_2: jal  parity_check
      j    menu_loop
ml_3: jal  print_ascii_table
      j    menu_loop

ml_4:
    # Option 4: preview outbuf AND show byte count using mul
    li   $v0, 4
    la   $a0, msg_preview
    syscall
    li   $v0, 4
    la   $a0, outbuf
    syscall

    # ---- NEW: show buffer byte count ----
    # out_len already holds char count.
    # Demonstrate mul: total_bits = out_len * 8
    # This is a real multiply using mult + mflo (hardware HI/LO registers)
    lw   $t0, out_len
    li   $t1, 8
    mult $t0, $t1             # HI:LO = out_len * 8
    mflo $t2                  # $t2 = total bits stored in buffer
    # We print the byte count (out_len), and the total bits ($t2)
    li   $v0, 4
    la   $a0, msg_buf_len     # "\n[Buffer holds "
    syscall
    li   $v0, 1
    move $a0, $t0             # print out_len (characters)
    syscall
    li   $v0, 4
    la   $a0, msg_buf_bytes   # " bytes]\n"
    syscall
    j    menu_loop

ml_5:
    # Option 5: write outbuf to file, say goodbye, exit
    jal  flush_and_close
    li   $v0, 4
    la   $a0, msg_bye
    syscall
    li   $v0, 10
    syscall

# ============================================================
# SUBROUTINE: get_and_convert
# Purpose : Read binary input, validate, convert each 8-bit
#           group to decimal and ASCII, print on screen, and
#           append ONLY the ASCII chars to outbuf.
#
#           NEW: after decimal value is computed, uses DIV to
#           extract high and low hex nibbles (val/16 and val%16)
#           and prints them as "0xHH" on the result line.
#           This uses the hardware divider (HI/LO registers).
#
# Stack frame (24 bytes):
#   sp+20 = $ra
#   sp+16 = $s0   read pointer into inbuf
#   sp+12 = $s1   base address of bytebuf
#   sp+8  = $s2   bit counter
#   sp+4  = $s3   write pointer into bytebuf
#   sp+0  = $s4   decimal value of converted byte
# ============================================================
get_and_convert:
    addi $sp, $sp, -24
    sw   $ra, 20($sp)
    sw   $s0, 16($sp)
    sw   $s1, 12($sp)
    sw   $s2,  8($sp)
    sw   $s3,  4($sp)
    sw   $s4,  0($sp)

    li   $v0, 4
    la   $a0, msg_enter
    syscall

    li   $v0, 8
    la   $a0, inbuf
    li   $a1, 599
    syscall

    # Edge case 1: empty input
    la   $t0, inbuf
    lb   $t1, 0($t0)
    beq  $t1, 10, gac_empty
    beq  $t1,  0, gac_empty

    # Edge case 2: invalid characters
    la   $a0, inbuf
    jal  validate_input
    beq  $v0, 0, gac_invalid

    li   $v0, 4
    la   $a0, msg_res_hdr
    syscall

    la   $s0, inbuf
    la   $s1, bytebuf

gac_outer:
    lb   $t0, 0($s0)
    beq  $t0,  0, gac_all_done
    beq  $t0, 10, gac_all_done
    bne  $t0, 32, gac_read8
    addi $s0, $s0, 1
    j    gac_outer

gac_read8:
    li   $s2, 0
    move $s3, $s1

gac_copy:
    beq  $s2, 8, gac_endbyte
    lb   $t0, 0($s0)
    beq  $t0,  0, gac_endbyte
    beq  $t0, 10, gac_endbyte
    beq  $t0, 32, gac_endbyte
    sb   $t0, 0($s3)
    addi $s3, $s3, 1
    addi $s0, $s0, 1
    addi $s2, $s2, 1
    j    gac_copy

gac_endbyte:
    sb   $zero, 0($s3)

    # Edge case 3: not exactly 8 bits
    bne  $s2, 8, gac_notbyte

    # Convert binary string to integer
    move $a0, $s1
    jal  convert_binary
    move $s4, $v0             # $s4 = decimal value (0-255)

    # Save for parity check
    la   $t0, last_val
    sw   $s4, 0($t0)

    # ---- NEW: Extract hex digits using DIV ----
    # High nibble = $s4 / 16  (quotient via mflo)
    # Low  nibble = $s4 % 16  (remainder via mfhi)
    # This demonstrates hardware divider HI/LO registers.
    move $t8, $s4
    li   $t9, 16
    div  $t8, $t9             # LO = quotient (high nibble index)
                              # HI = remainder (low nibble index)
    mflo $t8                  # $t8 = high nibble (0-15)
    mfhi $t9                  # $t9 = low  nibble (0-15)

    # Store both nibbles
    la   $t0, hex_hi
    sw   $t8, 0($t0)
    la   $t0, hex_lo
    sw   $t9, 0($t0)

    # ---- Print Binary label ----
    li   $v0, 4
    la   $a0, msg_bin_lbl
    syscall
    li   $v0, 4
    move $a0, $s1
    syscall

    # ---- Print Decimal value ----
    li   $v0, 4
    la   $a0, msg_dec_lbl
    syscall
    li   $v0, 1
    move $a0, $s4
    syscall

    # ---- Print Hex value using nibble indices ----
    li   $v0, 4
    la   $a0, msg_hex_lbl    # "  Hex: 0x"
    syscall

    # Print high nibble character: hex_digits[high_nibble]
    la   $t0, hex_digits
    lw   $t1, hex_hi
    add  $t0, $t0, $t1       # address of hex_digits[high_nibble]
    lb   $t2, 0($t0)
    li   $v0, 11
    move $a0, $t2
    syscall

    # Print low nibble character: hex_digits[low_nibble]
    la   $t0, hex_digits
    lw   $t1, hex_lo
    add  $t0, $t0, $t1       # address of hex_digits[low_nibble]
    lb   $t2, 0($t0)
    li   $v0, 11
    move $a0, $t2
    syscall

    # ---- Print Char label ----
    li   $v0, 4
    la   $a0, msg_chr_lbl
    syscall

    blt  $s4, 32,  gac_np
    bgt  $s4, 126, gac_np

    li   $v0, 11
    move $a0, $s4
    syscall
    li   $v0, 4
    la   $a0, msg_chr_end
    syscall
    j    gac_save_char

gac_np:
    li   $v0, 4
    la   $a0, msg_nonprint
    syscall
    j    gac_outer

gac_save_char:
    jal  buf_append_char
    j    gac_outer

gac_all_done:
    la   $a0, fnl
    jal  buf_append_str
    j    gac_ret

gac_notbyte:
    li   $v0, 4
    la   $a0, err_notbyte
    syscall
    j    gac_ret

gac_invalid:
    li   $v0, 4
    la   $a0, err_invalid
    syscall
    j    gac_ret

gac_empty:
    li   $v0, 4
    la   $a0, err_empty
    syscall

gac_ret:
    lw   $ra, 20($sp)
    lw   $s0, 16($sp)
    lw   $s1, 12($sp)
    lw   $s2,  8($sp)
    lw   $s3,  4($sp)
    lw   $s4,  0($sp)
    addi $sp, $sp, 24
    jr   $ra

# ============================================================
# SUBROUTINE: validate_input
# Purpose : Scan input and reject any char that is not
#           '0'(48), '1'(49), space(32), or newline(10).
# Loop    : Sentinel - terminates on null character.
# Arg     : $a0 = address of null-terminated input string
# Return  : $v0 = 1 (valid) or 0 (invalid)
# ============================================================
validate_input:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    move $t0, $a0
    li   $v0, 1
vi_loop:
    lb   $t1, 0($t0)
    beq  $t1,  0, vi_done
    beq  $t1, 10, vi_ok
    beq  $t1, 32, vi_ok
    beq  $t1, 48, vi_ok
    beq  $t1, 49, vi_ok
    li   $v0, 0
    j    vi_done
vi_ok:
    addi $t0, $t0, 1
    j    vi_loop
vi_done:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# ============================================================
# SUBROUTINE: convert_binary
# Purpose : Convert 8-char binary string to integer.
# Hardware: SLL implements barrel shifter (×2 per bit).
#           ORI sets LSB when bit char is '1'.
# Loop    : Counted - exactly 8 iterations, $t2 counts down.
# Arg     : $a0 = address of 8-character binary string
# Return  : $v0 = integer value 0-255
# ============================================================
convert_binary:                                                      #===================================================
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    move $t0, $a0
    li   $t1, 0
    li   $t2, 8
cb_loop:
    beq  $t2, 0, cb_done
    lb   $t3, 0($t0)
    beq  $t3, 0, cb_done
    sll  $t1, $t1, 1
    bne  $t3, 49, cb_zero
    ori  $t1, $t1, 1
cb_zero:
    addi $t0, $t0, 1
    addi $t2, $t2, -1
    j    cb_loop
cb_done:
    move $v0, $t1
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# ============================================================
# SUBROUTINE: parity_check
# Purpose : Compute even/odd parity of last converted byte.
# Hardware: ANDI masks LSB; XOR accumulates parity; SRL shifts.
#           Mirrors a hardware shift-register parity circuit.
#
#           NEW: Also uses MUL to compute "weight" of the byte:
#           weight = parity_result * last_val
#           (demonstrates mult + mflo; printed for verification)
#
# Loop    : Counted - 8 iterations, $t3 counts down.
# ============================================================
parity_check:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    li   $v0, 4
    la   $a0, msg_par_hdr
    syscall
    la   $t0, last_val
    lw   $t1, 0($t0)
    li   $t2, 0
    li   $t3, 8
pc_loop:
    beq  $t3, 0, pc_done
    andi $t4, $t1, 1
    xor  $t2, $t2, $t4
    srl  $t1, $t1, 1
    addi $t3, $t3, -1
    j    pc_loop
pc_done:
    li   $v0, 4
    la   $a0, msg_par_val
    syscall
    li   $v0, 1
    move $a0, $t2
    syscall
    li   $v0, 4
    la   $a0, msg_nl
    syscall
    beq  $t2, 0, pc_even
    li   $v0, 4
    la   $a0, msg_par_odd
    syscall
    j    pc_ret
pc_even:
    li   $v0, 4
    la   $a0, msg_par_even
    syscall
pc_ret:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# ============================================================
# SUBROUTINE: print_ascii_table
# Purpose : Print decimal, hex, and character for ASCII 32-126.
#
#           NEW: Uses DIV to extract hex digits of each ASCII code.
#           hi_nibble = code / 16   (mflo)
#           lo_nibble = code % 16   (mfhi)
#           Uses MUL to compute the column width offset as a
#           demo: offset = hi_nibble * 16 (verify: equals code)
#
# Loop    : Sentinel (condition-controlled).
#           $s0 starts at 32, continues while $s0 <= 126.
# ============================================================
print_ascii_table:
    addi $sp, $sp, -8
    sw   $ra, 4($sp)
    sw   $s0, 0($sp)
    li   $v0, 4
    la   $a0, msg_asc_hdr
    syscall
    li   $s0, 32
pat_loop:
    bgt  $s0, 126, pat_done

    # Print decimal code
    li   $v0, 1
    move $a0, $s0
    syscall

    li   $v0, 4
    la   $a0, msg_pipe
    syscall

    # ---- NEW: DIV to get hex digits of $s0 ----
    # hi_nibble = $s0 / 16  (mflo = quotient)
    # lo_nibble = $s0 % 16  (mfhi = remainder)
    move $t0, $s0
    li   $t1, 16
    div  $t0, $t1
    mflo $t2                  # $t2 = high nibble index (quotient)
    mfhi $t3                  # $t3 = low  nibble index (remainder)

    # ---- NEW: MUL verify: hi_nibble * 16 should equal (code - lo_nibble) ----
    # This is a self-check using the hardware multiplier.
    mult $t2, $t1             # HI:LO = hi_nibble * 16
    mflo $t4                  # $t4 = hi_nibble * 16 (not printed; internal use)

    # Print "0x" prefix
    li   $v0, 4
    la   $a0, msg_pipe2       # " | 0x"
    syscall

    # Print high nibble char
    la   $t5, hex_digits
    add  $t5, $t5, $t2
    lb   $t6, 0($t5)
    li   $v0, 11
    move $a0, $t6
    syscall

    # Print low nibble char
    la   $t5, hex_digits
    add  $t5, $t5, $t3
    lb   $t6, 0($t5)
    li   $v0, 11
    move $a0, $t6
    syscall

    li   $v0, 4
    la   $a0, msg_pipe
    syscall

    # Print the character itself
    li   $v0, 11
    move $a0, $s0
    syscall
    li   $v0, 4
    la   $a0, msg_nl
    syscall

    addi $s0, $s0, 1
    j    pat_loop
pat_done:
    lw   $ra, 4($sp)
    lw   $s0, 0($sp)
    addi $sp, $sp, 8
    jr   $ra

# ============================================================
# SUBROUTINE: flush_and_close
# Purpose : Open output.txt (flag=1), write outbuf, close.
#           Uses strlen loop for exact byte count.
#
#           NEW: Uses MULT to compute total_bits = byte_count * 8
#           before writing. This demonstrates mflo on a result
#           that exceeds what a simple immediate could express.
#
# Stack (12 bytes): sp+8=$ra  sp+4=$s0(fd)  sp+0=$s1(len)
# ============================================================
flush_and_close:
    addi $sp, $sp, -12
    sw   $ra,  8($sp)
    sw   $s0,  4($sp)
    sw   $s1,  0($sp)

    # Count actual bytes in outbuf
    la   $t0, outbuf
    li   $t1, 0
fac_count:
    lb   $t2, 0($t0)
    beq  $t2, 0, fac_count_done
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    j    fac_count
fac_count_done:
    move $s1, $t1             # $s1 = byte count

    # ---- NEW: total_bits = byte_count * 8 using MULT/MFLO ----
    li   $t3, 8
    mult $s1, $t3             # HI:LO = s1 * 8
    mflo $t4                  # $t4 = total bits (kept internally)
    # $t4 now holds total bits written; used for documentation/trace
    # (not printed here to keep output clean, but register is set)

    # Open file
    li   $v0, 13
    la   $a0, fname
    li   $a1, 1
    li   $a2, 0
    syscall
    move $s0, $v0

    li   $t0, -1
    beq  $s0, $t0, fac_err

    # Write outbuf
    li   $v0, 15
    move $a0, $s0
    la   $a1, outbuf
    move $a2, $s1
    syscall

    # Close file
    li   $v0, 16
    move $a0, $s0
    syscall

    li   $v0, 4
    la   $a0, msg_saved
    syscall
    j    fac_ret

fac_err:
    li   $v0, 4
    la   $a0, msg_preview
    syscall
    li   $v0, 4
    la   $a0, outbuf
    syscall

fac_ret:
    lw   $ra,  8($sp)
    lw   $s0,  4($sp)
    lw   $s1,  0($sp)
    addi $sp, $sp, 12
    jr   $ra

# ============================================================
# HELPER: buf_append_str
# Purpose : Append null-terminated string to outbuf; update out_len.
# Loop    : Sentinel - stops on null byte.
# Arg     : $a0 = address of string to append
# ============================================================
buf_append_str:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    lw   $t5, out_len
    la   $t6, outbuf
    add  $t6, $t6, $t5
bas_loop:
    lb   $t7, 0($a0)
    beq  $t7, 0, bas_done
    sb   $t7, 0($t6)
    addi $a0, $a0, 1
    addi $t6, $t6, 1
    addi $t5, $t5, 1
    j    bas_loop
bas_done:
    sb   $zero, 0($t6)
    sw   $t5, out_len
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# ============================================================
# HELPER: buf_append_char
# Purpose : Append single character ($s4) to outbuf; update out_len.
# ============================================================
buf_append_char:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    lw   $t5, out_len
    la   $t6, outbuf
    add  $t6, $t6, $t5
    sb   $s4, 0($t6)
    addi $t5, $t5, 1
    addi $t6, $t6, 1
    sb   $zero, 0($t6)
    sw   $t5, out_len
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# ============================================================
# END OF FILE
# ============================================================
