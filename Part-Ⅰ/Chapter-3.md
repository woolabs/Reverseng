# 第三章
# Hello,world!

让我们用《C语言程序设计》中最著名的例子开始吧[Ker88]：

```
#include <stdio.h>

int main() 
{
	printf("hello, world\n");
    return 0;
}
```

## 3.1 x86

### 3.1.1 MSVC

让我们在MSVC 2010中编译一下：

`cl 1.cpp /Fa1.asm`
 
（/Fa 选项表示让编译器生产汇编列表文件）
代码清单 3.1: MSVC 2010

```
CONST   SEGMENT
$SG3830 DB     'hello, world', 00H
CONST   ENDS
PUBLIC  _main
EXTRN   _printf:PROC
; Function compile flags: /Odtp
_TEXT   SEGMENT
_main   PROC
    	push 	ebp
    	mov 	ebp, esp
    	push 	OFFSET $SG3830
    	call 	_printf
    	add 	esp, 4
    	xor 	eax, eax
    	pop 	ebp
    	ret 	0
_main   ENDP
_TEXT   ENDS
```

MSVC生成的汇编代码用的是Intel的汇编语法。Intel语法与AT&T语法的区别将会在3.1.3讨论。

编译器会生成连接到`1.exe`的`1.obj`文件。在我们的例子当中，该文件包含两个部分：`CONST`（放数据常量）和`_TEXT`（放代码）。

字符串`"hello, world"`在C/C++的类型为`const char[]`[Str13, 7.3.2],，然而它没有自己的变量名。编译器需要处理这个字符串，于是就自己给他定义了一个内部名称`$SG3830`。

所以我们的例子可以重写为下面这样：

```
#include <stdio.h>

const char $SG3830[]="hello, world\n";

int main() 
{
    printf($SG3830);
    return 0;
}
```

让我们回到汇编代码，正如我们看到的，字符串是由0字节结束的，这是标准的C/C++字符串。关于C/C++字符串见：57.1.1

在代码部分，`_TEXT`，那儿只有一个函数：main()。main()函数与大多数函数一样都由起始代码开始，由收尾代码结束。

函数当中的起始代码结束以后，我们看见了对printf()函数的调用：`CALL _printf`。在调用之前，保存我们问候语字符串的地址（或指向它的指针），已经在PUSH指令的帮助下，被存放在栈中。

当printf()函数执行完返回到main()函数的时候，字符串地址(或指向它的指针)仍然在堆栈中。当我们完全不需要它的时候，堆栈指针（ESP寄存器）需要被复原。

`ADD ESP, 4`意思是ESP寄存器的值加4。

为什么是4呢？因为这是32位的程序，通过栈传送地址刚好需要4个字节。如果是64位的代码则需要8字节。`ADD ESP, 4`在效率上等同于`POP register`，但是后者不需要使用任何寄存器。

一些编辑器（如Intel C++编译器）在同样的情况下可能会用`POP ECX`代替ADD（这样的模式可以在Oracle RDBMS代码中看到，因为它是由Intel C++编译器编译的），这两条指令的效果基本相同，但是ECX的寄存器内容会被改写。Intel C++编译器可能用`POP ECX`，因为这条指令比`ADD ESP, X`更短，（`POP`——1字节对应`ADD`——3字节）。

这里有一个在Oracle RDBMS中用`POP`而不用`ADD`的例子。
清单 3.2: Oracle RDBMS 10.2 Linux (app.o 文件)
```
.text:0800029A 		push 	ebx
.text:0800029B 		call 	qksfroChild
.text:080002A0 		pop 	ecx
```

在调用printf()之后，原来的C/C++代码执行`return 0`，返回0当做main()函数的返回结果。在生成的代码中，这被编译成指令`XOR EAX, EAX`。

XOR事实上就是异或，但是编译器经常用它来代替`MOV EAX, 0`原因就是它需要的字节更短（`XOR`需要2字节对应`MOV`需要5字节）。

有些编译器则用`SUB EAX, EAX` 就是EXA的值减去EAX，也就是返回0。

最后的`RET`指令返回控制权给调用者。通常这是C/C++的库函数代码，它会按顺序，把控制权返还给操作系统。

### 3.1.2 GCC

现在我们尝试在linux中用GCC 4.4.1编译同样的C/C++代码

`gcc 1.c -o 1`

下一步，在IDA反汇编的帮助下，我们看看main()函数是如何被创建的。IDA与MSVC一样，也是使用Intel语法。

代码清单 3.3:IDA里的代码

```
main proc near
var_10          = dword ptr -10h
    push ebp
    mov  ebp, esp
    and  esp, 0FFFFFFF0h
    sub  esp, 10h
    mov  eax, offset aHelloWorld ;` `"hello, world"
    mov [esp+10h+var_10], eax
    call _printf
    mov eax, 0
    leave
    retn
main            endp
```

结果几乎是相同的，`"hello,world"`字符串地址（保存在data段的）一开始保存在EAX寄存器当中，然后保存到栈当中。

此外在函数开始我们看到了`AND ESP, 0FFFFFFF0h`，这条指令将ESP寄存器中的值对齐为16字节。这让堆栈中的所有值，都以相同的方式对齐。(如果分配的内存地址大小被对齐为4或16字节，CPU的性能会更好。)

`SUB ESP，10H`在栈上分配16个字节。 虽然在下面我们可以看到，这里其实只需要4个字节。

这是因为分配的堆栈的大小也被对齐为16位。

该字符串的地址（或这个字符串指针）直接存入到堆栈空间，而不使用PUSH指令。`var_10`，是一个局部变量，也是`printf()`的参数。

然后`printf()`函数被调用。

不像MSVC，当gcc编译不开启优化时，它使用`MOV EAX，0`清空EAX，而不用更短的指令。

最后一条指令，`LEAVE`相当于`MOV ESP，EBP`和`POP EBP`两条指令。换句话说，这相当于将堆栈指针（ESP）恢复，并将EBP寄存器复原到其初始状态。

这是很有必要的，因为我们在函数的开头修改了这些寄存器的值（ESP和EBP）（执行`MOV EBP，ESP`/`AND ESP, ...`）。

### 3.1.3 GCC:AT&T 语法

我们来看一看在AT&T当中的汇编语法，这个语法在UNIX类系统当中更普遍。
代码清单 3.4: 让我们用 GCC 4.7.3 编译
`gcc -S 1_1.c`

我们将得到这个：

代码清单 3.5: GCC 4.7.3
```
    	.file   "1_1.c"
    	.section    .rodata
.LC0:
    	.string "hello, world"
    	.text
    	.globl  main
    	.type   main, @function
main:
.LFB0:
    	.cfi_startproc
    	pushl 	%ebp
    	.cfi_def_cfa_offset 8
    	.cfi_offset 5, -8
    	movl 	%esp, %ebp
    	.cfi_def_cfa_register 5
    	andl 	$-16, %esp
    	subl 	$16, %esp
    	movl 	$.LC0, (%esp)
    	call 	printf
    	movl 	$0, %eax
    	leave
    	.cfi_restore 5
    	.cfi_def_cfa 4, 4
    	ret
    	.cfi_endproc
.LFE0:
    	.size   main, .-main
    	.ident  "GCC: (Ubuntu/Linaro 4.7.3-1ubuntu1) 4.7.3"
    	.section        .note.GNU-stack, "", @progbits
```

这段代码包含了很多的宏（以点开始）。目前我们不关心这个。

现在为了简单起见，我们先不看这些。（除了 .string ，就像C-string一样，用于编码一个以null结尾的字符序列）。然后，我们将看到这个：

代码清单 3.6: GCC 4.7.3
```
.LC0:
    .string "hello, world"
main:
    pushl   %ebp
    movl %esp, %ebp
    andl $-16, %esp
    subl $16, %esp
    movl $.LC0, (%esp)
    call printf
    movl $0, %eax
    leave
    ret
```

在Intel与AT&T语法当中一些主要的区别就是：

* 操作数写在后面  
	在Intel语法中：\<instruction> \<destination operand> \<source operand>  
	在AT&T语法中：\<instruction> \<source operand> \<destination operand>  
	有一个简单的记住它们的方法: 当你面对intel语法的时候，你可以想象把等号(=)放到2个操作数中间，当面对AT&T语法的时候，你可以放一个右箭头(→）到两个操作数之间。  
* AT&T: 在寄存器名之前需要写一个百分号(%)并且在数字前面需要加上美元符($)。并用圆括号替代方括号。 
* AT&T: 以下是一些添加到操作符后，用来表示数据形式的后缀：  
	– q — quad (64 bits)  
	– l — long (32 bits)  
	– w — word (16 bits)  
	– b — byte (8 bits)  

让我们回到上面的编译结果：它和在IDA里看到的是一样的。只有一点不同：`0FFFFFFF0h` 被写成了`$-16`。但这是其实是一样的，10进制的16在16进制里表示为0x10。-0x10就等同于0xFFFFFFF0(针对于32位的数据类型)。

另外：返回值通常用`MOV`置0，而不用`XOR`。MOV仅仅加载（load）了一个值到寄存器。这条指令的名称是个误称(数据没有被移动，而是被复制了)。在其他的构架上，这条指令会被称作“LOAD” 、 “STORE”或其他类似的名称。

## 3.2 x86-64

### 3.2.1 MSVC-x86-64

让我们来试试64-bit的MSVC：
代码清单 3.7: MSVC 2012 x64

```
$SG2989 DB      'hello, world', 00H
main    PROC
    sub    rsp, 40
    lea    rcx, OFFSET FLAT:$SG2923
    call   printf
    xor    eax, eax
    add    rsp, 40
    ret    0
main ENDP
```

在x86-64里，所有的寄存器都被扩展到64位，并且名字前都带有R-前缀。这是为了减少栈的使用(即减少对外部内存/缓存的访问)，通常的做法是：用寄存器来传递参数（类似于fastcall）。也就是，一部分参数通过寄存器传递，其余的通过栈传递。

在win64里，`RCX,RDX,R8,R9`寄存器被用来传递函数的4个参数，在这里我们可以看到指向给printf()函数的字符串的指针，没有用通过栈，而是用了`RCX`来传递。这些指针现在是64位的，所以他们通过64位寄存器来传递(带有R-前缀)，并且为了向后兼容，依旧可以使用E-前缀，来访问32位的部分。

如下图所示，这是`RAX/EAX/AX/AL`在x86-64构架里的情况 ￼![](pic/C3-1.jpg)

main()函数会返回一个int类型的值，在C/C++里为了兼容和移植性，依旧是32位的。这就是问什么，是`EAX`而不是`RAX`（即寄存器的低32位部分）在函数最后会被清0。

在寄存器里也有40字节被分配给了局部堆栈。这被称为“影子空间”。这一点我们之后会提及：8.2.1 。

### 3.2.2 GCC-x86-64

这次在64位的Linux里试试GCC：

代码清单 3.8: GCC 4.4.6 x64

```
    .string "hello, world"
main:
    sub    rsp, 8
    mov    edi, OFFSET FLAT:.LC0 ; "hello, world"
    xor    eax, eax  ; number of vector registers passed
    call   printf
    xor    eax, eax
    add    rsp, 8
    ret
```

在Linux,\*BSD和Mac OS X里也使用同一种方式来传递函数参数。

前6个参数使用`RDI,RSI,RDX,RCX,R8,R9`来传递的，剩下的用栈。

所以在这个程序里，字符串指针被放到`EDI`（RDI的低32位部分）。但是为什么不用RDI的64位部分呢？

记住这一点很重要：`MOV`指令在64位模式下，对低32位进行写入操作的时候，会清空高32位的内容[Int13]。比如 `MOV EAX，011223344h`将会把值写到RAX里，并且清空RAX的高32位区域。 

如果我们打开编译好的对象文件(object file[.o]),我们会看到所有的指令的操作符：

代码清单 3.9: GCC 4.4.6 x64

```
.text:00000000004004D0                     	main proc near
.text:00000000004004D0 48 83 EC 08          sub 	rsp, 8
.text:00000000004004D4 BF E8 05 40 00       mov 	edi, offset format ;"hello, world"
.text:00000000004004D9 31 C0                xor 	eax, eax
.text:00000000004004DB E8 D8 FE FF FF       call 	_printf
.text:00000000004004E0 31 C0                xor 	eax, eax
.text:00000000004004E2 48 83 C4 08          add 	rsp, 8
.text:00000000004004E6 C3                   retn
.text:00000000004004E6                     	main endp
```

就像看到的那样，在`0x4004D4`那行写入`EDI`花了5个字节。如果把这句换成给`EDI`写入64位的值，会花掉7个字节。显然，GCC在试图节省空间，除此之外，数据段(data segment)中包含的字串不会分配到高于4GiB的地址。

可以看到在调用printf()函数前，`EAX`被清空了，这是因为在x86-64的 `*NIX` 系统上， 使用过的向量寄存器的数量会被存入`EAX` [Mit13]。

## 3.3 关于GCC 额外的一点

(3.1.1)，并且匿名的C字符串带有常量的类型C字符串在常量段被分配的地址是一定不变的。基于这样的事实，就有一个有趣的结论：编译器可能只用了字符串的某一部分。

让我们看看这个例子：

```
#include <stdio.h>

int f1()
{
	printf ("world\n");
}
int f2()
{
	printf ("hello world\n");
}
int main()
{
	f1();
	f2();
}
```
一般的C/C++编译器(包括MSVC)会分别分配给地址两个字符串，但是让我们看看GCC干了什么：
代码清单 3.10: GCC 4.8.1 + IDA listing
```
f1 		proc near

s 		= dword ptr -1Ch
		sub 	esp, 1Ch
		mov 	[esp+1Ch+s], offset s ; "world\n"
		call 	_puts
		add 	esp, 1Ch
		retn
f1 		endp

f2 		proc near

s 		= dword ptr -1Ch

		sub 	esp, 1Ch
		mov 	[esp+1Ch+s], offset aHello ; "hello "
		call	_puts
		add 	esp, 1Ch
		retn
f2 		endp

aHello 	db 'hello '
s 		db 'world',0xa,0
```
实际上，当我们打印"hello world"字符串时，这两个单词被放在内存里相邻的位置。函数f2()中调用的`puts()`并不知道字符串已经被分开了。事实上字符串并没有被真正分开，只是在代码里被假装分开了。

当`puts()`被f1()调用时，他使用“world”字符串加上一个0，`puts()`并不清楚字符串之后还有什么。

这个聪明的小技巧至少在GCC里被经常使用，他能够节省一些内存。

## 3.4 ARM

作者根据自身对ARM处理器的经验，选择了几款流行的编译器：
* 嵌入式领域很流行的：Keil Release 6/2013
* 苹果的Xcode 4.6.3 IDE(其中使用了LLVM-GCC4.2编译器)
* GCC 4.9 (Linaro) (for ARM64) [可用的32位.exe](http://go.yurichev.com/17325)

32位ARM的代码(包括Thumb 和 Thumb-2模式)被用在这本书的所有例子里，如果未做其他提示，我们谈论64位ARM时会叫它ARM64.

### 3.3.1 未进行代码优化的Keil 6/2013 编译：ARM模式

让我们在Keil里编译我们的例子

`armcc.exe –arm –c90 –O0 1.c`

armcc编译器可以生成intel语法的汇编程序列表，但是里面有高级的ARM处理器相关的宏，对我们来讲更希望看到“指令原来的样子”，所以让我们看看IDA反汇编之后的结果。

代码清单 3.11: 无优化的 Keil 6/2013 (ARM 模式) IDA

```
.text:00000000                  main
.text:00000000 10 40 2D E9			STMFD 	SP!, {R4,LR}
.text:00000004 1E 0E 8F E2          ADR 	R0, aHelloWorld ; "hello, world"
.text:00000008 15 19 00 EB          BL 		__2printf
.text:0000000C 00 00 A0 E3          MOV 	R0, #0
.text:00000010 10 80 BD E8          LDMFD 	SP!, {R4,PC}

.text:000001EC 68 65 6C 6C +aHelloWorld  DCB "hello, world",0 ; DATA XREF: main+4
```

在例子中，我们可以发现所有指令都是4字节的，因为我们编译的时候选择了ARM模式，而不是Thumb模式。

最开始的指令是`STMFD SP!, {R4, LR}`，这条指令类似x86平台的`PUSH`指令，它会把2个寄存器（R4和LR）的值写到栈里。不过为了简化，在`armcc`编译器输出的汇编代码里会写成`PUSH {R4, LR}`，但这并不准确，因为`PUSH`命令只在Thumb模式下可用，所以为了减少混乱，我们用IDA来做反汇编工具。

这指令首先会减少`SP`的值，这样它在栈中指向的空间就被释放，以留给新条目使用，然后将R4和LR的值存入被修改后的`SP`的储存区域中。

这条指令（类似于Thumb模式的PUSH）允许一次压入好几个寄存器的值，非常实用。顺带说一下，在x86里面它没有等价的指令。还有一点值得注意的是：`STMFD`指令是广义的`PUSH`指令(扩展了它的功能)，因为他能操作任何寄存器，不只是`SP`。换句话说，`STMFD`可以用于将一组寄存器储存在特定的内存地址上。

`ADR R0, aHelloWorld`这条指令将`"hello, world"`字串的地址偏移加上或减去PC寄存器的值。有人会问，`PC`寄存器在这里有什么用呢？这被称作浮动地址码（position-independet code），这样的代码可以在内存中非固定的地址上运行。换句话说，这是和`PC`寄存器相关的寻址。ADR这条指令，考虑了指令的地址和字符串真正所在的地址的差异。无论操作系统把我们的代码加载到哪里，这个差值(偏移)总是相同的。这也是为什么，我们每次都要加上当前的指令地址(从`PC`里)，以获取内存中字串的绝对地址。

`BL __2print`这条指令用于调用printf()函数，以下是这条指令是如何工作的：

* 将BL指令（0xC）后面的地址写入LR寄存器；
* 然后把printf()函数的入口地址写入PC寄存器，将控制权交给printf()函数。

当printf()函数执行完之后，它必须知道该把控制权返回谁。这就是为什么，每个函数都会把控制权交给`LR`寄存器中的地址。

函数返回地址的存放位置，也正是“纯”-RISC处理器（例如ARM）和CISC处理器(例如x86)的区别。

另外，一个32位地址或者偏移量不能被编码到32位BL指令里，因为BL指令只有24位的空间。我们应该还记得，所有的ARM模式下的指令都是4字节的（32位）。因此，指令占用了4位的地址。这也就意味着最后2bits(这里总会被设置成0)被忽略了，总的来说，我们有26位可用于偏移编码。这足够去访问大约`当前_PC`±32M的地址。

下面我们来看`MOV R0， #0`这条语句，这条语句就是把0写入R0寄存器。这是因为C函数返回了0，返回值会放在R0里。

最后一条指令是`LDMFD SP!, R4,PC`，这是STMFD的逆指令。为了将初始值存入`R4`和`PC`寄存器里，这条指令会从栈上(或任何其他的内存区域)读取保存的值，并且增加堆栈指针`SP`的值。这非常类似x86平台里的`POP`指令。

最前面那条`STMFD`指令，将`R4`，和`LR`寄存器成对保存到栈中。在`LDMFD`执行的时候，`R4`和`PC`会被复原。

我们已经知道，函数的返回地址会保存到`LD`寄存器里。第一条指令会把他先保存到栈里，这是因为main()调用printf()函数时，会使用LD寄存器。在函数的最后，这个值会被直接写入`PC`寄存器，完成函数的返回操作。

因为在C/C++里`main()`一般是主函数，控制权会返回给系统加载器或者CRT里面的指针或其他类似的东西。

所有的这些都允许在函数的结尾忽略`BX LR`指令。

汇编代码里的`DCB`关键字用来定义ASCII字串数组，就像x86汇编里的`DB`关键字。

### 3.4.2未进行代码优化的Keil 6/2013 编译： (Thumb模式)

让我们用下面的指令，将相同的例子用Keil的Thumb模式来编译一下。

`armcc.exe –thumb –c90 –O0 1.c`

我们可以在IDA里得到下面这样的代码： 
代码清单 3.12: Non-optimizing Keil 6/2013 (Thumb mode) + IDA

```
.text:00000000            main
.text:00000000 10 B5          PUSH 		{R4,LR}
.text:00000002 C0 A0          ADR		R0, aHelloWorld ; "hello, world"
.text:00000004 06 F0 2E F9    BL 		__2printf
.text:00000008 00 20          MOVS		R0, #0
.text:0000000A 10 BD          POP 		{R4,PC}
.text:00000304 68 65 6C 6C +aHelloWorld  DCB "hello, world",0 ; DATA XREF: main+2
```

我们首先就能注意到指令都是2字节(16位)的了，这正是Thumb模式的特征。

但BL指令是2由个16位的指令来构成的。因为不可能只用16位操作符里的小空间，去加载printf()的偏移量。因此，第一个16位指令，用来加载函数偏移的高10位，第二个指令加载函数偏移的低11位。正如我说过的，所有的Thumb模式下的指令都是2字节(16位)的。这就意味着一个Thumb指令，无论如何不可能在奇数位的地址上。基于以上因素，地址的最后一位将会在编码指令时省略。总的来讲，`BL`在Thumb模式下可以访问`当前_PC`±2M的地址。

至于在这个函数中的其他指令:`PUSH`和`POP`，它们跟上面讲到的`STMFD/LDMFD`很类似，但这里不需要指定`SP`寄存器，`ADR`指令也跟上面的工作方式相同。`MOVS`指令将函数的返回值0写到了`R0`寄存器里，让函数返回0。

### 3.4.3 开启代码优化的Xcode（LLVM）(ARM模式)

Xcode 4.6.3不开启代码优化的情况下，会产生非常多冗余的代码，所以我们学习一个优化过的版本。这个版本所用的指令的数量会尽可能的少。

开启`-O3`编译选项

Listing 3.13: Optimizing Xcode 4.6.3 (LLVM) (ARM mode)

```
__text:000028C4         _hello_world
__text:000028C4 80 40 2D E9		STMFD   SP!, {R7,LR}
__text:000028C8 86 06 01 E3		MOV     R0, #0x1686
__text:000028CC 0D 70 A0 E1     MOV     R7, SP
__text:000028D0 00 00 40 E3     MOVT    R0, #0
__text:000028D4 00 00 8F E0     ADD     R0, PC, R0
__text:000028D8 C3 05 00 EB     BL      _puts
__text:000028DC 00 00 A0 E3     MOV     R0, #0
__text:000028E0 80 80 BD E8     LDMFD   SP!, {R7,PC}

__cstring:00003F62 48 65 6C 6C +aHelloWorld_0    DCB "Hello world!", 0
```

我们来说已经非常熟悉`STMFD`和`LDMFD`了。

`MOV`指令就是将`0x1686`写入`R0`寄存器里。这个值也正是字串”Hello world！”的指针偏移。

R7寄存器(在[App10]里这是个标准)是一个帧指针，我们继续。

`MOVT R0， #0`(`MOVe Top`)指令时向`R0`的高16位写入0。这是因为普通情况下MOV这条指令在ARM模式下，只对低16位进行操作。需要记住的是所有在ARM模式下的指令都被限定在32bits内。当然这个限制并不影响2个寄存器直接的操作。这也是`MOVT`这种写高16位(包含第16~31位)指令存在的意义。其实这样写的代码会感觉有点多余，因为`MOVS R0，#0x1686`这条指令也能把高16位清0。或许这就是相对于人脑来说编译器的不足。

`ADD R0，PC，R0`指令把R0寄存器的值与PC寄存器的值进行相加并且保存到R0寄存器里面，用来计算`"Hello world!"`这个字串的绝对地址。上面已经介绍过了，这是因为代码是浮动地址的，所以这个修正是有必要的。

BL指令用来调用`printf()`的替代函数`puts()`函数。

GCC将printf（）函数替换成了puts()。因为printf()函数只有一个参数的时候跟puts()函数是类似的。printf()函数的字串参数里，没有以%开头的特殊控制符的时候，两个函数的功能是相似的。如果不是这样，这两个函数的功能会有所差别。

为什么编译器会替换`printf()`到`puts()`呢？也许是因为`puts()`函数更快。`puts()`函数效率更快是因为它只是做了字串的标准输出(stdout)，而不需要将字符串的每一位与%相比较。

下面，我们可以看到非常熟悉的`"MOV R0, #0"`指令，用来将`R0`寄存器设为0。

### 3.4.4 开启代码优化的Xcode(LLVM)编译thumb-2模式

在默认情况下，Xcode4.6.3会生成如下的Thumb-2代码

Listing 3.14: Optimizing Xcode 4.6.3 (LLVM) (Thumb-2 mode)

```
__text:00002B6C                _hello_world
__text:00002B6C 80 B5          PUSH    {R7,LR}
__text:00002B6E 41 F2 D8 30    MOVW    R0, #0x13D8
__text:00002B72 6F 46          MOV     R7, SP
__text:00002B74 C0 F2 00 00    MOVT.W  R0, #0
__text:00002B78 78 44          ADD     R0, PC
__text:00002B7A 01 F0 38 EA    BLX     _puts
__text:00002B7E 00 20          MOVS    R0, #0
__text:00002B80 80 BD          POP     {R7,PC}

...

__cstring:00003E70 48 65 6C 6C 6F 20 +aHelloWorld DCB "Hello world!",0xA,0
```

BL和BLX指令在thumb模式下情况需要我们回忆下刚才讲过的，它是由一对16-bit的指令来构成的。在thumb-2模式下这条指令跟thumb一样被编码成了32-bit指令。非常容易观察到的是，thumb-2的指令的机器码也是从0xFx或者0xEx的。对于thumb和thumb-2模式来说，在IDA的结果里机器码的位置和这里是交替交换的。对于ARM模式来说4个byte也是反向的，这是因为他们用了不同的字节序。所以我们可以知道，MOVW，MOVT.W和BLX这几个指令的开始都是0xFx。

在thumb-2指令里有一条是"MOVW R0, #0x13D8",它的作用是写数据到R0的低16位里面。

`MOVT.W R0, #0`的作用类似与前面讲到的MOVT指令，但它可以工作在thumb-2模式下。

还有些跟上面不同的地方，比如BLX指令替代了上面用到的BL指令，这条指令不仅将控制puts()函数返回的地址放入了LR寄存器里，并且讲代码从thumb模式转换到了ARM模式（或者ARM转换到thumb（根据现有情况判断））。这条指令跳转到下面这样的位置（下面的代码是ARM编码模式）。

```
__symbolstub1:00003FEC              	_puts  ; CODE XREF: _hello_world+E
__symbolstub1:00003FEC 44 F0 9F E5  	LDR PC, =__imp__puts
```

可能会有细心的读者要问了:为什么不直接跳转到puts()函数里面去？

因为那样做会浪费内存空间。

很多程序都会使用额外的动态库(dynamic libraries)(Windows里面的DLL，还有\*NIX里面的.so，MAC OS X里面的.dylib),通常使用的库函数会被放入动态库中，当然也包括标准C函数puts()。

在可执行的二进制文件里(Windows的PE里的.exe文件，ELF和Mach-O文件)都会有输入表段。它是一个用来引入额外模块里模块名称和符号（函数或者全局变量）的列表。

系统加载器（OS loader）会加载所有需要的模块，当在主模块里枚举输入符号的时候，会把每个符号正确的地址与相应的符号确立起来。

在我们的这个例子里，`__imp__puts`就是一个系统加载器加载额外模块的32位的地址值。LDR指令只需要把这个值加载到PC里面去，就可以控制程序流程到puts()函数里去。

所以只需要在系统加载器里的时候，一次性的就能将每个符号所对应的地址确定下来，这是个提高效率的好方式。

外加，我们前面也指出过，我们没办法只用一条指令并且不做内存操作的情况下就将一个32bit的值保存到寄存器里，ARM并不是唯一的模式的情况下，程序里去跳入动态库中的某个函数里，最好的办法就是这样做一些类似与上面这样单一指令的函数（称做thunk function），然后从thumb模式里也能去调用。

在上面的例子（ARM编译的那个例子）中BL指令也是跳转到了同一个thunk function里。尽管没有进行模式的转变（所以指令里不存在那个”X”）。

#### 关于形实转换函数


> ""


([The Jargon File](go.yurichev.com/17362))
### 3.4.5 ARM64

**GCC**

## 3.5 MIPS
### 3.5.1

### 3.5.2

### 3.5.3


### 3.5.4

### 3.5.5

## 3.5.5

## 3.7