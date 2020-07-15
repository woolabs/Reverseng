# 第六十四章 
# 传递参数的方法

## 64.1 cdcel

这种传递参数的方法在C/C++语言里面比较流行。

如下的代码片段所示，调用者反序地把参数压到栈中：最后一个参数，倒数第二个参数，第一个参数。调用者还必须在函数返回之后把栈指针（ESP）还原为初始状态。

Listing 64.1: cdecl
```
push arg3
push arg2
push arg1
call function
add esp, 12 ; returns ESP
```

## 64.2 stdcall

该调用方法与cdecl差不多，除了被调用者必须通过RET x指令代替RET指令将ESP指针设置为初始化状态，其中`x = arguments number * sizeof(int)`。调用者无需调整栈指针(ESP)。

Listing 64.2: stdcall
```
push arg3
push arg2
push arg1
call function
function:
... do something ...
ret 12
```

这种调用方式在win32的标准库无处不在，但win64并不使用该调用方法（具体参见下文win64一节）。

举个例子，我们可以稍微把在91页中8.1的示例代码修改一下，增加一个`__stdcall`修饰符。

```
int __stdcall f2 (int a, int b, int c)
{
	return a*b+c;
};
```

编译出来的结果跟8.2几乎一模一样，但你可以看到它是通过RET 12而不是RET返回的。同时，调用者并没有调整栈指针(ESP)。

因此，很容易通过RETN n指令推导出函数参数的数量（n除以四）。

Listing 64.3: MSVC 2010

```
_a$ = 8 ; size = 4
_b$ = 12 ; size = 4
_c$ = 16 ; size = 4
_f2@12 PROC
    push ebp
    mov ebp, esp
    mov eax, DWORD PTR _a$[ebp]
    imul eax, DWORD PTR _b$[ebp]
    add eax, DWORD PTR _c$[ebp]
    pop ebp
    ret 12 ; 0000000cH
_f2@12 ENDP
; ...
    push 3
    push 2
    push 1
    call _f2@12
    push eax
    push OFFSET $SG81369
    call _printf
    add esp, 8
```

### 64.2.1 可变参数的函数

printf()系列的函数大概是C/C++里面唯一一系列具有可变参数的函数了，在这些函数的帮助下很容易理清cdecl和stdcall两种调用方式之间的重要区别。让我们先假设编译器知道每个调用printf()函数的参数的个数，无论如何，当我们调用printf()的时候，它已经存在于编译好的MSVCRT.DLL之中（我们讨论的是Windows），并没有任何关于传递多少个参数的信息，剩下的办法就是通过它的格式字符串获取得到参数个数。因此，如果printf()函数是一个stdcall调用方式的函数，它必须通过格式字符串计算参数个数用于恢复栈指针（ESP），这是一种相当危险的情况，程序员的一个错别字就可以导致程序崩溃。因此此类函数使用cdecl调用方式远比使用stdcall调用方式适合。

## 64.3 fastcall

这是一种将部分参数通过寄存器传入，其余参数通过栈方式传入的方法。它的执行效率在一些旧时CPU比cdecl/stdcall要好（因为小栈的压力）。然而，在现代的CPU中使用该调用方式不一定能获得更好的性能。

fastcall并没有一个标准化，因此不同的编译器的实现可以不同。这是一个众所周知的警告：如果你有两个DLL，其中第一个DLL调用第二个DLL的函数，它们是又分别不同的编译器使用fastcall调用方式编译出来的，则会有不可预期的后果。

MSVC和GCC两个编译器都是通过ECX和EDX来传递第一个和第二个参数，通过栈进行传递其余参数。栈指针必须被被调用者恢复为初始状态（与stdcall类似）。

Listing 64.4: fastcall

```
push arg3
mov edx, arg2
mov ecx, arg1
call function
function:
.. do something ..
ret 4
```

举个例子，我们可以稍微把8.1的示例代码修改一下，增加一个`__fastcall`修饰符。

```
int __fastcall f3 (int a, int b, int c)
{
	return a*b+c;
};
```

下面它编译出来的结果：

Listing 64.5: Optimizing MSVC 2010 /Ob0

```
_c$ = 8 		; size = 4
@f3@12 PROC
; _a$ = ecx
; _b$ = edx
    mov eax, ecx
    imul eax, edx
    add eax, DWORD PTR _c$[esp-4]
    ret 4
@f3@12 ENDP
; ...
    mov edx, 2
    push 3
    lea ecx, DWORD PTR [edx-1]
    call @f3@12
    push eax
    push OFFSET $SG81390
    call _printf
    add esp, 8
```

我们可以看到被调用者使用RET N指令来调整栈指针（ESP）。这意味着，我们可以通过这条指令来推断出参数的个数。

### 64.3.1 GCC regparm

这是一种对fastcall调用方式的某种优化。使用-mregparm编译选项可以设置多少个参数是通过寄存器传递的（最大为3个）。因此，EAX，EDX和ECX寄存器将被使用。

当然，如果指定通过寄存器传参的参数数量小于三个的时候，并没有使用完这三个寄存器。

调用者需要把栈指针恢复为初始状态。

相关例子请参看(19.1.1)。

### 64.3.2 Watcom/OpenWatcom 编译器

在这里，它被成为“寄存器调用约定”，头四个参数通过EAX，EDX，EBX和ECX传递。其余参数通过栈传递。通过在函数名上添加下划线来区分那些不同的调用约定。

## 64.4 thiscall

这是C++里面传递this指针的成员函数调用约定。

在MSVC里面，this指针通过ECX寄存器来传递。

在GCC里面，this指针是通过第一个参数进行传递的。因此很明显，在所有成员函数里面都会多出一个额外的参数。

相关例子请查看（51.1.1）。

## 64.5 x86-64

### 64.5.1 Windows x64

在Win64里面传递函数参数的方法类似fastcall调用约定。前四个参数通过RCX，RDX，R8和R9寄存器传参，其余参数通过栈进行传递。调用者还必须预留32个字节或者4个64位的空间，让被调用者可以保存前四个参数。短函数可能直接使用通过寄存器传过来的值，但更大的可能是保存那些值后在进一步使用。

调用者还必须负责还原栈指针。

这个调用约定也用于Windows x86-64位系统上的DLL（而不是Win32的stdcall）。

例子

```
#include <stdio.h>
void f1(int a, int b, int c, int d, int e, int f, int g)
{
	printf ("%d %d %d %d %d %d %d\n", a, b, c, d, e, f, g);
};
int main()
{
	f1(1,2,3,4,5,6,7);
};
```

Listing 64.6: MSVC 2012 /0b

```
$SG2937 DB '%d %d %d %d %d %d %d', 0aH, 00H
main PROC
    sub rsp, 72 					; 00000048H
    mov DWORD PTR [rsp+48], 7
    mov DWORD PTR [rsp+40], 6
    mov DWORD PTR [rsp+32], 5
    mov r9d, 4
    mov r8d, 3
    mov edx, 2
    mov ecx, 1
    call f1
    xor eax, eax
    add rsp, 72 					; 00000048H
    ret 0
main ENDP
a$ = 80
b$ = 88
c$ = 96
d$ = 104
e$ = 112
f$ = 120
g$ = 128
f1 PROC
$LN3:
    mov DWORD PTR [rsp+32], r9d
    mov DWORD PTR [rsp+24], r8d
    mov DWORD PTR [rsp+16], edx
    mov DWORD PTR [rsp+8], ecx
    sub rsp, 72 					; 00000048H
    mov eax, DWORD PTR g$[rsp]
    mov DWORD PTR [rsp+56], eax
    mov eax, DWORD PTR f$[rsp]
    mov DWORD PTR [rsp+48], eax
    mov eax, DWORD PTR e$[rsp]
    mov DWORD PTR [rsp+40], eax
    mov eax, DWORD PTR d$[rsp]
    mov DWORD PTR [rsp+32], eax
    mov r9d, DWORD PTR c$[rsp]
    mov r8d, DWORD PTR b$[rsp]
    mov edx, DWORD PTR a$[rsp]
    lea rcx, OFFSET FLAT:$SG2937
    call printf
    add rsp, 72 					; 00000048H
    ret 0
    f1 ENDP
```

在这里我们可以清楚看到这7个参数是如何传递的：4个参数通过寄存器传递而其余3个通过栈传递。f1()的反汇编代码一开始就把参数保存到“预留”的栈空间之中，这样做的目的是编译器并不能保证有足够的寄存器可以使用，如果不这样做的话这四个寄存器将被参数占用到函数执行结束。最后，预留栈空间是调用者的职责。

Listing 64.7: Optimizing MSVC 2012 /0b
```
$SG2777 DB '%d %d %d %d %d %d %d', 0aH, 00H
a$ = 80
b$ = 88
c$ = 96
d$ = 104
e$ = 112
f$ = 120
g$ = 128
f1 PROC
$LN3:
	sub rsp, 72 					; 00000048H
	mov eax, DWORD PTR g$[rsp]
	mov DWORD PTR [rsp+56], eax
	mov eax, DWORD PTR f$[rsp]
	mov DWORD PTR [rsp+48], eax
	mov eax, DWORD PTR e$[rsp]
	mov DWORD PTR [rsp+40], eax
	mov DWORD PTR [rsp+32], r9d
	mov r9d, r8d
	mov r8d, edx
	mov edx, ecx
	lea rcx, OFFSET FLAT:$SG2777
	call printf
	add rsp, 72 					; 00000048H
	ret 0
f1 ENDP
main PROC
	sub rsp, 72 					; 00000048H
	mov edx, 2
	mov DWORD PTR [rsp+48], 7
	mov DWORD PTR [rsp+40], 6
	lea r9d, QWORD PTR [rdx+2]
	lea r8d, QWORD PTR [rdx+1]
	lea ecx, QWORD PTR [rdx-1]
	mov DWORD PTR [rsp+32], 5
	call f1
	xor eax, eax
	add rsp, 72 					; 00000048H
	ret 0
main ENDP
```

如果我们使用了编译优化的开关去编译上面的例子，它的反汇编码几乎是相同的，但是预留的栈空间将不被使用，因为在这里并不需要使用到预留的栈空间。

而且可以看到MSVC 2012是如何利用LEA指令来优化代码（A.6.2）。

我也不确定是否值得这么做。

更多的例子请看（74.1）

#### this指针的传递(C/C++)

this指针通过RCX传递，成员函数的第一个参数通过RDX传递，更多例子请看（51.1.1）。


### 64.5.2 Linux x64

Linux x86-64传递参数的方式几乎和Windows一样。但是是通过6个寄存器代替4个寄存器来传参（RDI，RSI，RDX，RCX，R8，R9），另外并没有预留的栈空间这回事。虽然，如果它需要/想要的话，可以把寄存器的值保存到栈之中。

Listing 64.8: Optimizing GCC 4.7.3

```
.LC0:
	.string "%d %d %d %d %d %d %d\n"
f1:
	sub rsp, 40
	mov eax, DWORD PTR [rsp+48]
	mov DWORD PTR [rsp+8], r9d
	mov r9d, ecx
	mov DWORD PTR [rsp], r8d
	mov ecx, esi
	mov r8d, edx
	mov esi, OFFSET FLAT:.LC0
	mov edx, edi
	mov edi, 1
	mov DWORD PTR [rsp+16], eax
	xor eax, eax
	call __printf_chk
	add rsp, 40
	ret
main:
	sub rsp, 24
	mov r9d, 6
	mov r8d, 5
	mov DWORD PTR [rsp], 7
	mov ecx, 4
	mov edx, 3
	mov esi, 2
	mov edi, 1
	call f1
	add rsp, 24
	ret
```

注意：这里的值是写入到32-bit的寄存器（EAX...）而不是整个64-bit寄存器（RAX...）。这是因为写入到32-bit寄存器的时候会自动清空高32-bit。据说，这是为了方便把代码移植到x86-64。

## 64.6 返回float和double类型的值

除了Win64之外，其它返回float和double类型的值都是通过FPU里面的ST(0)寄存器返回的。
在Win64里面，返回float和double类型的值是通过XMM0寄存器返回。

## 64.7 修改参数

有时候，C/C++程序员（虽然不仅仅是这些人）可能会问，如果他们碰巧修改了参数会怎样？答案非常简单，这些参数是保存在栈里面的，修改参数的时候是修改这个栈里面的内容，调用者并没有在被调用函数退出之后再使用它们（至少在我的实践中没有遇到这种情况）。

```
#include <stdio.h>
void f(int a, int b)
{
	a=a+b;
	printf ("%d\n", a);
};
```

Listing 64.9: MSVC 2012

```
_a$ = 8 	; size = 4
_b$ = 12 	; size = 4
_f PROC
	push ebp
	mov ebp, esp
	mov eax, DWORD PTR _a$[ebp]
	add eax, DWORD PTR _b$[ebp]
	mov DWORD PTR _a$[ebp], eax
	mov ecx, DWORD PTR _a$[ebp]
	push ecx
	push OFFSET $SG2938 ; '%d', 0aH
	call _printf
	add esp, 8
	pop ebp
	ret 0
_f END
```

是的，可以随便修改参数。当然，这得它不是C++的引用（references）（51.3），而且你如果不修改通过指针指向的数据。那么修改参数是不会影响到当前函数的。

从理论上来讲，被调用者的函数返回之后，调用者可以获取并修改和使用它。如果它是直接使用汇编语言编写的。但C/C++并不提供任何方式可以访问它们。

## 64.8 使用指针的函数参数

...更有意思的是，有可能在程序中，取一个函数参数的指针并将其传递给另外一个函数。

```
#include <stdio.h>
// located in some other file
void modify_a (int *a);
void f (int a)
{
	modify_a (&a);
	printf ("%d\n", a);
};
```

很难理解它是如果实现的，直到我们看到它的反汇编码：

Listing 64.10: Optimizing MSVC 2010

```
$SG2796 DB '%d', 0aH, 00H
_a$ = 8
_f PROC
	lea eax, DWORD PTR _a$[esp-4] 	; just get the address of value in local stack
	push eax 						; and pass it to modify_a()
	call _modify_a
	mov ecx, DWORD PTR _a$[esp] 	; reload it from the local stack
	push ecx 						; and pass it to printf()
	push OFFSET $SG2796 			; '%d'
	call _printf
	add esp, 12
	ret 0
_f ENDP
```

传递到另一个函数是a在栈空间上的地址，该函数修改了指针指向的值然后再调用printf()来打印出修改之后的值。

细心的读者可能会问，使用寄存器传参的调用约定是如何传递函数指针参数的？

这是一种利用了影子空间的情况，输入的参数值先从寄存器复制到局部栈中的影子空间，然后再讲这个地址传递给其他函数。

Listing 64.11: Optimizing MSVC 2012 x64

```
$SG2994 DB '%d', 0aH, 00H
a$ = 48
f PROC
	mov DWORD PTR [rsp+8], ecx 		; save input value in Shadow Space
	sub rsp, 40
	lea rcx, QWORD PTR a$[rsp] 		; get address of value and pass it to modify_a()
	call modify_a
	mov edx, DWORD PTR a$[rsp] 		; reload value from Shadow Space and pass it to printf()
	lea rcx, OFFSET FLAT:$SG2994	; '%d'
	call printf
	add rsp, 40
	ret 0
f ENDP
```

GCC同样将传入的参数存储在本地栈空间：

Listing 64.12: Optimizing GCC 4.9.1 x64

```
.LC0:
.string "%d\n"
f:
	sub rsp, 24
	mov DWORD PTR [rsp+12], edi 	; store input value to the local stack
	lea rdi, [rsp+12] 				; take an address of the value and pass it to modify_a()
	call modify_a
	mov edx, DWORD PTR [rsp+12] 	; reload value from the local stack and pass it to printf()
	mov esi, OFFSET FLAT:.LC0 		; '%d'
	mov edi, 1
	xor eax, eax
	call __printf_chk
	add rsp, 24
	ret
```

ARM64的GCC也做了同样的事情，但这个空间称为寄存器保护区：

```
f:
	stp x29, x30, [sp, -32]!
	add x29, sp, 0 		; setup FP
	add x1, x29, 32 	; calculate address of variable in Register Save Area
	str w0, [x1,-4]! 	; store input value there
	mov x0, x1 			; pass address of variable to the modify_a()
	bl modify_a
	ldr w1, [x29,28] 	; load value from the variable and pass it to printf()
	adrp x0, .LC0 ; '%d'
	add x0, x0, :lo12:.LC0
	bl printf ; call printf()
	ldp x29, x30, [sp], 32
	ret
.LC0:
	.string "%d\n"
```

顺便提一下，一个类似影子空间的使用在这里也被提及过（46.1.2）。