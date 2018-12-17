.data 
	op:		.word		0	#操作码
	#对于两个操作数 第一个字存整数部分第二个字存小数部分
	num1:  	.word    	0     	#第一个操作数 0~31 如果是浮点数即为前两位为整数，后三位为小数部分范围在 00.000~11.111(0~3.875)	如果为浮点数就第一个字节存整数+小数，第二个字节存小数点后面的数
	num2:	.word 	0	#第二个操作数
	result:	.word	0	#结果 0~961（31*31）如果为浮点数即为  0~(123.453125) 由于数码管只能显示8位，所以整数部分固定显示3位，小数部分显示5位
	#最终结果存进s1，两个操作数存进s2，s3 ，减法默认大减小
.text
start:
	lui     $t1,0xffff					         
	ori     $s0,$t1,0xF000	#$s0端口是系统的I/O地址的高20位       0xfffff000
	sw     	$0,0xC60($s0)       #将Led 置零
	addi	$s1,$0,0
#开关读取操作码
swItOp:
    lw     	$t1,0xC70($s0)   	#读取拨码开关的数值 t1

	andi   	$t2,$t1,0xe000     	#获得拨码开关数值的（15~13） 表示操作码
	srl    	$t2,$t2,13  
    sw    	$t2,op($0)

	srl 	$t2,$t2,2       		#再移动两位得到最左边的一位  表示是否为浮点数运算
	addi  	$t3,$0,1
	beq 	$t2,$t3,floatInput	#如果t2 = 1 即最左边的开关为1，即为浮点数
#整数的读数过程
intInput:
	lw     $t1,0xC70($s0)   	#读取拨码开关的数值 t1
	
	andi   $t2,$t1,0x001f     	#获得拨码开关数值的低5位（0~4） 表示第一个操作数  5个开关   
    sw     $t2,num1($0) 


	andi   	$t2,$t1,0x07c0     	#获得拨码开关数值的（6~10） 表示第二个操作数	5个开关
	srl    	$t2,$t2,6  
     sw     $t2,num2($0)
	j		choseOP			#跳转到运算指令中
#浮点数的读数过程
floatInput:				#浮点输入和整数输入不太一样，我们需要将输入数的整数部分和小数部分分开
	lw     	$t1,0xC70($s0)   	#读取拨码开关的数值 t1
	andi 	$s7,$t1,0x8000		#！！用于存到led的最高位 表示是浮点运算！！
#-----------------------------------------------------------------------------------------------
	andi   	$t2,$t1,0x001f     	#获得拨码开关数值的低5位（4~0） 表示第一个操作数 
    sw     	$t2,num1($0)           	#num1 第一个字存整数+小数

	andi   	$t2,$t1,0x0018    	#获得拨码开关数值的2位（4~3） 表示第一个操作数的整数
	srl	 	$t2,$t2,3
	addi	$t3,$0,4
	sw     	$t2,num1($t3)        #整数部分存到num1中的第二个字

	andi   	$t2,$t1,0x0007     	#获得拨码开关数值的3位（2~0） 表示第一个操作数的小数部分
	addi	$t3,$0,8
	sw     	$t2,num1($t3)        #小数部分存到num1中的第三个字 
	
#---------------------------------------------------------------------------------------------------
	andi   $t2,$t1,0x07c0     	#获得拨码开关数值的(10~6) 表示第二个操作数	
	srl    $t2,$t2,6  
   	sw     $t2,num2($0)		#num2 第一个字存整数+小数


	andi	$t2,$t1,0x0600     	#获得拨码开关数值的（10~9） 表示第二个操作数的整数部分
	srl 	$t2,$t2,9 
	addi	$t3,$0,4		#整数部分存到num2中的第二个字
    sw     	$t2,num2($t3)

	andi   	$t2,$t1,0x01c0     	#获得拨码开关数值的（8~6） 表示第二个操作数的小数部分
	srl    	$t2,$t2,6
	addi	$t3,$0,8		#小数部分存到num2中的第三个字
    sw 		$t2,num2($t3)
#----------------------------------------------------------------------------------------------------
	j	choseOP
choseOP:
	lw		$t1,op($0) 		#取出操作码
	
	beq   	$t1,$0,intAdd 		#整数加法

	addi	$t2,$0,1
	beq   	$t1,$t2,intSub		#整数减法
	
	addi	$t2,$0,2
	beq    	$t1,$t2,intMul		#整数乘法

	addi	$t2,$0,3
	beq    	$t1,$t2,intSub		#整数除法

	addi	$t2,$0,4
	beq    	$t1,$t2,floatAdd		#浮点数加法

	addi	$t2,$0,5
	beq    	$t1,$t2,floatSub		#浮点数减法

	addi	$t2,$0,6
	beq    	$t1,$t2,floatMul		#浮点数乘法

	addi	$t2,$0,7
	beq  	$t1,$t2,floatDiv		#浮点数除法
##############################################################################################################################

intAdd:			#整数加法
	sw		$s1,result($0)
intSub:			#整数减法
	sw		$s1,result($0)
intMul:			#整数乘法
	sw		$s1,result($0)
intDiv:			#整数除法
	sw		$s1,result($0)
##############################################################################################################################
floatAdd:			#浮点数加法
	#led 需要用到10位，4位整数部分，6位小数部分
	#0x03c0为整数部分 ， 0x003f为小数部分
	addi	$t1,$0,0	
	lw		$t2,num1($t1)	#t2存num1的整数+小数部分
	lw		$t3,num2($t1)	#t3存num2的整数小数部分
	add		$s2, $t2,$t3	# $s2 =$t2+ $t3  比如 01010 + 00101 = 01111 表示 01.010 + 00.101 = 01.111


	sll		$s2,$s2,3	#左移三位 把整数和小数放到对应的位置上  整数0000  小数000000

	add    $s1, $s2,$0		#s1用于储存最后的答案0001 110000 表示1.11
	j		floatResultSave		# jump to floatResultSave
########################################################################################################################################
floatSub:			#浮点数减法
	lw	 	$t1, num1($0)		# 取出第一个数
	lw	 	$t2, num2($0)		# 取出第二个数
	slt     $t3, $t1, $t2		# 如果第一个数比第二个数小
	addi 	$t4,$0,1	
	beq		$t3,$4,sub2s1  	#如果第一个数比第二个数小就进入第二个数减第一个数
	j		sub1s2
sub1s2:
	lw		$t2,num1($0)	#t2存num1的整数+小数部分
	lw		$t3,num2($0)	#t3存num2的整数小数部分
	sub		$s1, $t2, $t3		#num1 - num2
	sll		$s1,$s1,3
	j		floatResultSave		# jump to floatResultSave
sub2s1:
	lw		$t2,num2($0)	#t2存num2的整数+小数部分
	lw		$t3,num1($0)	#t3存num1的整数小数部分
	sub		$s1, $t2, $t3		#num2 - num1
	sll		$s1,$s1,3
	j		floatResultSave		# jump to floatResultSave
#######################################################################################################################################
floatMul:			#浮点数乘法 通过找出两个数的小数位数，x位小数乘y位小数 结果应为x+y位小数（x+y < 6）然后左移6-(x+y)位
	addi	$t1,$0,0
	
	lw	 	$s2, num1($t1)		# 取出第一个数的整体
	lw	 	$s3, num2($t1)		# 取出第二个数的整体

	beq 	$s3,$0,num2is0		#第二个乘数是0的情况下，结果直接为0， 由于思路是 x个y x为第二个数，如果第二个数为0，在逻辑中先减1，就变为-1会出错

	addi	$t1,$0,8
	lw	 	$s4, num1($t1)		# 取出第一个数的小数部分 
	lw	 	$s5, num2($t1)		# 取出第二个数的小数部

	j		loop_decimalNumber1

decimalNumber1:			#找出num1后小数点有几位
	addi 	$t1,$0,0x1			#小数点后第三位
	andi	$t4,$s4,$t1			#判断小数部分第三位有没有1 如果有就代表小数有3位
	addi	$t5,$0,1
	beq		$t5,$t4,num1have3	#如果t4=1

	addi 	$t1,$0,0x2			#小数点后第二位
	andi	$t4,$s4,$t1			#判断小数部分第二位有没有1 如果有就代表小数有2位
	addi	$t5,$0,2
	beq		$t5,$t4,num1have2	#如果t4=1

	addi 	$t1,$0,0x4			#小数点后第一位
	andi	$t4,$s4,$t1			#判断小数部分第一位有没有1 如果有就代表小数有1位
	addi	$t5,$0,4
	beq		$t5,$t4,num1have1	#如果t4=1

num1have3:
	addi    $s4, $0,3
	j		decimalNumber2
num1have2:
	addi    $s4, $0,2
	j		decimalNumber2
num1have1:
	addi    $s4, $0,1
	j		decimalNumber2

decimalNumber2:			#找出num1后小数点有几位
	addi 	$t1,$0,0x1			#小数点后第三位
	andi	$t4,$s5,$t1			#判断小数部分第三位有没有1 如果有就代表小数有3位
	addi	$t5,$0,1
	beq		$t5,$t4,num2have3	#如果t4=1

	addi 	$t1,$0,0x2			#小数点后第二位
	andi	$t4,$s5,$t1			#判断小数部分第二位有没有1 如果有就代表小数有2位
	addi	$t5,$0,1
	beq		$t5,$t4,num2have2	#如果t4=1

	addi 	$t1,$0,0x4			#小数点后第一位
	andi	$t4,$s5,$t1			#判断小数部分第一位有没有1 如果有就代表小数有1位
	addi	$t5,$0,1
	beq		$t5,$t4,num2have1	#如果t4=1

num2have3:
	addi    $s5, $0,3
	j		fMulfunction
num2have2:
	addi    $s5, $0,2
	j		fMulfunction
num2have1:
	addi    $s5, $0,1
	j		fMulfunction

fMulfunction:	#经过上面的处理，s4中存的num1的小数点后位数 s5中存的num2小数点后位数
#3*5 就是 3+3+3+3+3
	add		$s1,$s1,$s2			#s1 = s1 + s2 s2为第一个数的整体
	addi	$s3,$s3,-1
	bne     $s3,$0,fMulfunction #s3个s2相加 只到s3 == 0就退出循环

	add		$t1,$s4,$s5		#t1 储存的乘法结果的小数点后的总位数
	addi	$t2,$0, 6		
	sub     $t1, $t2, $t1	#t1  =  6 - t1 即左移的位数

	sllv    $s1, $s1, $t1	#s1 左移t1 位
	j		floatResultSave	# jump to floatResultSave
	
num2is0:
	addi	$s1,$0,$0		#结果直接为0
	j		floatResultSave	# jump to floatResultSave
###############################################################################################################################################
floatDiv:			#浮点数除法
	sw		$s1,result($0)
######################################################################################################################
resultSave:		#储存结果到Led里面
	or		$t1,$s1,$s7 	#把结果和 表示浮点运算的flag 放到一起，用于传参数判断是否为浮点运算
	sw		$t1,0xC60($s0)  
	j 		start			#传递完后重新开始
floatResultSave:
	or		$t1,$s1,$s7 	#把结果和 表示浮点运算的flag 放到一起，用于传参数是否为浮点运算
	sw		$t1,0xC60($s0)  
	j 		start			#传递完后重新开始