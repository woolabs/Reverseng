# 联合体

## 19.1 伪随机数生成器的例子

如果我们需要0～1的随机浮点数，最简单的方法就是用PRNG（伪随机数发生器），比如马特赛特旋转演算法可以生成一个随机的32位的DWORD。然后我们可以把这个值转为FLOAT类型，然后除以RAND_MAX（我们的例子是0xFFFFFFFF），这样，我们得到的将是0..1区间的数。 但是如我们所知道的是，除法很慢。我们是否能摆脱它呢？就像我们用乘法做除法一样（14章）。 让我们想想浮点数由什么构成：符号位、有效数字位、指数位。我们只需要在这里面存储一些随机的位就好了。 指数不能变成0（在本例里面数字会不正常），所以我们存储0111111到指数里面，这意味着指数位将是1。然后，我们用随机位填充有效数字位，然后把符号位设置为0（正数）。生成的数字将在1-2的间隔中生成，所以我们必须从里面再减去1。 我例子里面是最简单的线性同余随机数生成器，生成32位（译注：32-bit比特位，非数字位）的数字。PRNG将会用UNIX时间戳来初始化。 然后，我们会把float类型当作联合体（union）来处理，这是一个C/C++的结构。它允许我们把一片内存里面各种不同类型的数据联合覆盖到一起用。在我们的例子里，我们可以创建一个union，然后通过float或者uint32_t来访问它。因此，这只是一个小技巧，而且是很脏的技巧。

```
#include <stdio.h>
#include <stdint.h>
#include <time.h>
union uint32_t_float
{
    uint32_t i;
    float f;
};
// from the Numerical Recipes book
const uint32_t RNG_a=1664525;
const uint32_t RNG_c=1013904223;
int main()
{
    uint32_t_float tmp;
    uint32_t RNG_state=time(NULL); // initial seed
    for (int i=0; i<100; i++)
    {
        RNG_state=RNG_state*RNG_a+RNG_c;
        tmp.i=RNG_state & 0x007fffff | 0x3F800000;
        float x=tmp.f-1;
        printf ("%f", x);
    };
    return 0;
};
```

清单19.1: MSVC 2010 （/Ox）

```
$SG4232 DB ’%f’, 0aH, 00H
__real@3ff0000000000000 DQ 03ff0000000000000r ; 1
tv140= -4 ; size = 4
_tmp$= -4 ; size = 4
_main PROC
    push ebp
    mov ebp, esp
    and esp, -64 ; ffffffc0H
    sub esp, 56 ; 00000038H
    push esi
    push edi
    push 0
    call __time64
    add esp, 4
    mov esi, eax
    mov edi, 100 ; 00000064H
$LN3@main:
    ; let’s generate random 32-bit number
    imul esi, 1664525 ; 0019660dH
    add esi, 1013904223 ; 3c6ef35fH
    mov eax, esi
    ; leave bits for significand only
    and eax, 8388607 ; 007fffffH
    ; set exponent to 1
    or eax, 1065353216 ; 3f800000H
    ; store this value as int
    mov DWORD PTR _tmp$[esp+64], eax
    sub esp, 8
    ; load this value as float
    fld DWORD PTR _tmp$[esp+72]
    ; subtract one from it
    fsub QWORD PTR __real@3ff0000000000000
    fstp DWORD PTR tv140[esp+72]
    fld DWORD PTR tv140[esp+72]
    fstp QWORD PTR [esp]
    push OFFSET $SG4232
    call _printf
    add esp, 12 ; 0000000cH
    dec edi
    jne SHORT $LN3@main
    pop edi
    xor eax, eax
    pop esi
    mov esp, ebp
    pop ebp
    ret 0
_main ENDP
_TEXT ENDS
END
```

GCC也生成了非常相似的代码。