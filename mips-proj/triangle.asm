#       32-bit MIPS program which renders a smooth shaded 
#       triangle at given coordinates and with given vertex colors.
# 		Author: Marcin Białek 

#       using fixed32 = int;    // fixed point number (Q16.16)
#
#       struct Vector {
#           fixed32 x;	        // 0
#           fixed32 y;	        // 4
#       };
#
#       struct Color {
#           fixed32 r;	        // 0
#           fixed32 g;	        // 4
#           fixed32 b;	        // 8
#       };
#
#       struct Vertex: public Vector, public Color {
#           // Vector 	        // 0
#           // Color 		// 8
#       };
#
#       struct Context  {
#           Vertex A;     	// 0 
#           Vertex B;     	// 20     
#           Vertex C;     	// 40
#           Vector AB;    	// 60
#           Vector AC;    	// 68
#           Vector BC;    	// 76
#           fixed32 area; 	// 84
#       };

        
    .eqv    SCREEN_BUFFER	0x10000000
	.eqv	SCREEN_WIDTH	128
	.eqv	SCREEN_HEIGHT	128


    .macro intToFixed16 %a 
		sll	%a, %a, 16
    .end_macro


    .macro fixed16ToInt %a 
		sra	%a, %a, 16
    .end_macro


    .macro mul16 %a %b %c 
        sw 	%b, -4($sp)
        mult 	%b, %c 
        mfhi 	%a 
        sll 	%a, %a, 16 
        mflo 	%b
        srl 	%b, %b, 16
        or 	%a, %a, %b
        lw	%b, -4($sp)
    .end_macro


	.data 
com:	.asciiz	", "
col:	.asciiz	": "
nl:     .asciiz "\n"
usageString:	
	.ascii  "Proper usage:\n"
	.ascii  "java -jar mars.jar main.asm pa V0x V0y V0r V0g V0b V1x V1y V1r V1g V1b V2x V2y V2r V2g V2b\n\n" 
	.ascii  "Parameters:\n"
	.ascii  "\tVnx\tx coordinate of vertex n (0 - 127)\n"
	.ascii  "\tVny\ty coordinate of vertex n (0 - 127)\n"
	.ascii  "\tVnr\tred component of the color for vertex n (0 - 255)\n"
	.ascii  "\tVng\tgreen component of the color for vertex n (0 - 255)\n"
	.ascii  "\tVnb\tblue component of the color for vertex n (0 - 255)\n"
	.ascii 	"\nAll \"not numbers\" are treated as 0.\n"
	.ascii 	"Numbers out of the ranges cause invalid coloring.\n"
	.asciiz ""


	.text
    .globl 	main
main:
    bne     $a0, 15, displayProperUsage

	subiu	$sp, $sp, 88
	move	$fp, $sp 
	
	move	$a0, $fp
	jal	readContext
	
	move	$a0, $fp
	jal	precompute
	
	move	$a0, $fp
	jal	render	
exit:
	li	$v0, 10
	syscall
displayProperUsage:
	li 	$v0, 4 
	la 	$a0, usageString 
	syscall
	j 	exit


# void calcVectorDifference(const Vector* A, const Vector* B, Vector* result) 
calcVectorDifference:
	lw 	$t0, ($a0)
	lw 	$t1, ($a1)
	sub 	$t1, $t1, $t0 
	sw 	$t1, ($a2)
	
	lw 	$t0, 4($a0)
	lw 	$t1, 4($a1)
	sub 	$t1, $t1, $t0 
	sw 	$t1, 4($a2)
	
	jr	$ra
	

# fixed32 calcTriangleArea(fixed32 Ax, fixed32 BCy, fixed32 Bx, fixed32 ACy, fixed32 Cx, fixed32 ABy) 
#		               $a0         $a1          $a2         $a3          $v0         $v1
calcTriangleArea:
	mul16	($t0, $a2, $a3)
	mul16	($t1, $a0, $a1)
	sub	$t0, $t0, $t1 
	mul16	($t1, $v0, $v1)
	sub	$t0, $t0, $t1 
	abs	$t0, $t0
	move	$v0, $t0 
	jr	$ra 
	
	
# void precompute(Context* context)
precompute:
	subiu	$sp, $sp, 12 
	sw 	$fp, ($sp)
	move	$fp, $sp
	sw	$ra, 4($fp)
	sw 	$s0, 8($fp)
	move 	$s0, $a0
	
	addiu	$a0, $s0, 0
	addiu	$a1, $s0, 20
	addiu	$a2, $s0, 60
	jal	calcVectorDifference

    addiu	$a0, $s0, 0
	addiu	$a1, $s0, 40
	addiu	$a2, $s0, 68
	jal	calcVectorDifference

    addiu	$a0, $s0, 20
	addiu	$a1, $s0, 40
	addiu	$a2, $s0, 76
	jal	calcVectorDifference

    lw	$a0, 0($s0)
	lw	$a1, 80($s0)
	lw	$a2, 20($s0)
	lw	$a3, 72($s0)
	lw	$v0, 40($s0)
	lw	$v1, 64($s0)
	jal	calcTriangleArea
	li	$t0, 0x7fffffff
	div	$v0, $t0, $v0
	sw	$v0, 84($s0)
	
	lw	$ra, 4($fp)
	lw 	$s0, 8($fp)
	lw 	$fp, ($fp)
	addiu	$sp, $sp, 8 
	jr	$ra
	
	
# void calcPixelColor(const Context* context, Vector* position, Color* pixel)
# Stack:
# 	0	$fp
#	4	$ra 
#	8	$s0	const Context* context
#	12	$s1	Vector* position
#	16	$s2	Color* pixel
#	20	Vector AP
# 	28	Vector BP
#	36	Vector CP
#	44	$s3	
#	48	$s4	
#	52	$s5	
#	56	$s6	context->area
calcPixelColor:
	subiu	$sp, $sp, 60
	sw 	$fp, ($sp)
	move	$fp, $sp
	sw	$ra, 4($fp)
	sw	$s0, 8($fp)
	sw	$s1, 12($fp)
	sw	$s2, 16($fp)
	sw	$s3, 44($fp)
	sw	$s4, 48($fp)
	sw	$s5, 52($fp)
	sw	$s6, 56($fp)
	move 	$s0, $a0 
	move 	$s1, $a1 
	move 	$s2, $a2 
	lw	$s6, 84($s0)	

	addiu	$a0, $s0, 0
	addiu	$a1, $s1, 0
	addiu	$a2, $fp, 20
	jal	calcVectorDifference

    addiu	$a0, $s0, 20
	addiu	$a1, $s1, 0
	addiu	$a2, $fp, 28
	jal	calcVectorDifference

    addiu	$a0, $s0, 40
	addiu	$a1, $s1, 0
	addiu	$a2, $fp, 36
	jal	calcVectorDifference

	lw	$t0, 60($s0)	# context->AB.x
	lw	$t1, 24($fp)	# AP.y
	mul16	($t2, $t0, $t1)

    lw	$t0, 64($s0)	# context->AB.y
	lw	$t1, 20($fp)	# AP.x
	mul16	($t3, $t0, $t1)
	
	sge	$t4, $t2, $t3

    lw	$t0, 68($s0)	# context->AC.x
	lw	$t1, 24($fp)	# AP.y
	mul16	($t2, $t0, $t1)
	
    lw	$t0, 72($s0)	# context->AC.y
	lw	$t1, 20($fp)	# AP.x
	mul16	($t3, $t0, $t1)
	
	sge	$t5, $t2, $t3 

    lw	$t0, 76($s0)	# context->BC.x
	lw	$t1, 32($fp)	# BP.y
	mul16	($t2, $t0, $t1)
	
    lw	$t0, 80($s0)	# context->BC.y
	lw	$t1, 28($fp)	# BP.x
	mul16	($t3, $t0, $t1)
	
	sge	$t6, $t2, $t3
	
    beq	$t4, $t5, .L0_pixel_outside_triangle
    bne	$t4, $t6, .L0_pixel_outside_triangle
    	
.L0_pixel_inside_triangle:	
	lw	$a0, 0($s0)	# context->A.x
	lw	$a1, 32($fp)	# BP.y
	lw	$a2, 20($s0)	# context->B.x
	lw	$a3, 24($fp)	# AP.y
	lw	$v0, 0($s1)	# position->x
	lw	$v1, 64($s0)	# context->AB.y
	jal	calcTriangleArea
	
	mul16	($s3, $v0, $s6)
	
	lw	$a0, 0($s0)	# context->A.x
	lw	$a1, 40($fp)	# CP.y
	lw	$a2, 40($s0)	# context->C.x
	lw	$a3, 24($fp)	# AP.y
	lw	$v0, 0($s1)	# position->x
	lw	$v1, 72($s0)	# context->AC.y
	jal	calcTriangleArea
	
	mul16	($s4, $v0, $s6)
	
	lw	$a0, 40($s0)	# context->C.x
	lw	$a1, 32($fp)	# BP.y
	lw	$a2, 20($s0)	# context->B.x
	lw	$a3, 40($fp)	# CP.y
	lw	$v0, 0($s1)	# position->x
	lw	$v1, 80($s0)	# context->BC.y
	neg	$v1, $v1
	jal	calcTriangleArea
	
	mul16	($s5, $v0, $s6)
	
	lw	$t0, 8($s0)	# context->A.r
	lw	$t1, 28($s0)	# context->B.r
	lw	$t2, 48($s0)	# context->C.r
	mul16	($t3, $s5, $t0)
	mul16	($t4, $s4, $t1)
	add	$t3, $t3, $t4
	mul16	($t4, $s3, $t2)
	add	$t3, $t3, $t4
	sw	$t3, 0($s2)	# pixel->r
	
	lw	$t0, 12($s0)	# context->A.g
	lw	$t1, 32($s0)	# context->B.g
	lw	$t2, 52($s0)	# context->C.g
	mul16	($t3, $s5, $t0)
	mul16	($t4, $s4, $t1)
	add	$t3, $t3, $t4
	mul16	($t4, $s3, $t2)
	add	$t3, $t3, $t4
	sw	$t3, 4($s2)	# pixel->g
	
	lw	$t0, 16($s0)	# context->A.b
	lw	$t1, 36($s0)	# context->B.b
	lw	$t2, 56($s0)	# context->C.b
	mul16	($t3, $s5, $t0)
	mul16	($t4, $s4, $t1)
	add	$t3, $t3, $t4
	mul16	($t4, $s3, $t2)
	add	$t3, $t3, $t4
	sw	$t3, 8($s2)	# pixel->b
	
	j	.L0_return
    	
.L0_pixel_outside_triangle:
	#     *pixel = { 0, 0, 0 };
	li	$t0, 0
	sw	$t0, 0($s2)
	sw	$t0, 4($s2)
	sw	$t0, 8($s2)
        
.L0_return:
	lw	$ra, 4($fp)
	lw	$s0, 8($fp)
	lw	$s1, 12($fp)
	lw	$s2, 16($fp)
	lw	$s3, 44($fp)
	lw	$s4, 48($fp)
	lw	$s5, 52($fp)
	lw	$s6, 56($fp)
	lw 	$fp, ($sp)
	addiu	$sp, $sp, 60
	jr	$ra
	
    	
# void render(const Context* context) 
# Stack:
#	0	$fp
#	4	$ra 
#	8	$s0	const Context* context
#	12	$s1	SCREEN_BUFFER
#	16	$s2	y
#	20	$s3	x
#	24	Vector position
#	32	Color pixel
render:
	subiu	$sp, $sp, 44
	sw	$fp, ($sp)
	move	$fp, $sp
	sw	$ra, 4($fp)
	sw	$s0, 8($fp)
	sw	$s1, 12($fp)
	sw	$s2, 16($fp)
	sw	$s3, 20($fp)
	move 	$s0, $a0
	
	li	$s1, SCREEN_BUFFER
	li	$s2, 0
.L1_loop_0:
	li 	$s3, 0
.L1_loop_1:
	sll	$t0, $s2, 16
	sw	$t0, 28($fp)
	sll	$t0, $s3, 16
	sw	$t0, 24($fp)
	
	move 	$a0, $s0 
	addiu	$a1, $fp, 24
	addiu	$a2, $fp, 32 
	jal 	calcPixelColor
	
	lw	$t0, 32($fp) 	# red 
	lw	$t1, 36($fp) 	# green 
	lw	$t2, 40($fp) 	# blue
	li	$t3, 0xff0000 	# 255
	mul16	($t4, $t0, $t3)
	mul16	($t5, $t1, $t3)
	mul16	($t6, $t2, $t3)
	fixed16ToInt($t4)
	fixed16ToInt($t5)
	fixed16ToInt($t6)
	
	sll	$t4, $t4, 16 
	sll	$t5, $t5, 8 
	or	$t6, $t6, $t4
	or	$t6, $t6, $t5
	sw 	$t6, ($s1)
	
	addiu	$s3, $s3, 1			
	addiu	$s1, $s1, 4
	blt	$s3, SCREEN_WIDTH, .L1_loop_1	
.L1_next:
	addiu 	$s2, $s2, 1 
	blt	$s2, SCREEN_HEIGHT, .L1_loop_0
	
.L1_return:
	lw	$ra, 4($fp)
	lw	$s0, 8($fp)
	lw	$s1, 12($fp)
	lw	$s2, 16($fp)
	lw	$s3, 20($fp)
	lw	$fp, ($sp)
	addiu	$sp, $sp, 44
	jr 	$ra	
	
	
# unsigned int stringToInt(const char* str)
stringToInt:
	li 	$v0, 0 
	lbu 	$t0, ($a0)
.L2_loop:
	bltu 	$t0, '0', .L2_not_string  
	bgtu 	$t0, '9', .L2_not_string  
	subiu 	$t0, $t0, '0'
	mulu 	$v0, $v0, 10
	addu 	$v0, $v0, $t0 
	addiu 	$a0, $a0, 1
	lbu 	$t0, ($a0)
	bnez 	$t0, .L2_loop
.L2_return:
	jr 	$ra
.L2_not_string:
	li 	$v0, 0
	jr 	$ra	
	
	
# void readVertex(Vertex* vertex, const char* argv[5]) 
readVertex:
	subiu	$sp, $sp, 16
	sw	$fp, ($sp)
	move	$fp, $sp 
	sw	$ra, 4($fp)
	sw	$s0, 8($fp)
	sw	$s1, 12($fp)
	move 	$s0, $a0 
	move 	$s1, $a1 
	
	lw	$a0, ($s1)
	jal	stringToInt
	intToFixed16($v0)
	sw	$v0, 0($s0)
	
	lw	$a0, 4($s1)
	jal	stringToInt
	intToFixed16($v0)
	sw	$v0, 4($s0)
	
	lw	$a0, 8($s1)
	jal	stringToInt
	intToFixed16($v0)
	srl	$v0, $v0, 7
	sw	$v0, 8($s0)
	
	lw	$a0, 12($s1)
	jal	stringToInt
	intToFixed16($v0)
	srl	$v0, $v0, 7
	sw	$v0, 12($s0)
	
	lw	$a0, 16($s1)
	jal	stringToInt
	intToFixed16($v0)
	srl	$v0, $v0, 7
	sw	$v0, 16($s0)
	
	lw	$ra, 4($fp)
	lw	$s0, 8($fp)
	lw	$s1, 12($fp)
	lw	$fp, ($sp)
	addiu	$sp, $sp, 16
	jr	$ra
	
	
# void readContext(Context* context, const char* argv[])
readContext:
	subiu	$sp, $sp, 16
	sw	$fp, ($sp)
	move	$fp, $sp 
	sw	$ra, 4($fp)
	sw	$s0, 8($fp)
	sw	$s1, 12($fp)
	move 	$s0, $a0 
	move 	$s1, $a1 
	
	addiu	$a0, $s0, 0 
	addiu	$a1, $s1, 0
	jal	readVertex
	
	addiu	$a0, $s0, 20 
	addiu	$a1, $s1, 20
	jal	readVertex
	
	addiu	$a0, $s0, 40 
	addiu	$a1, $s1, 40
	jal	readVertex
	
	lw	$ra, 4($fp)
	lw	$s0, 8($fp)
	lw	$s1, 12($fp)
	lw	$fp, ($sp)
	addiu	$sp, $sp, 16
	jr	$ra
	
	

