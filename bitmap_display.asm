##############################################################################
# Example: Displaying Pixels
#
# This file demonstrates how to draw pixels with different colours to the
# bitmap display.
##############################################################################

######################## Bitmap Display Configuration ########################
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
##############################################################################

# to-do list:
# - collision detection

# DATA
.data
ADDR_DSPL: .word 0x10008000

# this memory address indicates if there's been a key pressed (1) or not (0)
# this memory address + 4 bytes indicates the ascii code of key pressed
KEYBOARD_ADDR: .word 0xffff0000

# saving the hex codes for the colours in an array of 24 bytes (6 words long)             
# red green blue yellow magenta cyan
COLOURS: .word 0xff0000, 0x00ff00, 0x0000ff, 0xffff00, 0xff00ff, 0x00ffff

# this is a pointer to the top pixel of current column, initially set to coordinate (0,0) on grid
CURRENT_COLUMN: .word 0x10008000

# string that corresponds to newline
NEWLINE: .asciiz "hi\n"

# TEXT 
.text
.globl main

main:
    lw $s0, ADDR_DSPL       # $s0 = base address for display

    # draw border
    jal draw_border

    # draw a 3-bit pixel column at 1, 0
    li $a0, 1   # $a0 = x-coordinate argument of make_column
    jal make_column

    game_loop:      
        # sleep for 0.01 sec
        li $v0, 32      # load syscall value for sleep
        li $a0, 10    # sleep for 10 ms
        syscall

        # check to see if keyboard pressed
        lw $t0, KEYBOARD_ADDR   # store memory address of keyboard press
        lw $t8, 0($t0)          # store value at memory address
        beq $t8, 1, keyboard_input  # if 1, some key has been pressed
        j game_loop             # loop back

exit:
    li $v0, 10              # terminate the program gracefully
    syscall

# functions

# keyboard_input: get key pressed and do corresponding action
keyboard_input:
    # preserve registers $a0, $t0, $t7, $v0 by pushing to stack
    addiu $sp, $sp, -4
    sw $a0, 0($sp)

    addiu $sp, $sp, -4
    sw $t0, 0($sp)

    addiu $sp, $sp, -4
    sw $t7, 0($sp)

    addiu $sp, $sp, -4
    sw $v0, 0($sp)

    lw $t0, KEYBOARD_ADDR   # store memory address of keyboard press
    lw $t7, 4($t0)          # gets ascii code for actual key press

    li $v0, 1       # print int syscall
    move $a0, $t7   # prints ascii code of key press
    syscall

    li $v0, 11      # print char syscall
    li $a0, 10      # load ascii code for \n
    syscall         # prints newline
    
    beq $t7, 119, respond_to_w  # 119 is ascii code for 'w' - which indicates we should rotate colours
    beq $t7, 100, respond_to_d  # 100 = ascii code for 'd' - move right  
    beq $t7, 97, respond_to_a   # 97 = ascii code for 'a' - move left
    beq $t7, 115, respond_to_s  # 115 = ascii code for 's' - move down

    # preserve registers by popping from stack
    lw $v0, 0($sp)
    addiu $sp, $sp, 4

    lw $t7, 0($sp)
    addiu $sp, $sp, 4

    lw $t0, 0($sp)
    addiu $sp, $sp, 4

    lw $a0, 0($sp)
    addiu $sp, $sp, 4

    # return
    j game_loop

# respond_to_w: responds to a key press of w to rotate down colours in current column
# No parameters, no return value. All registers are preserved.
respond_to_w:
    # preserve registers $ra by pushing into stack
    addiu $sp, $sp, -4
    sw $ra, 0($sp)

    # call rotate_colours
    jal rotate_colours

    # preserve registers by popping from stack
    lw $ra, 0($sp)
    addiu $sp, $sp, 4

    # return
    jr $ra

# rotate_colours: shifts the colours of the column down
# No arguments, no return value. This function preserves all registers.
rotate_colours:
    # preserve registers $a0, $t0, $t1 by pushing to stack
    addiu $sp, $sp, -4
    sw $a0, 0($sp)

    addiu $sp, $sp, -4
    sw $t0, 0($sp)

    addiu $sp, $sp, -4
    sw $t1, 0($sp)

    # Define top pixel px0, next pixel px1, and last pixel px2
    # $t0 will save the colour of px being overwritten
    # $t1 will be the colour to overwrite with

    # $a0 = pointer to px at top of column $a0
    lw $a0, CURRENT_COLUMN

    # save px1 colour, overwrite px1 colour to be px0
    lw $t0, 128($a0)    # t0 stores px1 colour
    lw $t1, 0($a0)      # t1 stores px0 colour
    sw $t1, 128($a0)    # overwrite px1 to be px0 colour

    # save px2 colour, overwrite px2 colour to be px1's original colour
    move $t1, $t0       # t1 now stores px1 colour
    lw $t0, 256($a0)    # t0 stores px2 colour
    sw $t1, 256($a0)    # overwrite px2 colour to be px1's original colour

    # don't need to save px0 colour, overwrite px0 to be px2's original colour
    move $t1, $t0       # t1 now stores px2's original colour
    sw $t1, 0($a0)      # overwrite px0 colour

    # overwrite pixel below to be current pixel colour
    # preserve registers by popping from stack
    lw $t1, 0($sp)
    addiu $sp, $sp, 4

    lw $t0, 0($sp)
    addiu $sp, $sp, 4

    lw $a0, 0($sp)
    addiu $sp, $sp, 4

    # return
    jr $ra

# respond_to_d: function moves current column right
respond_to_d:
    # preserve registers $ra by pushing to stack
    addiu $sp, $sp, -4
    sw $ra, 0($sp)

    jal move_right

    # preserve registers by popping to stack
    lw $ra, 0($sp)
    addiu $sp, $sp, 4

    jr $ra

# respond_to_a: function moves current column left
respond_to_a:
    # preserve registers $ra by pushing to stack
    addiu $sp, $sp, -4
    sw $ra, 0($sp)

    jal move_left

    # preserve registers by popping to stack
    lw $ra, 0($sp)
    addiu $sp, $sp, 4

    jr $ra

# respond_to_s: function moves current column down
respond_to_s:
    # preserve registers $ra by pushing to stack
    addiu $sp, $sp, -4
    sw $ra, 0($sp)

    jal move_down

    # preserve registers by popping to stack
    lw $ra, 0($sp)
    addiu $sp, $sp, 4

    jr $ra

# move_right: function moves current column right. 
# No arguments. All registers preserved.
move_right:
    # preserve registers $t0, $t1, $t2, $t3 by pushing to stack
    addiu $sp, $sp, -4
    sw $t0, 0($sp)
    addiu $sp, $sp, -4
    sw $t1, 0($sp)
    addiu $sp, $sp, -4
    sw $t2, 0($sp)
    addiu $sp, $sp, -4
    sw $t3, 0($sp)

    # $t0 pointer to current pixel to move - initialized as pointer to top px of current column 
    lw $t0, CURRENT_COLUMN

    # use a for loop to shift the column one to the right
    li $t1, 3   # initial loop variable $t1 to 3
    move_right_loop:
        # if t1 == 0, end loop
        beq $t1, $zero, move_right_loop_end
        # $t2 is current px colour
        lw $t2, 0($t0)
        # colour px to the right
        sw $t2, 4($t0)
        # colour original px black
        sw $zero, 0($t0)
        # decrement loop variable
        addi $t1, $t1, -1
        # increment pointer to current px to next px down in the column
        addi $t0, $t0, 128
        # repeat loop
        j move_right_loop
    
    move_right_loop_end:
    # modify CURRENT_COLUMN to store pointer to the top px of new column
    lw $t0, CURRENT_COLUMN  # this is pointer to top px of old column
    addi $t0, $t0, 4        # pointer to top px of new column
    la $t3, CURRENT_COLUMN  # this is memory address of CURRENT_COLUMN
    sw $t0, 0($t3)          # store modified pointer to CURRENT_COLUMN
    
    # preserve registers by popping from stack
    lw $t3, 0($sp)
    addiu $sp, $sp, 4
    lw $t2, 0($sp)
    addiu $sp, $sp, 4
    lw $t1, 0($sp)
    addiu $sp, $sp, 4 
    lw $t0, 0($sp)
    addiu $sp, $sp, 4

    # return
    jr $ra   

# move_left: function moves current column left. 
# No arguments.  All registers preserved.
move_left:
    # preserve registers $t0, $t1, $t2, $t3 by pushing to stack
    addiu $sp, $sp, -4
    sw $t0, 0($sp)
    addiu $sp, $sp, -4
    sw $t1, 0($sp)
    addiu $sp, $sp, -4
    sw $t2, 0($sp)
    addiu $sp, $sp, -4
    sw $t3, 0($sp)

    # $t0 pointer to current pixel to move - initialized as pointer to top px of current column 
    lw $t0, CURRENT_COLUMN

    # use a for loop to shift the column one to the left
    li $t1, 3   # initial loop variable $t1 to 3
    move_left_loop:
        # if t1 == 0, end loop
        beq $t1, $zero, move_left_loop_end
        # $t2 is current px colour
        lw $t2, 0($t0)
        # colour px to the left
        sw $t2, -4($t0)
        # colour original px black
        sw $zero, 0($t0)
        # decrement loop variable
        addi $t1, $t1, -1
        # increment pointer to current px to next px down in the column
        addi $t0, $t0, 128
        # repeat loop
        j move_left_loop
    
    move_left_loop_end:
    # modify CURRENT_COLUMN to store pointer to the top px of new column
    lw $t0, CURRENT_COLUMN  # this is pointer to top px of old column
    addi $t0, $t0, -4       # pointer to top px of new column
    la $t3, CURRENT_COLUMN  # this is memory address of CURRENT_COLUMN
    sw $t0, 0($t3)          # store modified pointer to CURRENT_COLUMN
    
    # preserve registers by popping from stack
    lw $t3, 0($sp)
    addiu $sp, $sp, 4
    lw $t2, 0($sp)
    addiu $sp, $sp, 4
    lw $t1, 0($sp)
    addiu $sp, $sp, 4 
    lw $t0, 0($sp)
    addiu $sp, $sp, 4

    # return
    jr $ra   

# move_down: function to shift column down
move_down:
    # preserve registers $t0, $t1, $t2, $t3 by pushing to stack
    addiu $sp, $sp, -4
    sw $t0, 0($sp)

    addiu $sp, $sp, -4
    sw $t1, 0($sp)

    addiu $sp, $sp, -4
    sw $t2, 0($sp)

    addiu $sp, $sp, -4
    sw $t3, 0($sp)

    # $t0 = pointer to px that'll shift down 1
    lw $t0, CURRENT_COLUMN  # initialized to top px
    addi $t0, $t0, 256      # add 2 row offsets to get it to point to bot px of current column

    # loop variable $t1 initialized to 3; we will shift the px's down, starting bottom of column to top
    li $t1, 3

    move_down_loop:
        beq $t1, $zero, move_down_loop_end

        # px_0 = px we will shift down; px_1 = px that it'll shift to

        lw $t2, 0($t0)      # $t2 = px_0's current colour, that we will shift down
        sw $t2, 128($t0)    # paint px_1
        sw $zero, 0($t0)    # paint px_0 black
        addi $t0, $t0, -128 # shift $t0 up 1 row
        addi $t1, $t1, -1   # decrement loop variable
        j move_down_loop

    move_down_loop_end:
    # change CURRENT_COLUMN down 1 unit
    lw $t0, CURRENT_COLUMN  # this is pointer to old top px of column
    addi $t0, $t0, 128      # this is new pointer to new top of column
    la $t3, CURRENT_COLUMN
    sw $t0, 0($t3)

    # preserve registers by popping from stack
    lw $t3, 0($sp)
    addiu $sp, $sp, 4

    lw $t2, 0($sp)
    addiu $sp, $sp, 4

    lw $t1, 0($sp)
    addiu $sp, $sp, 4

    lw $t0, 0($sp)
    addiu $sp, $sp, 4

    # return
    jr $ra

# draw_line: function to draw a gray horizontal line of a given length at a given x and y-coordinate.
# This function preserves register values.
# $a0 = x-coordinate
# $a1 = y-coordinate
# $a2 = length
draw_line:
    # pushing registers modified in this function to stack to preserve their values at end of function call
    # registers preserved: $t0, $t1, $t2, $t3 in that order
    addiu $sp, $sp, -4
    sw $t0, 0($sp)

    addiu $sp, $sp, -4
    sw $t1, 0($sp)

    addiu $sp, $sp, -4
    sw $t2, 0($sp)

    addiu $sp, $sp, -4
    sw $t3, 0($sp)

    li $t0, 0                   # t0 is loop variable (will increment by 1 from 0 to length-1 inclusive)
    move $t1, $s0               # t1 keeps track of memory address of pixel to draw to
    
    # given the x and y-coordinate, need to calculate how many bytes to offset my memory address to find place to draw next pixel
    # use $t2 to keep track of horizontal and vertical offsets

                                # horizontal offset
    move $t2, $a0               # store initial x-coordinate into $t2
    sll $t2, $t2, 2             # multiply x-coordinate by 4
    add $t1, $t1, $t2           # add to memory address 

                                # vertical offset
    move $t2, $a1               # store initial y-coordinate into $t2
    sll $t2, $t2, 7             # multiply y-coordinate by 128
    add $t1, $t1, $t2           # add to memory address

    line_loop_begin:
        beq $t0, $a2, line_loop_end  # if $t0 == $a2 (loop variable equals length of line), exit loop
        li $t3, 0x808080        # load grey colour code into $t3 
        sw $t3, 0($t1)          # draw pixel
        addi $t0, $t0, 1        # increment loop variable
        addi $t1, $t1, 4        # increment t1 by 4 to load next memory address to draw pixel to
        j line_loop_begin       # repeat loop
    line_loop_end:
    
    # popping registers back to preserve values
    lw $t3, 0($sp)
    addiu $sp, $sp, 4

    lw $t2, 0($sp)
    addiu $sp, $sp, 4    

    lw $t1, 0($sp)
    addiu $sp, $sp, 4

    lw $t0, 0($sp)
    addiu $sp, $sp, 4
    
    jr $ra                      # jump back to where function was called from

# draw_rectangle: draws a rectangle of a given height and width at specified x and y-coordinates
# This function preserves registers.
# $a0 = x-coordinate
# $a1 = y-coordinate
# $a2 = width
# $a3 = height
draw_rectangle:
    # preserve registers $t0, $a1, $ra by pushing to stack
    addiu $sp, $sp, -4
    sw $t0, 0($sp)

    addiu, $sp, $sp, -4             # store original value of y-coordinate ($a1) for box in the stack, since the loop will modify its value
    sw $a1, 0($sp)

    addiu $sp, $sp, -4              # save $ra in stack since we're about to jump and link draw_line 
    sw $ra, 0($sp)

    li $t0, 0   # initialize loop variable $t0

    rect_loop_start:
        beq $t0, $a3, rect_loop_end # if loop variable == height, jump to end of loop

        # addiu $sp, $sp, -4          # otherwise, store $t0 in stack since draw_line modifies it
        # sw $t0, 0($sp)

        # $a0 = x-coordinate, $a1 = y-coordinate, $a2 = length of line
        jal draw_line               # call draw_line

        addi $a1, $a1, 1            # increment value of y-coordinate ($a1) by 1

        # lw $t0, 0($sp)              # restore $t0 from stack
        # addiu $sp, $sp, 4   

        addi $t0, $t0, 1            # increment $t0 by 1
        j rect_loop_start           # jump back to start
    rect_loop_end:
    # pop from stack to preserve registers
    lw $ra, 0($sp)      # restore $ra from stack
    addiu $sp, $sp, 4

    lw $a1, 0($sp)      # restore $a1 from stack
    addiu $sp, $sp, 4

    lw $t0, 0($sp)      # restore $t0 from stack
    addiu $sp, $sp, 4

    jr $ra

# random_colour: generates a random colour (generates a random number 0 <= x <= 5, then uses this to find index of COLOURS array)
# No input arguments. Returns random colour in $v0.
# Function preserves all registers other than $v0.
random_colour:
    # preserve registers $a0, $a1, $t6 by pushing to stack
    addiu $sp, $sp, -4
    sw $a0, 0($sp)

    addiu $sp, $sp, -4
    sw $a1, 0($sp)

    addiu $sp, $sp, -4
    sw $t6, 0($sp)

    li $v0, 42  # syscall for generating random int with a maximum value (exclusive)
    li $a0, 0   # generator id
    li $a1, 6   # maximum value (exclusive)
    syscall     # generates random number between 0 <= x <= 5, stored in $a0 now

    la $t6, COLOURS     # loads memory address of COLOURS array into $t6
    sll $a0, $a0, 2     # multiplies random number x by 4
    add $t6, $t6, $a0   # add 4*x to memory address of COLOURS to get the memory address of random colour
    lw $v0, 0($t6)      # stores random colour into $v0
    
    # restore registers from stack
    lw $t6, 0($sp)
    addiu $sp, $sp, 4

    lw $a1, 0($sp)
    addiu $sp, $sp, 4

    lw $a0, 0($sp)
    addiu $sp, $sp, 4

    jr $ra  # return

# make_column creates a 3-pixel column at a specified initial x coordinate (y-coordinate is always 0). Colours are randomly generated
# $a0 = x-coordinate
# This function preserves all registers. It modifies CURRENT_COLUMN in memory to update memory location of top px of column.
make_column:
    # preserve $ra, $a0, $t0, $t1, $t7, $v0
    addiu $sp, $sp, -4  # store $ra in stack, since we're about to jump and link to random_colour
    sw $ra, 0($sp) 

    addiu $sp, $sp, -4
    sw $a0, 0($sp)

    addiu $sp, $sp, -4
    sw $t0, 0($sp)

    addiu $sp, $sp, -4
    sw $t1, 0($sp)

    addiu $sp, $sp, -4
    sw $t7, 0($sp)

    addiu $sp, $sp, -4
    sw $v0, 0($sp)

    move $t0, $s0       # $t0 will store where to draw pixel. Initialize it to be coordinate (0,0)
    sll $a0, $a0, 2     # multiply $a0 by 4 to indicate how many bytes we have to offset the drawing location by
    add $t0, $t0, $a0   # add the offset to get new drawing location 
    
    # modify CURRENT_COLUMN in memory to memory address of top px of column about to be drawn
    la $t1, CURRENT_COLUMN  # load memory address of CURRENT_COLUMN to $t1
    sw $t0, 0($t1)          # store memory address of top px of column into CURRENT_COLUMN

    # create a loop to draw 3 pixels
    li $t7, 3   # initialize loop variable $t7 to 3
    column_loop_begin:
        beq $t7, $zero, column_loop_end # if loop variable == 0, end loop

        jal random_colour  # call random_colour to get a random colour, which is returned in $v0
        sw $v0, 0($t0)      # draw pixel at location

        addi $t0, $t0, 128  # increase y-coordinate by 1 to get next drawing location, one pixel below now
        addi $t7, $t7, -1   # decrement loop variable by 1
        j column_loop_begin 
    column_loop_end:
    # pop registers from stack
    lw $v0, 0($sp)
    addiu $sp, $sp, 4

    lw $t7, 0($sp)
    addiu $sp, $sp, 4

    lw $t1, 0($sp)
    addiu $sp, $sp, 4

    lw $t0, 0($sp)
    addiu $sp, $sp, 4

    lw $a0, 0($sp)
    addiu $sp, $sp, 4

    lw $ra, 0($sp)      
    addiu $sp, $sp, 4

    jr $ra

# draw_border will create the border for the game
# No arguments and no return values.
# This function preserves all registers.
draw_border:    
    # preserve registers by pushing to stack
    addiu $sp, $sp, -4  
    sw $ra, 0($sp)

    addiu $sp, $sp, -4  
    sw $a0, 0($sp)

    addiu $sp, $sp, -4  
    sw $a1, 0($sp)

    addiu $sp, $sp, -4  
    sw $a2, 0($sp)   

    addiu $sp, $sp, -4  
    sw $a3, 0($sp)

    # draw first column at (0, 0) that is 1 pixel wide and 14 pixels tall
    # will call draw_rectangle with the following arguments
    li $a0, 0       # x-coord = 0
    li $a1, 0       # y-coord = 0
    li $a2, 1       # width = 1
    li $a3, 14

    jal draw_rectangle

    # draw second column at (7, 0) that is 1 px wide and 14 px tall
    # call draw_rectangle with following arguments
    li $a0, 7   # x-coord = 7   
    li $a1, 0   # y-coord = 0
    li $a2, 1   # width = 1
    li $a3, 14  # height = 14

    jal draw_rectangle

    # draw bottom row at (1, 13) that is 6 px wide and 1 px tall
    # call draw_line with following arguments
    li $a0, 1   # x-coord = 1
    li $a1, 13  # y-coord = 13
    li $a2, 6   # width = 1

    jal draw_line

    # pop registers back from the stack
    lw $a3, 0($sp)
    addiu $sp, $sp, 4

    lw $a2, 0($sp)
    addiu $sp, $sp, 4

    lw $a1, 0($sp)
    addiu $sp, $sp, 4

    lw $a0, 0($sp)
    addiu $sp, $sp, 4

    lw $ra, 0($sp)
    addiu $sp, $sp, 4

    jr $ra    


