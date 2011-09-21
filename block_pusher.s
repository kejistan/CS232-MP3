## you get to write this one from scratch.
## we'll only be testing its behavior, not poking your code directly
.data
goal_side:	  .word	1				# 0 for left, 1 for right
pi:			  .float 3.14159265358979
pi_4:		  .float 0.78539816339745
const_1:	  .float 0.0663
const_2:	  .float 0.2447

.text
main:
			  sub	$sp, $sp, 8
			  sw	$ra, 0($sp)
			  jal	find_goal_side
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

find_goal_side:
			  lw	$t0, 0xffff0020($0)	# x coordinate
			  sub	$t1, $t0, 150	# board is 301 coordinates wide
			  bgez	$t1, find_goal_side_return # x >= 150
			  sw	$0, goal_side($0) # goal_side defaults to right
find_goal_side_return:
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
			  li	$s1, 700		# uint target_x = 700
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
			  lw	$t0, goal_side
			  li	$v0, 0			# initialize to false
			  beqz	$t0, is_in_goal_left # goal_side == LEFT
			  sub	$a0, $a0, 300
is_in_goal_left:
			  bnez	$a0, is_in_goal_false # x_coord == 300
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
			  jal	approximate_angle
			  sw	$v0, 0xffff0014($0)
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
			  sub	$a0, $a0, $a2
			  sub	$a1, $a1, $a3
			  jal	atan2
			  sw	$v0, 0xffff0080($0) # debug
approximate_angle_return:
			  lw	$ra, 0($sp)
			  add	$sp, $sp, 8
			  jr	$ra

# Calculate the angle from the x axis
# Expected to be used as: atan2(box_x - bot_x, box_y - bot_y)
atan2:
			  move	$v0, $a0
			  beqz	$a0, atan2_simple_cases
			  li	$v0, 0
			  bgtz	$a0, atan2_atan
			  bgez	$a1, atan2_non_negative
			  li	$v0, -360		# -360 to come out correctly after adding 180
atan2_non_negative:
			  add	$v0, 180
atan2_atan:
			  # approximate the arctan($a1 / $a0)
			  li	$t0, 1
			  mtc1	$t0, $f4
			  cvt.d.w $f4, $f4
			  mtc1	$a0, $f8		# relative_x
			  mtc1	$a1, $f12		# relative_y
			  div.d	$f0, $f12, $f8 # x = relative_x / relative_y
			  abs.d	$f8, $f0		# fp8 = |x|
			  sub.d $f4, $f8, $f4 # |x| - 1
			  mul.d $f4, $f4, $f0 # x(|x| - 1)
			  ldc1 $f12, const_1
			  mul.d	$f8, $f8, $f12 # 0.0663|x|
			  ldc1 $f12, const_2
			  add.d	$f8, $f8, $f12 # 0.2447 + 0.0663|x|
			  mul.d	$f4, $f4, $f8 # x(|x| - 1)(0.2447 + 0.0663|x|)
			  ldc1	$f12, pi_4
			  mul.d $f0, $f0, $f12 # pi / 4 * x
			  sub.d	$f0, $f0, $f4 # pi / 4 * x - x(|x| - 1)(0.2447 + 0.0663|x|)
			  # fp0 now holds the arctan in radians
			  li	$t0, 180
			  mtc1	$t0, $f4
			  cvt.d.w $f4, $f4
			  mul.d $f0, $f0, $f4
			  ldc1	$f4, pi
			  div.d	$f0, $f0, $f4
			  round.w.d	$f0, $f0	# arctan in radians, rounded to integer
			  mfc1	$t0, $f0
			  add	$v0, $v0, $t0
			  j		atan2_return
atan2_simple_cases:
			  blez $a1, atan2_simple_2
			  li $v0, 90
atan2_simple_2:
			  beqz $a1, atan2_return # undefined case
			  li $v0, -90
atan2_return:
			  jr $ra