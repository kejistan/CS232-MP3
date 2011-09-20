.data
newline:	  .asciiz "\n"			# useful for printing commands
			  .word	0 0
node_0:		  .word	node_4, node_2
pad__0:		  .word	0, 0, 0, 0, 0, 0, 0, 0
node_1:		  .word	node_2, node_0
pad__1:		  .word	0, 0, 0, 0, 0, 0
node_2:		  .word	node_5, node_4
pad__2:		  .word	0, 0, 0, 0
node_3:		  .word	node_4, node_1
pad__3:		  .word	0, 0
node_4:		  .word	node_0, node_1
pad__4:		  .word	0, 0, 0, 0, 0, 0
node_5:		  .word	node_2, node_3
pad__5:		  .word	0, 0, 0, 0, 0, 0, 0, 0

.text
# main function
main:
			  sub	$sp, $sp, 4
			  sw	$ra, 0($sp)		# save $ra on stack

			  la	$a0, node_0
			  jal	bit_reverse_ptr
			  la	$a0, node_1
			  jal	bit_reverse_ptr
			  la	$a0, node_2
			  jal	bit_reverse_ptr
			  la	$a0, node_3
			  jal	bit_reverse_ptr
			  la	$a0, node_4
			  jal	bit_reverse_ptr
			  la	$a0, node_5
			  jal	bit_reverse_ptr

# test count_nodes
			  la	$a0, node_0
			  jal	count_nodes
			  move	$a0, $v0
			  jal	print_int_and_space
# this should print 6

# print a newline
			  li	$v0, 4
			  la	$a0, newline
			  syscall

			  lw	$ra, 0($sp)		# restore $ra from stack
			  add	$sp, $sp, 4
			  jr	$ra



print_int_and_space:
			  li	$v0, 1			# load the syscall option for printing ints
			  syscall				# print the element

			  li	$a0, 32			# print a black space (ASCII 32)
			  li	$v0, 11			# load the syscall option for printing chars
			  syscall				# print the char

			  jr	$ra				# return to the calling procedure

print_newline:
			  li	$v0, 4			# at the end of a line, print a newline char.
			  la	$a0, newline
			  syscall
			  jr	$ra

bit_reverse_ptr:					# takes a pointer to a pair of memory locations that we should reverse (and put back)
			  sub	$sp, $sp, 8
			  sw	$ra, 0($sp)
			  sw	$a0, 4($sp)

			  lw	$a0, 0($a0)		# load the first value to reverse
			  jal	bit_reverse
			  lw	$a0, 4($sp)
			  sw	$v0, 0($a0)		# write it back

			  lw	$a0, 4($a0)		# load the second value to reverse
			  jal	bit_reverse
			  lw	$a0, 4($sp)
			  sw	$v0, 4($a0)		# write it back

			  lw	$ra, 0($sp)
			  add	$sp, $sp, 8
			  jr	$ra

## unsigned bit_reverse(unsigned in);
bit_reverse:
			  sub	$sp, $sp, 16	# don't look at this code closely, look at model solution when published.
			  sw	$ra, 0($sp)
			  sw	$s0, 4($sp)
			  sw	$t1, 8($sp)
			  li	$v0, 0
			  li	$t2, 31
			  move	$s0, $a0
			  li	$a0, 0

bit_reverse_loop:
			  srl	$t1, $s0, $a0
			  add	$a0, $a0, 1
			  and	$t1, $t1, 1
			  sll	$t1, $t1, $t2
			  or	$v0, $v0, $t1

			  sub	$t2, $t2, 1
			  blt	$a0, 32, bit_reverse_loop

			  lw	$ra, 0($sp)
			  lw	$s0, 4($sp)
			  lw	$t1, 8($sp)
			  add	$sp, $sp, 16
			  jr	$ra


# ALL your code goes below this line.
#
# We will delete EVERYTHING above the line; DO NOT delete
# the line.
#
# ---------------------------------------------------------------------

## unsigned count_nodes(node_t *node);
count_nodes:
			  sub	$sp, $sp, 16	# allocate some local space
			  sw	$s1, 8($sp)
			  sw	$s0, 4($sp)
			  sw	$ra, 0($sp)
			  move	$s0, $a0		# save the argument
			  lw	$a0, 0($s0)		# node->p[0]
			  and	$t0, $a0, 0x80000000 # MSB_SET?
			  li	$v0, 0			# set return for branch
			  bnez	$t0, count_nodes_return
			  or	$t0, $a0, 0x80000000 # MSB_SET
			  sw	$t0, 0($s0)		# mark the node
			  li	$s1, 1			# initialize return value to 1
			  jal	bit_reverse		# get the valid node pointer
			  move	$a0, $v0
			  jal	count_nodes		# count_nodes(node->p[0])
			  add	$s1, $s1, $v0
			  lw	$a0, 4($s0)		# node->p[1]
			  jal	bit_reverse
			  move	$a0, $v0
			  jal	count_nodes		# count_nodes(node->p[1])
			  add	$v0, $s1, $v0
count_nodes_return:
			  lw	$s1, 8($sp)
			  lw	$s0, 4($sp)
			  lw	$ra, 0($sp)
			  add	$sp, $sp, 16
			  jr	$ra
