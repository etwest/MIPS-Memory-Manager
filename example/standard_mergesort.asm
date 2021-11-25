.data
array: .space 1024 	# this array will be instantiated and then sorted
.text 
j main

############################################################
# Insantiate the array values
############################################################
createArray:
li $t0, 0
li $t1, 256 		# 256 words = 1024 bytes
la $t2, array
creation_loop:
bge $t0, $t1, done_creating
sll $t3, $t0, 2 	# multiply by 4

li $t9, 7
mul $t4, $t0, $t9
li $t9, 269
div $t4, $t9
mfhi $t4		# create a 'shuffled' array by performing mod
add $t3, $t3, $t2	# get the actual addr of the array
sw $t4, 0($t3)
addi $t0, $t0, 1
b creation_loop
done_creating:
jr $ra


############################################################
# Print an array
# $a0 the pointer to the array to print
# $a1 the size of the array to print (in words)
############################################################
printArray:
li $t0, 1
move $t1, $a1
move $t2, $a0
lw $a0, 0($t2)
li $v0, 1
syscall
print_arr_loop:
bge $t0, $t1, done_print_loop
sll $t3, $t0, 2 	# multiply by 4
add $t3, $t3, $t2	# get the actual addr of the array
li $a0, ','
li $v0, 11
syscall
lw $a0, 0($t3)		# load the array element
li $v0, 1
syscall
addi $t0, $t0, 1
b print_arr_loop
done_print_loop:
jr $ra


############################################################
# copy array copies array elements from one array to another
# a0 is the array to copy from
# a1 the array to copy to
# a2 the size of the second array (in words)
############################################################
copy_array:
li $t0, 0
copying_loop:
bge $t0, $a2, done_copying
sll $t3, $t0, 2 	# multiply by 4
add $t4, $t3, $a1
add $t3, $t3, $a0
lw $t5, 0($t3)
sw $t5, 0($t4)
addi $t0, $t0, 1
b copying_loop
done_copying:
jr $ra

############################################################
# merges two sorted arrays into one sorted array
# a0 the array where the result should go
# On the stack we have in this order
# | pointer to first array  |
# |   size of first array   | // in words
# | pointer to second array |
# |  size of second array   | // in words
############################################################
merge_step:
lw $t0, 0($sp)			# first array pointer
addi $sp, $sp, 4
lw $t1, 0($sp)			# first array size
addi $sp, $sp, 4
lw $t2, 0($sp)			# second array pointer
addi $sp, $sp, 4
lw $t3, 0($sp)			# second array size
addi $sp, $sp, 4

sll $t1, $t1, 2 		# convert from words to bytes
sll $t3, $t3, 2

add $t1, $t1, $t0		# get end of arrays
add $t3, $t3, $t2

merge_loop:
lw $t4, 0($t0)			# L[i]
lw $t5, 0($t2)			# R[i]
bge $t4, $t5, L_bigger		# L[i] >= R[i]

sw $t4, 0($a0)			# put left into result array and increment it
addi $t0, $t0, 4
b check_cond

L_bigger:
sw $t5, 0($a0)			# put right into result array and incr
addi $t2, $t2, 4

check_cond:
addi $a0, $a0, 4 		# incr result array pointer
bge $t0, $t1, L_empty		# check if either array is empty
bge $t2, $t3, R_empty
b merge_loop

L_empty:
bge $t2, $t3, done 		# Loop over all the remaining elements of R
lw $t5, 0($t2)
sw $t5, 0($a0)			# Put remaining elements in output array
addi $a0, $a0, 4
addi $t2, $t2, 4
b L_empty

R_empty:
bge $t0, $t1, done 		# Loop over all the remaining elements of L
lw $t4, 0($t0)
sw $t4, 0($a0)			# Put remaining elements in output array
addi $a0, $a0, 4
addi $t0, $t0, 4
b R_empty

done:
jr $ra

############################################################
# The actual mergeSort function
# a0 is a pointer to the array to operate on
# a1 is the size of the array (in words)
############################################################
mergeSort:
li $t0, 2
bgt $a1, $t0, do_recursion
move $v0, $a0
blt $a1, $t0, baseCase_done	# This is the base case. Just return the 2 (or 1) element array (sorted)
lw $t1, 0($a0)
lw $t2, 4($a0)
ble $t1, $t2, baseCase_done 	# a0[0] <= a0[1] so don't swap
sw $t2, 0($a0)
sw $t1, 4($a0)			# swap the elements then return
baseCase_done:
jr $ra

do_recursion:
addi $sp, $sp, -4
sw $s0, 0($sp)
addi $sp, $sp, -4
sw $s1, 0($sp)
addi $sp, $sp, -4
sw $s2, 0($sp)
addi $sp, $sp, -4
sw $s3, 0($sp)
addi $sp, $sp, -4
sw $s4, 0($sp)
addi $sp, $sp, -4
sw $s5, 0($sp)
move $s0, $ra
move $s1, $a0

sra $s2, $a1, 1			# divide by 2 to get the SIZE of the FIRST sub array
sub $s3, $a1, $s2		# SIZE of the SECOND sub array
sll $t2, $s2, 2			# get the size in bytes
move $a0, $t2
li $v0, 9
syscall
move $s4, $v0			# Addr of first sub-array

move $a0, $v0
li $v0, 34
syscall				# Print the address of sub-array for memory usage tracking
li $a0, '\n'
li $v0, 11
syscall

move $a0, $s1
move $a1, $s4
move $a2, $s2
jal copy_array			# copy the data to the sub-array

sll $t2, $s3, 2			# get the size in bytes of second sub-array
move $a0, $t2
li $v0, 9
syscall
move $s5, $v0			# Addr of second sub-array

move $a0, $v0
li $v0, 34
syscall				# Print the address of sub-array for memory usage tracking
li $a0, '\n'
li $v0, 11
syscall

move $a0, $s1
sll $t2, $s2, 2 		# size of first sub-array in bytes
add $a0, $a0, $t2		# copy from is array + sizeof(first sub-array)
move $a1, $s5
move $a2, $s3
jal copy_array			# copy the data to the sub-array

move $a0, $s4			# recurisive calls
move $a1, $s2
jal mergeSort
move $a0, $s5
move $a1, $s3
jal mergeSort


move $a0, $s1 			# merged array to be placed in a0
sw $s3, -4($sp)			# Push args onto stack (size right array)
sw $s5, -8($sp)			# pointer right array
sw $s2, -12($sp)		# size left array
sw $s4, -16($sp)		# pointer left array
addi $sp, $sp, -16
jal merge_step			# call merge on the sub arrays

move $ra, $s0			# done with sorting return to caller
lw $s5, 0($sp)
addi $sp, $sp, 4
lw $s4, 0($sp)
addi $sp, $sp, 4
lw $s3, 0($sp)
addi $sp, $sp, 4
lw $s2, 0($sp)
addi $sp, $sp, 4
lw $s1, 0($sp)
addi $sp, $sp, 4
lw $s0, 0($sp)
addi $sp, $sp, 4
jr $ra

main:
# Create and print the array
jal createArray

la $a0, array
li $a1, 256
jal printArray
li $a0, '\n'
li $v0, 11
syscall

# Sort the array using a recurisive mergeSort
la $a0, array
li $a1, 256
jal mergeSort

# Print the sorted array
la $a0, array
li $a1, 256
jal printArray

li $v0, 10
syscall
