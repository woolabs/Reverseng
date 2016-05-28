# 第二十四章
# 在32位环境中的64位值

在32位环境中的通用寄存器是32位的，所以64位值转化为一对32位值。

## 24.1 返回64位的值

### 24.1.1 x86

### 24.1.2 ARM

### 24.1.3 MIPS

## 24.2参数的传递，加法，减法

```
#include <stdint.h>
uint64_t f1 (uint64_t a, uint64_t b)
{
        return a+b;
};
void f1_test ()
{
#ifdef __GNUC__
        printf ("%lld", f1(12345678901234, 23456789012345));
#else
        printf ("%I64d", f1(12345678901234, 23456789012345));
#endif
};
uint64_t f2 (uint64_t a, uint64_t b)
{
        return a-b;
};
```
### 24.2.1 x86

代码 21.1: MSVC 2012 /Ox /Ob1

```
_a$ = 8                                             ; size = 8
_b$ = 16                                            ; size = 8
_f1     PROC
        mov     eax, DWORD PTR _a$[esp-4]
        add     eax, DWORD PTR _b$[esp-4]
        mov     edx, DWORD PTR _a$[esp]
        adc     edx, DWORD PTR _b$[esp]
        ret     0
_f1     ENDP
 
_f1_test    PROC
        push        5461                            ; 00001555H
        push        1972608889                      ; 75939f79H
        push        2874                            ; 00000b3aH
        push        1942892530                      ; 73ce2ff2H
        call        _f1
        push        edx
        push        eax
        push        OFFSET $SG1436 ; ’%I64d’, 0aH, 00H
        call        _printf
        add         esp, 28                         ; 0000001cH
        ret     0
_f1_test    ENDP
_f2     PROC
        mov     eax, DWORD PTR _a$[esp-4]
        sub     eax, DWORD PTR _b$[esp-4]
        mov     edx, DWORD PTR _a$[esp]
        sbb     edx, DWORD PTR _b$[esp]
        ret     0
_f2     ENDP
```

我们可以看到在函数f1_test()中每个64位值转化为2个32位值，高位先转，然后是低位。加法和减法也是如此。

当进行加法操作时，低32位部分先做加法。如果相加过程中产生进位，则设置CF标志。下一步通过ADC指令加上高位部分，如果CF置1了就增加1。

减法操作也是如此。第一个SUB操作也会导致CF标志的改变，并在随后的SBB操作中检查：如果CF置1了，那么最终结果也会减去1。

在32位环境中，64位的值是从EDX:EAX这一对寄存器的函数中返回的。可以很容易看出f1()函数是如何转化为printf()函数的。

代码 21.2: GCC 4.8.1 -O1 -fno-inline

```
_f1:
        mov     eax, DWORD PTR [esp+12]
        mov     edx, DWORD PTR [esp+16]
        add     eax, DWORD PTR [esp+4]
        adc     edx, DWORD PTR [esp+8]
        ret

_f1_test:
        sub     esp, 28
        mov     DWORD PTR [esp+8], 1972608889           ; 75939f79H
        mov     DWORD PTR [esp+12], 5461                ; 00001555H
        mov     DWORD PTR [esp], 1942892530             ; 73ce2ff2H
        mov     DWORD PTR [esp+4], 2874                 ; 00000b3aH
        call    _f1
        mov     DWORD PTR [esp+4], eax
        mov     DWORD PTR [esp+8], edx
        mov     DWORD PTR [esp], OFFSET FLAT:LC0        ; "%lld12"
        call    _printf
        add     esp, 28
        ret

_f2:
        mov     eax, DWORD PTR [esp+4]
        mov     edx, DWORD PTR [esp+8]
        sub     eax, DWORD PTR [esp+12]
        sbb     edx, DWORD PTR [esp+16]
        ret
```
GCC代码也是如此。

### 24.2.2 ARM

### 24.2.3 MIPS


## 21.2 乘法，除法

```
#include <stdint.h>
uint64_t f3 (uint64_t a, uint64_t b)
{
        return a*b;
};
uint64_t f4 (uint64_t a, uint64_t b)
{
        return a/b;
};
uint64_t f5 (uint64_t a, uint64_t b)
{
        return a % b;
};
```

### 24.3.1 x86

代码 21.3: MSVC 2012 /Ox /Ob1

```
_a$ = 8                                     ; size = 8
_b$ = 16                                    ; size = 8
_f3     PROC
        push        DWORD PTR _b$[esp]
        push        DWORD PTR _b$[esp]
        push        DWORD PTR _a$[esp+8]
        push        DWORD PTR _a$[esp+8]
        call        __allmul ; long long multiplication
        ret         0
_f3     ENDP
_a$ = 8                                     ; size = 8
_b$ = 16                                    ; size = 8
_f4     PROC
        push        DWORD PTR _b$[esp]
        push        DWORD PTR _b$[esp]
        push        DWORD PTR _a$[esp+8]
        push        DWORD PTR _a$[esp+8]
        call        __aulldiv ; unsigned long long division
        ret         0
_f4     ENDP
_a$ = 8                                     ; size = 8
_b$ = 16                                    ; size = 8
_f5     PROC
        push        DWORD PTR _b$[esp]
        push        DWORD PTR _b$[esp]
        push        DWORD PTR _a$[esp+8]
        push        DWORD PTR _a$[esp+8]
        call        __aullrem ; unsigned long long remainder
        ret         0
_f5     ENDP
```

乘法和除法是更为复杂的操作，一般来说，编译器会嵌入库函数的calls来使用。

部分函数的意义：可参见附录E。

Listing 21.4: GCC 4.8.1 -O3 -fno-inline

```
_f3:
        push        ebx
        mov         edx, DWORD PTR [esp+8]
        mov         eax, DWORD PTR [esp+16]
        mov         ebx, DWORD PTR [esp+12]
        mov         ecx, DWORD PTR [esp+20]
        imul        ebx, eax
        imul        ecx, edx
        mul         edx
        add         ecx, ebx
        add         edx, ecx
        pop         ebx
        ret
_f4:
        sub         esp, 28
        mov         eax, DWORD PTR [esp+40]
        mov         edx, DWORD PTR [esp+44]
        mov         DWORD PTR [esp+8], eax
        mov         eax, DWORD PTR [esp+32]
        mov         DWORD PTR [esp+12], edx
        mov         edx, DWORD PTR [esp+36]
        mov         DWORD PTR [esp], eax
        mov         DWORD PTR [esp+4], edx
        call        ___udivdi3 ; unsigned division
        add         esp, 28
        ret
_f5:
        sub         esp, 28
        mov         eax, DWORD PTR [esp+40]
        mov         edx, DWORD PTR [esp+44]
        mov         DWORD PTR [esp+8], eax
        mov         eax, DWORD PTR [esp+32]
        mov         DWORD PTR [esp+12], edx
        mov         edx, DWORD PTR [esp+36]
        mov         DWORD PTR [esp], eax
        mov         DWORD PTR [esp+4], edx
        call        ___umoddi3 ; unsigned modulo
        add         esp, 28
        ret
```

GCC的做法几乎一样，但是乘法代码内联在函数中，可认为这样更有效。

GCC有一些不同的库函数：参见附录D

### 24.3.2 ARM

### 24.3.3 MIPS

## 21.3 右位移

```
#include <stdint.h>
uint64_t f6 (uint64_t a)
{
        return a>>7;
};
```

### 24.4.1 x86

代码 21.5: MSVC 2012 /Ox /Ob1

```
_a$ = 8                                     ; size = 8
_f6     PROC
        mov     eax, DWORD PTR _a$[esp-4]
        mov     edx, DWORD PTR _a$[esp]
        shrd    eax, edx, 7
        shr     edx, 7
        ret     0
_f6     ENDP
```

代码 21.6: GCC 4.8.1 -O3 -fno-inline

```
_f6:
        mov     edx, DWORD PTR [esp+8]
        mov     eax, DWORD PTR [esp+4]
        shrd        eax, edx, 7
        shr     edx, 7
        ret
```

右移也是分成两步完成：先移低位，然后移高位。但是低位部分通过指令SHRD移动，它将EDX的值移动7位，并从EAX借来1位，也就是从高位部分。而高位部分通过更受欢迎的指令SHR移动：的确，高位释放出来的位置用0填充。

### 24.4.2 ARM

### 24.4.3 MIPS

## 24.5从32位值转化为64位值

### 24.5.1 x86

### 24.5.2 ARM

### 24.5.3 MIPS
```
#include <stdint.h>
int64_t f7 (int64_t a, int64_t b, int32_t c)
{
        return a*b+c;
};

int64_t f7_main ()
{
        return f7(12345678901234, 23456789012345, 12345);
};
```


代码 21.7: MSVC 2012 /Ox /Ob1

```
_a$ = 8                                 ; size = 8
_b$ = 16                                ; size = 8
_c$ = 24                                ; size = 4
_f7     PROC
        push        esi
        push        DWORD PTR _b$[esp+4]
        push        DWORD PTR _b$[esp+4]
        push        DWORD PTR _a$[esp+12]
        push        DWORD PTR _a$[esp+12]
        call        __allmul ; long long multiplication
        mov         ecx, eax
        mov         eax, DWORD PTR _c$[esp]
        mov         esi, edx
        cdq                 ; input: 32-bit value in EAX; output: 64-bit value in EDX:EAX
        add         eax, ecx
        adc         edx, esi
        pop         esi
        ret         0
_f7     ENDP
 
_f7_main PROC
        push        12345               ; 00003039H
        push        5461                ; 00001555H
        push        1972608889          ; 75939f79H
        push        2874                ; 00000b3aH
        push        1942892530          ; 73ce2ff2H
        call        _f7
        add     esp, 20                 ; 00000014H
        ret     0
_f7_main ENDP
```

这里我们有必要将有符号的32位值从c转化为有符号的64位值。无符号值的转化简单了当：所有的高位部分全部置0。但是这样不适合有符号的数据类型：符号标志应复制到结果中的高位部分。这里用到的指令是CDQ，它从EAX中取出数值，将其变为64位并存放到EDX:EAX这一对寄存器中。换句话说，指令CDQ从EAX中获取符号（通过EAX中最重要的位），并根据它来设置EDX中所有位为0还是为1。它的操作类似于指令MOVSX（13.1.1）。

代码 21.8: GCC 4.8.1 -O3 -fno-inline

```
_f7:
        push        edi
        push        esi
        push        ebx
        mov         esi, DWORD PTR [esp+16]
        mov         edi, DWORD PTR [esp+24]
        mov         ebx, DWORD PTR [esp+20]
        mov         ecx, DWORD PTR [esp+28]
        mov         eax, esi
        mul         edi
        imul        ebx, edi
        imul        ecx, esi
        mov         esi, edx
        add         ecx, ebx
        mov         ebx, eax
        mov         eax, DWORD PTR [esp+32]
        add         esi, ecx
        cdq             ; input: 32-bit value in EAX; output: 64-bit value in EDX:EAX
        add         eax, ebx
        adc         edx, esi
        pop         ebx
        pop         esi
        pop         edi
        ret
_f7_main:
        sub         esp, 28
        mov         DWORD PTR [esp+16], 12345               ; 00003039H
        mov         DWORD PTR [esp+8], 1972608889           ; 75939f79H
        mov         DWORD PTR [esp+12], 5461                ; 00001555H
        mov         DWORD PTR [esp], 1942892530             ; 73ce2ff2H
        mov         DWORD PTR [esp+4], 2874                 ; 00000b3aH
        call
_f7
        add         esp, 28
        ret
```

GCC生成的汇编代码跟MSVC一样，但是在函数中内联乘法代码。 更多：32位值在16位环境中（30.4）