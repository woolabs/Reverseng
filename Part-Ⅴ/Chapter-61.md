# 第61章 
# 可疑的代码模式
## 61.1 XOR 指令

像XOR op这样的指令，op为寄存器(比如，xor eax，eax)通常用于将寄存器的值设置为零，但如果操作数不同，"互斥或"运算将被执行。在普通的程序中这种操作较罕见，但在密码学中应用较广，包括业余的。如果第二个操作数是一个很大的数字，那么就更可疑了。可能会指向加密/解密操作或校验和的计算等等。

而这种观察也可能是无意义的，比如"canary"(18.3节)。canary的产生和检测通常使用XOR指令。

下面这个awk脚本可用于处理IDA的.list文件：

```
gawk -e '$2=="xor" { tmp=substr($3, 0, length($3)-1); if (tmp!=$4) if($4!="esp") if ($4!="ebp")⤦￼￼￼￼￼￼￼￼􏰀 {print$1,$2,tmp,",",$4}}'filename.lst
```

## 61.2 Hand-written assembly code

现代编译器不会emit LOOP和RCL指令。另一方面，这些指令对于直接用汇编语言编程的程序员来说很熟悉。如果你发现了这些指令，可以猜测这部分代码极有可能是手工编写的。这样的代码在这个指令列表中用(M)标记：A.6节。

同时函数prologue/epilogue通常不会以手工编写的汇编的形式呈现。

通常情况下，手工编写的代码中参数传递给函数没有固定的系统。

Windows 2003 内核(ntoskrnl.exe 文件)的例子：

```
MultiplyTest	proc near			; CODE XREF: Get386Stepping
				xor     cx, cx
loc_620555:							; CODE XREF: MultiplyTest+E
				push 	cx
				call 	Multiply
				pop 	cx
				jb 		short locret_620563
				loop 	loc_620555
				clc
locret_620563:						; CODE XREF:MultiplyTest+C
				retn
MultiplyTest endp

Multiply 		proc near 			;CODE XREF:MultiplyTest+5
				mov ecx,81h
				mov eax,417A000h
				mul ecx
				cmp edx,2
				stc
				jnz short locret_62057F
				cmp  eax,0FE7A000h
				stc
				jnz short locret_62057F
				clc
locret_62057F:						; CODE XREF:Multiply+10
									; Multiply+18
				retn
Multiply		endp
```

事实上，如果我们查看WRK v1.2源码，上面的代码在WRK-v1.2\base\ntos\ke\i386\cpu.asm文件中很容易找到。