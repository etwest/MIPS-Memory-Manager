# Structure of ll node is as follows
#--------- 4 bytes ---------#
#           Flags           # (is memory free?, uinitialized?, allocated?)
#---------------------------#
#        PrevPointer        # (is head if prevPointer = 0)
#---------------------------#
#        NextPointer        # (is tail if flags say so)
#---------------------------#
#           Memory          #
#             .             #
#             .             #
#             .             #
#---------------------------#

# Last bit of flags indicates if the memory has been initialized
# Second to last bit indicates if the memory is free
# Flags = 00 => memory free and uninitialized (default state)
# Flags = 01 => memory free and initialized (used syscall 9)
# Flags = 11 => memory allocated and initialized (We have given this address for use by a program)

# IMPORTANT: only the last node of the ll should be uninitialized. We also use un-init
#            to indicate the tail of the ll

# 12 is the size of this struct. It often shows up in the later code as a magic number

############################################################
# function to create a new node of the ll
# $a0 contains the address at which to construct this node
# $a1 gives the size of the node being constructed
# Doesn't return anything
############################################################
newNode:
addi $sp, $sp, -4	# Save s registers on the stack
sw $s0, 0($sp)
addi $sp, $sp, -4
sw $s1, 0($sp)
move $s0, $ra		# Save return address in s register
move $s1, $a1 		# Save size in s1

move $a1, $zero		# Set struct variables to zero in new node
jal setPrev
jal setFlags

addi $a1, $s1, 12	# Set the next pointer to be node pointer + size + 12
add $a1, $a1, $a0
jal setNext

move $ra, $s0		# Restore variables and return
lw $s1, 0($sp)
addi $sp, $sp, 4
lw $s0, 0($sp)
addi $sp, $sp, 4
jr $ra


############################################################
# function to print the list for debugging purposes
# $a0 is the node from which to begin printing
############################################################
PrintMemList:
addi $sp, $sp, -4
sw $s0, 0($sp)
addi $sp, $sp, -4
sw $s1, 0($sp)
addi $sp, $sp, -4
sw $s2, 0($sp)
addi $sp, $sp, -4
sw $s3, 0($sp)
move $s3, $ra
move $s0, $a0

print_loop:
move $a0, $s0
jal getSize		# print the size
move $a0, $v0
li $v0, 1
syscall
li $v0, 11
li $a0, '('
syscall

move $a0, $s0
li $v0, 34
syscall			# print the memory address
li $v0, 11
li $a0, ','
syscall
move $a0, $s0
jal getPrev
move $a0, $v0
li $v0, 34
syscall			# print the prev pointer
li $v0, 11
li $a0, ','
syscall
move $a0, $s0
jal getNext
move $a0, $v0
li $v0, 34
syscall			# print the next pointer
li $v0, 11
li $a0, ','
syscall

move $a0, $s0
jal getAlloc
move $s1, $v0
jal getInit
move $s2, $v0

beqz $s1, print_free
li $v0, 11
li $a0, 'a' 		# this memory is allocated somewhere
syscall
b done_free
print_free:
li $v0, 11
li $a0, 'f' 		# this memory is free
syscall
done_free:

beqz $s2, print_uninit
li $v0, 11
li $a0, 'i' 		# this memory is initialized
syscall
b done_init
print_uninit:
li $v0, 11
li $a0, 'u' 		# this memory is uninitialized
syscall
done_init:

li $a0, ')'
syscall

beqz $s2, done_print	# if node is uninit (tail) then exit the function
li $v0, 11
li $a0, '-'
syscall
li $v0, 11
li $a0, '>'
syscall 		# print an arrow
move $a0, $s0
jal getNext		# get the next ll_node to print
move $s0, $v0
b print_loop

done_print:
move $ra, $s3
lw $s3, 0($sp)
addi $sp, $sp, 4
lw $s2, 0($sp)
addi $sp, $sp, 4
lw $s1, 0($sp)
addi $sp, $sp, 4
lw $s0, 0($sp)
addi $sp, $sp, 4
li $a0, '\n'
li $v0, 11
syscall
jr $ra

############################################################
# function to check if the ll node at $a0 can be merged with
# either of its neighbors. (If they're free)
# Argument: $a0 : address of ll node
############################################################
Merge:
addi $sp, $sp, -4
sw $s0, 0($sp)
addi $sp, $sp, -4
sw $s1, 0($sp)
addi $sp, $sp, -4
sw $s2, 0($sp)
move $s0, $a0
move $s1, $ra
# first assert that this block is really free and initialized
jal getAlloc
bnez $v0, invalid_block
jal getInit
beqz $v0, invalid_block
b valid_block

invalid_block:		# Restore s variables and exit
move $ra, $s1
lw $s2 0($sp)
addi $sp, $sp, 4
lw $s1 0($sp)
addi $sp, $sp, 4
lw $s0, 0($sp)
addi $sp, $sp, 4
jr $ra

valid_block:
move $a0, $s0
jal getPrev  		#### Try to merge with prev
beqz $v0, skip_merge1	# We are head so skip merge w/ prev
move $s2, $v0
move $a0, $s2
jal getAlloc 		# Check if prev is free
bnez $v0, skip_merge1
move $a0, $s0           # get our next pointer
jal getNext
move $s0, $v0		# don't need our pointer so put next ptr there

move $a0, $s2		# set next of prev to our next. So we're skipped
move $a1, $s0
jal setNext
move $a0, $s0		# set prev of next to our prev. So we're skipped
move $a1, $s2
jal setPrev		

move $s0, $s2		# Original node no longer exists. Do next check on prev

skip_merge1: 		#### Try to merge with next
move $a0, $s0		# get next pointer
jal getNext
move $s2, $v0
move $a0, $s2
jal getAlloc
bnez $v0, skip_merge2 	# skip merge if it is not free
move $a0, $s2
jal getInit
beqz $v0, skip_merge2	# skip merge if next is not initialized
move $a0, $s2
jal getNext 		# next of next
move $s2, $v0		# skipping next so we don't need it's pointer anymore

move $a0, $s2
move $a1, $s0
jal setPrev 		# set prev of next+next to us
move $a0, $s0
move $a1, $s2
jal setNext 		# set our next to next+next

skip_merge2:		# Restore s registers and return
move $ra, $s1
lw $s2 0($sp)
addi $sp, $sp, 4
lw $s1 0($sp)
addi $sp, $sp, 4
lw $s0, 0($sp)
addi $sp, $sp, 4
jr $ra


############################################################
# A function to split the ll node specified ($a0) into two
# with the split off chunk having a size of $a1
############################################################
Split:
addi $sp, $sp, -4
sw $s0, 0($sp)
addi $sp, $sp, -4
sw $s1, 0($sp)
addi $sp, $sp, -4
sw $s2, 0($sp)
addi $sp, $sp, -4
sw $s3, 0($sp)

move $s0, $a0
move $s1, $ra
move $s2, $a1

jal getAlloc		# Assert that this block we're splitting is free
bnez $v0, bad_split

move $a0, $s0
jal getSize		# Assert that the block we're spltting is big enough
blt $v0, $s2, bad_split
beq $v0, $s2, eq_split	# Check if they're asking for a block of equal size
move $s3, $v0		# Save size for later

b good_split

bad_split:
move $ra, $s1
lw $s3, 0($sp)
addi $sp, $sp, 4
lw $s2, 0($sp)
addi $sp, $sp, 4
lw $s1 0($sp)
addi $sp, $sp, 4
lw $s0, 0($sp)
addi $sp, $sp, 4
li $v0, -1 		# This split failed
jr $ra

eq_split: 		# asking for a split which is exactly equal so just return me
move $a0, $s0
jal setAllocTrue 	# Set self alloc

move $ra, $s1 		# Return
move $v0, $s0
lw $s3, 0($sp)
addi $sp, $sp, 4
lw $s2, 0($sp)
addi $sp, $sp, 4
lw $s1 0($sp)
addi $sp, $sp, 4
lw $s0, 0($sp)
addi $sp, $sp, 4
jr $ra

good_split:
# add a new node after this node which contains remaining size after splitting
# set the current node to be allocated and of requested size
move $a0, $s0
jal getMemAddr
add $s3, $v0, $s2 	# s3 = address of new node = cur_mem_addr + req_size
move $a0, $s0
jal getSize

sub $t0, $v0, $s2	# size of new node = size of current node - req_size - 12
move $a0, $s3
addi $a1, $t0, -12
jal newNode

move $a0, $s0
jal getNext		# get our next pointer and save it in s2
move $s2, $v0

move $a0, $s0
move $a1, $s3
jal setNext		# set current node's next pointer to new node

move $a0, $s0
jal getFlags		# set new node's flags to current node's
move $a0, $s3
move $a1, $v0
jal setFlags

move $a0, $s0
jal setAllocTrue	# set current node to be allocated
move $a0, $s0
jal setInitTrue		# set current node to be initialized

move $a0, $s3
move $a1, $s0
jal setPrev		# set new node's prev pointer to current node

move $v0, $s0		# Return the address of the current node. Alloc will need to return memAddr
move $ra, $s1
lw $s3, 0($sp)
addi $sp, $sp, 4
lw $s2, 0($sp)
addi $sp, $sp, 4
lw $s1 0($sp)
addi $sp, $sp, 4
lw $s0, 0($sp)
addi $sp, $sp, 4
jr $ra


# The following are helper functions for the linked list
# The first argument $a0 is always the address of the linked list node in question
getFlags:
lw $v0, 0($a0)
jr $ra
setFlags:
sw $a1, 0($a0)
jr $ra

getAlloc:
lw $t0, 0($a0)
andi $v0, $t0, 2
jr $ra
setAllocTrue:
lw $t0, 0($a0)
ori $t0, $t0, 2
sw $t0, 0($a0)
jr $ra
setAllocFalse:
lw $t0, 0($a0)
andi $t0, $t0, 13
sw $t0, 0($a0)
jr $ra

getInit:
lw $t0, 0($a0)
andi $v0, $t0, 1
jr $ra
setInitTrue:
lw $t0, 0($a0)
ori $t0, $t0, 1
sw $t0, 0($a0)
jr $ra

getPrev:
lw $v0, 4($a0)
jr $ra
setPrev:
sw $a1, 4($a0)
jr $ra

getNext:
lw $v0, 8($a0)
jr $ra
setNext:
sw $a1, 8($a0)
jr $ra

getSize: 		# Size is (next pointer) - (node address) - 12
addi $sp, $sp, -4	# Save return address on stack
sw $ra, 0($sp)
jal getNext		# v0 now holds next pointer
sub $v0, $v0, $a0
addi $v0, $v0, -12
lw $ra, 0($sp)
addi $sp, $sp, 4	# Restore return address
jr $ra

getMemAddr:		# Don't have variable to track this. It's just address of linked list node + 12.
addi $v0, $a0, 12
jr $ra
