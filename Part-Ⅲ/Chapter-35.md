# 温度转换

另一个在初学者的编程书中常见的例子是温度转换程序，例如将华氏度转为摄氏度，或者反过来。

我也添加了一个简单的错误处理： 1）我们应该检查用户是否输入了正确的数字 2）我们应该检查摄氏度是否低于-273゜C，因为这比绝对零度还低，学校物理课上的东西应该都还记得。 exit()函数将立即终止程序，而不会回到调用者函数。

## 35.1 整数值

```
#include <stdio.h>
#include <stdlib.h>
int main()
{
    int celsius, fahr;
    printf ("Enter temperature in Fahrenheit:\n");
    if (scanf ("%d", &fahr)!=1)
    {
        printf ("Error while parsing your input\n");
        exit(0);
    };
    celsius = 5 * (fahr-32) / 9;
    if (celsius<-273)
    {
        printf ("Error: incorrect temperature!\n");
        exit(0);
    };
    printf ("Celsius: %d\n", celsius);
};
```

## 35.1.1 MSVC 2012 x86 

清单35.1： MSVC 2012 x86 

```
$SG4228 DB ’Enter temperature in Fahrenheit:’, 0aH, 00H
$SG4230 DB ’%d’, 00H
$SG4231 DB ’Error while parsing your input’, 0aH, 00H
$SG4233 DB ’Error: incorrect temperature!’, 0aH, 00H
$SG4234 DB ’Celsius: %d’, 0aH, 00H
_fahr$ = -4 ; size = 4
_main PROC
    push ecx
    push esi
    mov esi, DWORD PTR __imp__printf
    push OFFSET $SG4228 ; ’Enter temperature in Fahrenheit:’
    call esi ; call printf()
    lea eax, DWORD PTR _fahr$[esp+12]
    push eax
    push OFFSET $SG4230 ; ’%d’
    call DWORD PTR __imp__scanf
    add esp, 12 ; 0000000cH
    cmp eax, 1
    je SHORT $LN2@main
    push OFFSET $SG4231 ; ’Error while parsing your input’
    call esi ; call printf()
    add esp, 4
    push 0
    call DWORD PTR __imp__exit
    $LN9@main:
    $LN2@main:
    mov eax, DWORD PTR _fahr$[esp+8]
    add eax, -32 ; ffffffe0H
    lea ecx, DWORD PTR [eax+eax*4]
    mov eax, 954437177 ; 38e38e39H
    imul ecx
    sar edx, 1
    mov eax, edx
    shr eax, 31 ; 0000001fH
    add eax, edx
    cmp eax, -273 ; fffffeefH
    jge SHORT $LN1@main
    push OFFSET $SG4233 ; ’Error: incorrect temperature!’
    call esi ; call printf()
    add esp, 4
    push 0
    call DWORD PTR __imp__exit
    $LN10@main:
    $LN1@main:
    push eax
    push OFFSET $SG4234 ; ’Celsius: %d’
    call esi ; call printf()
    add esp, 8
    ; return 0 - at least by C99 standard
    xor eax, eax
    pop esi
    pop ecx
    ret 0
$LN8@main:
_main ENDP
```

关于这个我们可以说的是：

- printf()的地址先被载入了ESI寄存器中，所以printf()调用的序列会被CALL ESI处理，这是一个非常著名的编译器技术，当代码中存在多个序列调用同一个函数的时候，并且/或者有空闲的寄存器可以用上的时候，编译器就会这么做。 
- 我们知道ADD EAX,-32指令会把EAX中的数据减去32。 EAX = EAX + (-32)等同于 EAX = EAX - 32，因此编译器决定用ADD而不是用SUB，也许这样性能比较高吧。
- LEA指令在值应当乘以5的时候用到了： lea ecx, DWORD PTR [eax+eax*4]。 是的，i + i * 4是等同于i*5的，而且LEA比IMUL运行的要快。 还有，SHL EAX,2/ ADD EAX,EAX指令对也可以替换这句，而且有些编译器就是会这么优化。
- 用乘法做除法的技巧也会在这儿用上。
- 虽然我们没有指定，但是main()函数依然会返回0。C99规范告诉我们[15章， 5.1.2.2.3] main()将在没有return时也会照常返回0。 这个规则仅仅对main()函数有效。 虽然MSVC并不支持C99，但是这么看说不好他还是做到了一部分呢？

### 35.1.2 MSVC 2012 x64 /Ox

生成的代码几乎一样，但是我发现每个exit()调用之后都有INT 3。

```
xor ecx, ecx
call QWORD PTR __imp_exit
int 3
```

INT 3是一个调试器断点。 可以知道的是exit()是永远不会return的函数之一。所以如果他“返回”了，那么估计发生了什么奇怪的事情，也是时候启动调试器了。

## 35.2 浮点数值

清单35.1: MSVC 2010

```
#include <stdio.h>
#include <stdlib.h>
int main()
{
    double celsius, fahr;
    printf ("Enter temperature in Fahrenheit:\n");
    if (scanf ("%lf", &fahr)!=1)
    {
        printf ("Error while parsing your input\n");
        exit(0);
    };
    celsius = 5 * (fahr-32) / 9;
    if (celsius<-273)
    {
        printf ("Error: incorrect temperature!\n");
        exit(0);
    };
    printf ("Celsius: %lf\n", celsius);
};
```

MSVC 2010 x86使用FPU指令...

清单35.2: MSVC 2010 x86 /Ox

```
$SG4038 DB ’Enter temperature in Fahrenheit:’, 0aH, 00H
$SG4040 DB ’%lf’, 00H
$SG4041 DB ’Error while parsing your input’, 0aH, 00H
$SG4043 DB ’Error: incorrect temperature!’, 0aH, 00H
$SG4044 DB ’Celsius: %lf’, 0aH, 00H
__real@c071100000000000 DQ 0c071100000000000r ; -273
__real@4022000000000000 DQ 04022000000000000r ; 9
__real@4014000000000000 DQ 04014000000000000r ; 5
__real@4040000000000000 DQ 04040000000000000r ; 32
_fahr$ = -8 ; size = 8
_main PROC
    sub esp, 8
    push esi
    mov esi, DWORD PTR __imp__printf
    push OFFSET $SG4038 ; ’Enter temperature in Fahrenheit:’
    call esi ; call printf
    lea eax, DWORD PTR _fahr$[esp+16]
    push eax
    push OFFSET $SG4040 ; ’%lf’
    call DWORD PTR __imp__scanf
    add esp, 12 ; 0000000cH
    cmp eax, 1
    je SHORT $LN2@main
    push OFFSET $SG4041 ; ’Error while parsing your input’
    call esi ; call printf
    add esp, 4
    push 0
    call DWORD PTR __imp__exit
    $LN2@main:
    fld QWORD PTR _fahr$[esp+12]
    fsub QWORD PTR __real@4040000000000000 ; 32
    fmul QWORD PTR __real@4014000000000000 ; 5
    fdiv QWORD PTR __real@4022000000000000 ; 9
    fld QWORD PTR __real@c071100000000000 ; -273
    fcomp ST(1)
    fnstsw ax
    test ah, 65 ; 00000041H
    jne SHORT $LN1@main
    push OFFSET $SG4043 ; ’Error: incorrect temperature!’
    fstp ST(0)
    call esi ; call printf
    add esp, 4
    push 0
    call DWORD PTR __imp__exit
    $LN1@main:
    sub esp, 8
    fstp QWORD PTR [esp]
    push OFFSET $SG4044 ; ’Celsius: %lf’
    call esi
    add esp, 12 ; 0000000cH
    ; return 0
    xor eax, eax
    pop esi
    add esp, 8
    ret 0
$LN10@main:
_main ENDP
```

但是MSVC从2012年开始又改成了使用SIMD指令：

清单35.3: MSVC 2010 x86 /Ox

```
$SG4228 DB ’Enter temperature in Fahrenheit:’, 0aH, 00H
$SG4230 DB ’%lf’, 00H
$SG4231 DB ’Error while parsing your input’, 0aH, 00H
$SG4233 DB ’Error: incorrect temperature!’, 0aH, 00H
$SG4234 DB ’Celsius: %lf’, 0aH, 00H
__real@c071100000000000 DQ 0c071100000000000r ; -273
__real@4040000000000000 DQ 04040000000000000r ; 32
__real@4022000000000000 DQ 04022000000000000r ; 9
__real@4014000000000000 DQ 04014000000000000r ; 5
_fahr$ = -8 ; size = 8
_main PROC
    sub esp, 8
    push esi
    mov esi, DWORD PTR __imp__printf
    push OFFSET $SG4228 ; ’Enter temperature in Fahrenheit:’
    call esi ; call printf
    lea eax, DWORD PTR _fahr$[esp+16]
    push eax
    push OFFSET $SG4230 ; ’%lf’
    call DWORD PTR __imp__scanf
    add esp, 12 ; 0000000cH
    cmp eax, 1
    je SHORT $LN2@main
    push OFFSET $SG4231 ; ’Error while parsing your input’
    call esi ; call printf
    add esp, 4
    push 0
    call DWORD PTR __imp__exit
    $LN9@main:
    $LN2@main:
    movsd xmm1, QWORD PTR _fahr$[esp+12]
    subsd xmm1, QWORD PTR __real@4040000000000000 ; 32
    movsd xmm0, QWORD PTR __real@c071100000000000 ; -273
    mulsd xmm1, QWORD PTR __real@4014000000000000 ; 5
    divsd xmm1, QWORD PTR __real@4022000000000000 ; 9
    comisd xmm0, xmm1
    jbe SHORT $LN1@main
    push OFFSET $SG4233 ; ’Error: incorrect temperature!’
    call esi ; call printf
    add esp, 4
    push 0
    call DWORD PTR __imp__exit
    $LN10@main:
    $LN1@main:
    sub esp, 8
    movsd QWORD PTR [esp], xmm1
    push OFFSET $SG4234 ; ’Celsius: %lf’
    call esi ; call printf
    add esp, 12 ; 0000000cH
    ; return 0
    xor eax, eax
    pop esi
    add esp, 8
    ret 0
$LN8@main:
_main ENDP
```

当然，SIMD在x86下也是可用的，包括这些浮点数的运算。使用他们计算起来也确实方便点，所以微软编译器使用了他们。 我们也可以注意到 -273 这个值会很早的被载入XMM0。这个没问题，因为编译器并不一定会按照源代码里面的顺序产生代码。