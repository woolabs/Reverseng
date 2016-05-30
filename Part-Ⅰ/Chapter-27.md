# 第二十七章
# 使用SIMD来处理浮点数

当然，在增加了x64扩展这个特性之后，FPU在x86兼容处理器中还是存在的。但是同事，SIMD扩展（SSE, SSE2等）已经有了，他们也可以处理浮点数。数字格式依然相同（使用IEEE754标准）。

所以，x86-64编译器通常都使用SIMD指令。可以说这是一个好消息，因为这让我们可以更容易的使用他们。 
## 24.1 简单的例子

```
double f (double a, double b)
{
    return a/3.14 + b*4.1;
};
```

### 27.1.1 x64

清单24.1： MSFC 2012 x64 /Ox

```
__real@4010666666666666 DQ 04010666666666666r ; 4.1
__real@40091eb851eb851f DQ 040091eb851eb851fr ; 3.14
a$ = 8
b$ = 16
f PROC
    divsd xmm0, QWORD PTR __real@40091eb851eb851f
    mulsd xmm1, QWORD PTR __real@4010666666666666
    addsd xmm0, xmm1
    ret 0
f ENDP
```

输入的浮点数被传入了XMM0-XMM3寄存器，其他的通过栈来传递。 a被传入了XMM0，b则是通过XMM1。 XMM寄存器是128位的（可以参考SIMD22一节），但是我们的类型是double型的，也就意味着只有一半的寄存器会被使用。

DIVSD是一个SSE指令，意思是“Divide Scalar Double-Precision Floating-Point Values”（除以标量双精度浮点数值），它只是把一个double除以另一个double，然后把结果存在操作符的低一半位中。 常量会被编译器以IEEE754格式提前编码。 MULSD和ADDSD也是类似的，只不过一个是乘法，一个是加法。 函数处理double的结果将保存在XMM0寄存器中。

这是无优化的MSVC编译器的结果：

清单24.2： MSVC 2012 x64

```
__real@4010666666666666 DQ 04010666666666666r ; 4.1
__real@40091eb851eb851f DQ 040091eb851eb851fr ; 3.14
a$ = 8
b$ = 16
f PROC
    movsdx QWORD PTR [rsp+16], xmm1
    movsdx QWORD PTR [rsp+8], xmm0
    movsdx xmm0, QWORD PTR a$[rsp]
    divsd xmm0, QWORD PTR __real@40091eb851eb851f
    movsdx xmm1, QWORD PTR b$[rsp]
    mulsd xmm1, QWORD PTR __real@4010666666666666
    addsd xmm0, xmm1
    ret 0
f ENDP
```

有一些繁杂，输入参数保存在“shadow space”（影子空间，7.2.1节），但是只有低一半的寄存器，也即只有64位存了这个double的值。

### 27.1.2 x86


GCC编译器生成了几乎一样的代码。

## 24.2 通过参数传递浮点型变量

```
#include <math.h>
#include <stdio.h>
int main ()
{
    printf ("32.01 ^ 1.54 = %lf\n", pow (32.01,1.54));
    return 0;
}
```

他们通过XMM0-XMM3的低一半寄存器传递。

清单24.3： MSVC 2012 x64 /Ox

```
$SG1354 DB ’32.01 ^ 1.54 = %lf’, 0aH, 00H
__real@40400147ae147ae1 DQ 040400147ae147ae1r ; 32.01
__real@3ff8a3d70a3d70a4 DQ 03ff8a3d70a3d70a4r ; 1.54
main PROC
    sub rsp, 40 ; 00000028H
    movsdx xmm1, QWORD PTR __real@3ff8a3d70a3d70a4
    movsdx xmm0, QWORD PTR __real@40400147ae147ae1
    call pow
    lea rcx, OFFSET FLAT:$SG1354
    movaps xmm1, xmm0
    movd rdx, xmm1
    call printf
    xor eax, eax
    add rsp, 40 ; 00000028H
    ret 0
main ENDP
```

在Intel和AMD的手册中（见14章和1章）并没有MOVSDX这个指令，而只有MOVSD一个。所以在x86中有两个指令共享了同一个名字（另一个见B.6.2）。显然，微软的开发者想要避免弄得一团糟，所以他们把它重命名为MOVSDX，它只是会多把一个值载入XMM寄存器的低一半中。 pow（）函数从XMM0和XMM1中加载参数，然后返回结果到XMM0中。 然后把值移动到RDX中，因为接下来printf()需要调用这个函数。为什么？老实说我也不知道，也许是因为printf()是一个参数不定的函数？

清单24.4：GCC 4.4.6 x64 -O3

```
.LC2:
.string "32.01 ^ 1.54 = %lf\n"
main:
    sub rsp, 8
    movsd xmm1, QWORD PTR .LC0[rip]
    movsd xmm0, QWORD PTR .LC1[rip]
    call pow
    ; result is now in XMM0
    mov edi, OFFSET FLAT:.LC2
    mov eax, 1 ; number of vector registers passed
    call printf
    xor eax, eax
    add rsp, 8
    ret
.LC0:
    .long 171798692
    .long 1073259479
.LC1:
    .long 2920577761
    .long 1077936455
```

GCC让结果更清晰，printf（）的值传入到了XMM0中。顺带一提，这是一个因为printf()才把1写入EAX中的例子。这意味着参数会被传递到向量寄存器中，就像标准需求一样（见21章）。

## 27.3 比较式的例子

```
double d_max (double a, double b)
{
    if (a>b)
    return a;
    return b;
};
```
### 27.3.1 x64
清单 24.5： MSVC 2012 x64 /Ox

```
a$ = 8
b$ = 16
d_max PROC
    comisd xmm0, xmm1
    ja SHORT $LN2@d_max
    movaps xmm0, xmm1
$LN2@d_max:
    fatret 0
d_max ENDP
```

优化过的MSVC产生了很容易理解的代码。 COMISD是“Compare Scalar Ordered Double-Precision Floating-Point Values and Set EFLAGS”（比较标量双精度浮点数的值然后设置EFLAG）的缩写，显然，看着名字就知道他要干啥了。 非优化的MSVC代码产生了更加丰富的代码，但是仍然不难理解：

清单 24.6： MSVC 2012 x64

```
a$ = 8
b$ = 16
d_max PROC
    comisd xmm0, xmm1
    ja SHORT $LN2@d_max
    movaps xmm0, xmm1
    $LN2@d_max:
    fatret 0
d_max ENDP
```

但是，GCC 4.4.6生成了更多的优化代码，并且使用了MAXSD（“Return Maximum Scalar Double-Precision Floating-Point Value”，返回最大的双精度浮点数的值）指令，它将选中其中一个最大数。


清单24.7： GCC 4.4.6 x64 -O3

```
a$ = 8
b$ = 16
d_max PROC
    movsdx QWORD PTR [rsp+16], xmm1
    movsdx QWORD PTR [rsp+8], xmm0
    movsdx xmm0, QWORD PTR a$[rsp]
    comisd xmm0, QWORD PTR b$[rsp]
    jbe SHORT $LN1@d_max
    movsdx xmm0, QWORD PTR a$[rsp]
    jmp SHORT $LN2@d_max
    $LN1@d_max:
    movsdx xmm0, QWORD PTR b$[rsp]
    $LN2@d_max:
    fatret 0
d_max ENDP
```
### 27.3.2 x86

## 27.4 Calculating machine epsilon: x64 and SIMD

## 27.5 回顾伪随机书生成器

## 27.6 总结

只有低一半的XMM寄存器会被使用，一组IEEE754格式的数字也会被存在这里。 显然，所有的指令都有SD后缀（标量双精度数），这些操作数是可以用于IEEE754浮点数的，他们存在XMM寄存器的低64位中。 比FPU更简单的是，显然SIMD扩展并不像FPU以前那么混乱，栈寄存器模型也没使用。 如果你像试着将例子中的double替换成float的话，它们还是会使用同样的指令，但是后缀是SS（标量单精度数），例如MOVSS，COMISS，ADDSS等等。 标量（Scalar）代表着SIMD寄存器会包含仅仅一个值，而不是所有的。可以在所有类型的值中生效的指令都被“封装”成同一个名字。