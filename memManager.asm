.data
MinSize: .word 0x10 		# 16 bytes
MemorySize: .word 1024000 	# 1 MiB
Head: .word 0 			# Address of the head of the linked list
FailMsg: .asciiz 		"Error! the allocation has failed! Could not find a free block.\n"
FreeErrMsg: .asciiz 		"Error! Could not free an object.\n"

.text
j test
.include "MemManagementList.asm"

############################################################
# The function for allocating memory
# $a0 holds the number of bytes requested
############################################################
alloc:
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

lw $t9, MinSize
bgt $s0, $t9, good_size	# Assert that requested amount of memory is at least minSize bytes
move $s0, $t9		# If not then set request to minSize

good_size:
li $t9, 4
div $s0, $t9		# force memory to be word aligned at a minimum
mfhi $t9
add $s0, $s0, $t9

lw $t0, Head
bnez $t0, head_exists	# first check if the linked list is not yet initialized
li $a0, 12		# Alocate memory for the head node (for now head)
li $v0, 9
syscall 
move $a0, $v0		# location in memory of head
lw $a1, MemorySize
jal newNode		# create the head
sw $v0, Head

head_exists:		# loop through the ll until a free block is found
lw $a0, Head
move $s2, $a0
find_splitable:
move $a0, $s2
jal getAlloc
bnez $v0, do_next	# Skip over allocated memory
move $a0, $s2
jal getSize		# Assert that size is large enough
bge $v0, $s0, splitable
do_next:
move $a0, $s2
jal getNext		# try with the next thing in the ll
move $s2, $v0
beqz $s2, alloc_fail
b find_splitable

splitable:		# perform the split upon a valid node
move $a0, $s2
jal getInit
beqz $v0, alloc_new	# if this node is unititialized then jump to allocating new memory
move $a0, $s2		# take a node which is free and intialized and split that
move $a1, $s0
jal Split		# preform the split
move $s3, $v0		# address of new node
b alloc_done

alloc_new: 		# allocate new memory
addi $a0, $s0, 12	# allocate memory we want (12 for header + req_size)
li $v0, 9
syscall
move $s3, $v0
move $a0, $s2
move $a1, $s0
jal Split		# split the llnode
move $s3, $v0

alloc_done:
move $a0, $s3		# return the memoryAddr
jal getMemAddr
move $ra, $s1
lw $s3, 0($sp)
addi $sp, $sp, 4
lw $s2, 0($sp)
addi $sp, $sp, 4
lw $s1, 0($sp)
addi $sp, $sp, 4
lw $s0, 0($sp)
addi $sp, $sp, 4
jr $ra

alloc_fail:
la $a0, FailMsg
li $v0, 4
syscall
li $v0, -1
move $ra, $s1
lw $s3, 0($sp)
addi $sp, $sp, 4
lw $s2, 0($sp)
addi $sp, $sp, 4
lw $s1, 0($sp)
addi $sp, $sp, 4
lw $s0, 0($sp)
addi $sp, $sp, 4
jr $ra

############################################################
# The function for deallocating memory
# a0 should hold the address of the memory being dealloced
# TODO: Catch case where they attempt to free memory at a 
#       a bad address. Throw an error.
############################################################
free:
addi $sp, $sp, -4
sw $s0, 0($sp)
addi $sp, $sp, -4
sw $s1, 0($sp)
addi $sp, $sp, -4
sw $s2, 0($sp)
move $s0, $a0
move $s1, $ra

addi $s0, $s0, -12		# Subtract 12 from the ll_node to get its address

move $a0, $s0
jal setAllocFalse		# Set this ll node to be free

move $a0, $s0
jal Merge

move $ra, $s1
lw $s2, 0($sp)
addi $sp, $sp, 4
lw $s1, 0($sp)
addi $sp, $sp, 4
lw $s0, 0($sp)
addi $sp, $sp, 4
jr $ra

free_fail:
la $a0, FreeErrMsg	# we could not find the memory they wanted to free
li $v0, 4
syscall
move $ra, $s1
lw $s2, 0($sp)
addi $sp, $sp, 4
lw $s1, 0($sp)
addi $sp, $sp, 4
lw $s0, 0($sp)
addi $sp, $sp, 4
jr $ra

############################################################
# Just a function to test the linked list 
# and the alloc/free functions
############################################################
test:
sw $zero, Head 		# reset Head for alloc tests
li $a0, 100
jal alloc
move $s0, $v0		# address of alloced memory
lw $a0, Head
jal PrintMemList	# 100(ai) -> tail

move $a0, $s0
jal free
lw $a0, Head
jal PrintMemList	# 100(fi) -> tail

li $a0, 512
jal alloc
move $s1, $v0
lw $a0, Head
jal PrintMemList	# 100(fi) -> 512(ai) -> tail

li $a0, 256
jal alloc
move $s2, $v0
lw $a0, Head
jal PrintMemList	# 100(fi) -> 512(ai) -> 256(ai) -> tail

li $a0, 2048
jal alloc
move $s3, $v0
lw $a0, Head
jal PrintMemList	# 100(fi) -> 512(ai) -> 256(ai) -> 2048(ai) -> tail

li $a0, 100
jal alloc
move $s4, $v0
lw $a0, Head
jal PrintMemList	# 100(ai) -> 512(ai) -> 256(ai) -> 2048(ai) -> tail

move $a0, $s1
jal free
lw $a0, Head
jal PrintMemList	# 100(ai) -> 512(fi) -> 256(ai) -> 2048(ai) -> tail

move $a0, $s2
jal free
lw $a0, Head
jal PrintMemList	# 100(ai) -> 780(fi) -> 2048(ai) -> tail  // increase by more than 512+256 b/c header

move $a0, $s3
jal free
lw $a0, Head
jal PrintMemList	# 100(ai) -> 2816(fi) -> tail

move $a0, $s4
jal free
lw $a0, Head
jal PrintMemList	# 2916(fi) -> tail

li $a0, 100
jal alloc
move $s1, $v0
lw $a0, Head
jal PrintMemList	# 100(ai) -> 2804(fi) -> tail

li $a0, 100
jal alloc
move $s2, $v0
lw $a0, Head
jal PrintMemList	# 100(ai) -> 100(ai) -> 2692(fi) -> tail

li $a0, 100
jal alloc
move $s3, $v0
lw $a0, Head
jal PrintMemList	# 100(ai) -> 100(ai) -> 100(ai) -> 2580(fi) -> tail

move $a0, $s3
jal free
lw $a0, Head
jal PrintMemList	# 100(ai) -> 100(ai) -> 2692(fi) -> tail

move $a0, $s1
jal free
lw $a0, Head
jal PrintMemList	# 100(fi) -> 100(ai) -> 100(ai) -> 2580(fi) -> tail

move $a0, $s2
jal free
lw $a0, Head
jal PrintMemList	# 2916(fi) -> tail

li $v0 10
syscall
