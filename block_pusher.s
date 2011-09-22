## you get to write this one from scratch.
## we'll only be testing its behavior, not poking your code directly
.data
atan:		  .word	0, 5, 11, 16, 22, 28, 33, 39, 45, 50, 56, 61, 67, 73, 78, 84, 90, 95, 101, 106, 112, 118, 123, 129, 135, 140, 146, 151, 157, 163, 168, 174, 180, 185, 191, 196, 202, 208, 213, 219, 225, 230, 236, 241, 247, 253, 258, 264, 270, 275, 281, 286, 292, 298, 303, 309, 315, 320, 326, 331, 337, 343, 348, 354

.text
main:
			  sub	$sp, $sp, 8
			  sw	$ra, 0($sp)
live:
			  jal	find_closest_block
			  sub	$t0, $v0, 300
			  bgtz	$t0, stop		# closest_x > 300 (invalid case, triggered by no closest blocks)
			  move	$a0, $v0
			  move	$a1, $v1
			  jal	move_block_to_goal
			  j		live
stop:
			  sw	$0, 0xffff0010($0) # set velocity zero
			  j		live
main_return:
			  li	$v0, 0
			  lw	$ra, 0($sp)
			  add	$sp, $sp, 8
			  jr	$ra

find_closest_block:
			  sub	$sp, $sp, 40
			  sw	$s7, 32($sp)
			  sw	$s6, 28($sp)
			  sw	$s5, 24($sp)
			  sw	$s4, 20($sp)
			  sw	$s3, 16($sp)
			  sw	$s2, 12($sp)
			  sw	$s1, 8($sp)
			  sw	$s0, 4($sp)
			  sw	$ra, 0($sp)
			  li	$s0, 0			# uint i = 0
			  li	$s1, 700		# uint target_x = 700 chosen to always be further away than any block
			  li	$s2, 700		# uint target_y = 700
			  li	$s7, 980000		# distance(0, 0, 700, 700)
			  jal	find_bot_coordinates
			  move	$s3, $v0		# bot_x
			  move	$s4, $v1		# bot_y
find_closest_block_loop:
			  sub	$t0, $s0, 11
			  beqz	$t0, find_closest_block_return # i == 11
			  move	$a0, $s0
			  jal	find_box_coordinates
			  move	$s5, $v0		# box_x
			  move	$s6, $v1		# box_y
			  move	$a0, $s5
			  jal	is_in_goal
			  bnez	$v0, find_closest_block_loop_end # is_in_goal(i)
			  move	$a0, $s5		# box_x
			  move	$a1, $s6		# box_y
			  move	$a2, $s3		# bot_x
			  move	$a3, $s4		# bot_y
			  jal	distance
			  sub	$t0, $v0, $s7
			  bgez	$t0, find_closest_block_loop_end # min_dist <= distance(bot_x, bot_y, box_x, box_y)
			  move	$s7, $v0		# save the new min_dist
			  move	$s1, $s5		# save the new target_x
			  move	$s2, $s6		# save the new target_y
find_closest_block_loop_end:
			  add	$s0, $s0, 1
			  j		find_closest_block_loop
find_closest_block_return:
			  move	$v0, $s1
			  move	$v1, $s2
			  lw	$s7, 32($sp)
			  lw	$s6, 28($sp)
			  lw	$s5, 24($sp)
			  lw	$s4, 20($sp)
			  lw	$s3, 16($sp)
			  lw	$s2, 12($sp)
			  lw	$s1, 8($sp)
			  lw	$s0, 4($sp)
			  lw	$ra, 0($sp)
			  jr	$ra

#
# XXX Fix to not require pushing to far edge
#
is_in_goal:
			  li	$v0, 0			# initialize to false
			  bnez	$a0, is_in_goal_false # x_coord != 0
			  li	$v0, 1			# set to true
is_in_goal_false:
			  jr	$ra

move_block_to_goal:
			  sub	$sp, $sp, 24
			  sw	$s3, 16($sp)
			  sw	$s2, 12($sp)
			  sw	$s1, 8($sp)
			  sw	$s0, 4($sp)
			  sw	$ra, 0($sp)
			  move	$s0, $a0		# box_x
			  move	$s1, $a1		# box_y
			  jal	find_bot_coordinates
			  move	$s2, $v0		# bot_x
			  move	$s3, $v1		# bot_y
			  move	$a0, $s0
			  move	$a1, $s1
			  move	$a2, $s2
			  move	$a3, $s3
			  jal	distance
			  sub	$t0, $v0, 1
			  beqz	$t0, move_block_to_goal_close # distance(bot_x, bot_y, box_x, box_y) == 1
			  # calculate the angle and set
			  move	$a0, $s2
			  move	$a1, $s3
			  move	$a2, $s0
			  move	$a3, $s1
			  jal	approximate_angle # approximate_angle(bot, box)
			  sw	$v0, 0xffff0080($0) # debug
			  sw	$v0, 0xffff0014($0)	# write the angle
			  li	$t0, 1
			  sw	$t0, 0xffff0018($0)
			  j		move_block_to_goal_return
move_block_to_goal_close:
			  # debug
			  sw $s0, 0xffff0080($0)
			  sw $s1, 0xffff0080($0)
			  #
			  # check where we are relative to block and goal, move to fix position
			  #
move_block_to_goal_return:
			  li	$t0, 10
			  sw	$t0, 0xffff0010($0)	# set velocity 10 (to ensure we can start moving)
			  lw	$s3, 16($sp)
			  lw	$s2, 12($sp)
			  lw	$s1, 8($sp)
			  lw	$s0, 4($sp)
			  lw	$ra, 0($sp)
			  add	$sp, $sp, 24
			  jr	$ra

find_bot_coordinates:
			  lw	$v0, 0xffff0020($0)
			  lw	$v1, 0xffff0024($0)
			  jr	$ra

find_box_coordinates:
			  sw	$a0, 0xffff0070($0)
			  lw	$v0, 0xffff0070($0)
			  lw	$v1, 0xffff0074($0)
			  jr	$ra

distance:
			  sub	$t0, $a0, $a2	# x_diff
			  sub	$t1, $a1, $a3	# y_diff
			  mul	$t0, $t0, $t0	# x_diff ^ 2
			  mul	$t1, $t1, $t1	# y_diff ^ 2
			  add	$v0, $t0, $t1
			  jr	$ra

# Approximate the absolute angle (a0, a1) must travel to reach (a2, a3)
approximate_angle:
			  sub	$sp, $sp, 8
			  sw	$ra, 0($sp)
			  move	$t0, $a0		# save a0 from clobbering
			  sub	$a0, $a3, $a1
			  sub	$a1, $a2, $t0
			  jal	atan2
			  sw	$v0, 0xffff0080($0) # debug
			  lw	$ra, 0($sp)
			  add	$sp, $sp, 8
			  jr	$ra

# Calculate the angle from the x axis
# Expected to be used as: atan2(box_y - bot_y, box_x - bot_x)
atan2:
			  li	$v0, 0
			  beqz	$a1, atan2_simple_cases
			  mul	$t0, $a1, 1428
			  mul	$t1, $a0, 300
			  div	$t2, $t1, $t0	# 300y / 1428x = index [0,63]
			  # when quantizing into 64 different sections (approx 5 degrees each)
			  # should produce accuracy to any square within radius 10.
			  shl	$t2, $t2, 2		# multiply by four for alignment
			  lw	$v0, atan($t2)
			  j		atan2_return
atan2_simple_cases:
			  blez $a0, atan2_simple_2
			  li $v0, 90
atan2_simple_2:
			  beqz $a0, atan2_return # undefined case
			  li $v0, -90
atan2_return:
			  jr $ra