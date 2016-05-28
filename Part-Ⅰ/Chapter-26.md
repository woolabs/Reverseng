# 第二十六章
# 64位化

## 26.1 x86-64

对x86架构来说这是一个64位的扩展。 从反编译工程师的角度来看，最重要的区别是： 几乎所有的寄存器（除了FPU和SIMD）都扩展到了64位，而且都有一个r-前缀，而且还额外添加了8个寄存器。 现在所有的通用寄存器是：RAX、RBX、RCX、RDX、RBP、RSP、RSI、RDI、R8、R9、R10、R11、R12、R13、R14、R15。 当然，还是可以像以前一样加载旧的寄存器的。比如，使用EAX就可以访问RAX的低32位部分。 新的R8-R15寄存器也有对应的低位：R8D-R15D（低32位）、R8W-R15W（低16位）、R8B-R15B（低8位）。 SIMD寄存器的数量从8个扩展到了16个：XMM0-XMM15。

在Win64下，函数调用转换有一些轻微的变化。例如fastcall（见47.3节）。最开始的4个参数将存储在RCX、RDX、R8和R9寄存器里，其他的保存在栈上。调用者函数必须分配32个字节，因此被调用者可以保存前4个参数，然后再去按照他自己的需要去利用这些寄存器。一些较短的函数可以直接从寄存器里使用参数，但是大点的函数就需要把参数保存到栈上了。 系统V AMD64 ABI（LINUX, *BSD, MAC OS X）也改变了fastcall的方式。它为前6个参数使用了6个寄存器RDI、RSI、RDX、RCX、R8、R9。剩余的参数将传入栈中。 请看调用转换（47）一节。

为了保证兼容性，C int类型依然是32位。 •现在所有的指针都是64位的了。 当然这个有时候很麻烦：因为现在我们需要2倍的空间来存储指针，包括缓存，而不管事实上64位CPU只会使用48位的扩展内存这个情况。

由于现在寄存器数量翻倍了，编译器也将有更多的空间来处理寄存器分配的策略。对我们来说，也就是现在提交的代码将会有更少的本地变量。 例如，DES加密算法中计算第一个S-Box时，使用位切割DES方法（见22章）他将每次处理32/64/128/256个变量（依据DES_type类型（uint32、uint64、SSE2或者AVX））。

```
/*
* Generated S-box files.
*
* This software may be modified, redistributed, and used for any purpose,
* so long as its origin is acknowledged.
*
* Produced by Matthew Kwan - March 1998
*/
#ifdef _WIN64
#define DES_type unsigned __int64
#else
#define DES_type unsigned int
#endif
void
s1 (
    DES_type a1,
    DES_type a2,
    DES_type a3,
    DES_type a4,
    DES_type a5,
    DES_type a6,
    DES_type *out1,
    DES_type *out2,
    DES_type *out3,
    DES_type *out4
) {
    DES_type x1, x2, x3, x4, x5, x6, x7, x8;
    DES_type x9, x10, x11, x12, x13, x14, x15, x16;
    DES_type x17, x18, x19, x20, x21, x22, x23, x24;
    DES_type x25, x26, x27, x28, x29, x30, x31, x32;
    DES_type x33, x34, x35, x36, x37, x38, x39, x40;
    DES_type x41, x42, x43, x44, x45, x46, x47, x48;
    DES_type x49, x50, x51, x52, x53, x54, x55, x56;
    x1 = a3 & ~a5;
    x2 = x1 ^ a4;
    x3 = a3 & ~a4;
    x4 = x3 | a5;
    x5 = a6 & x4;
    x6 = x2 ^ x5;
    x7 = a4 & ~a5;
    x8 = a3 ^ a4;
    x9 = a6 & ~x8;
    x10 = x7 ^ x9;
    x11 = a2 | x10;
    x12 = x6 ^ x11;
    x13 = a5 ^ x5;
    x14 = x13 & x8;
    x15 = a5 & ~a4;
    x16 = x3 ^ x14;
    x17 = a6 | x16;
    x18 = x15 ^ x17;
    x19 = a2 | x18;
    x20 = x14 ^ x19;
    x21 = a1 & x20;
    x22 = x12 ^ ~x21;
    *out2 ^= x22;
    x23 = x1 | x5;
    x24 = x23 ^ x8;
    x25 = x18 & ~x2;
    x26 = a2 & ~x25;
    x27 = x24 ^ x26;
    x28 = x6 | x7;
    x29 = x28 ^ x25;
    x30 = x9 ^ x24;
    x31 = x18 & ~x30;
    x32 = a2 & x31;
    x33 = x29 ^ x32;
    x34 = a1 & x33;
    x35 = x27 ^ x34;
    *out4 ^= x35;
    x36 = a3 & x28;
    x37 = x18 & ~x36;
    x38 = a2 | x3;
    x39 = x37 ^ x38;
    x40 = a3 | x31;
    x41 = x24 & ~x37;
    x42 = x41 | x3;
    x43 = x42 & ~a2;
    x44 = x40 ^ x43;
    x45 = a1 & ~x44;
    x46 = x39 ^ ~x45;
    *out1 ^= x46;
    x47 = x33 & ~x9;
    x48 = x47 ^ x39;
    x49 = x4 ^ x36;
    x50 = x49 & ~x5;
    x51 = x42 | x18;
    x52 = x51 ^ a5;
    x53 = a2 & ~x52;
    x54 = x50 ^ x53;
    x55 = a1 | x54;
    x56 = x48 ^ ~x55;
    *out3 ^= x56;
}
```

这儿也有许多本地变量。当然，并不是所有的这些都存在本地栈上。让我们用MSVC2008的/Ox选项来编译一下：

清单23.1 使用MSVC 2008编译

```
PUBLIC _s1
; Function compile flags: /Ogtpy
_TEXT SEGMENT
_x6$ = -20 ; size = 4
_x3$ = -16 ; size = 4
_x1$ = -12 ; size = 4
_x8$ = -8 ; size = 4
_x4$ = -4 ; size = 4
_a1$ = 8 ; size = 4
_a2$ = 12 ; size = 4
_a3$ = 16 ; size = 4
_x33$ = 20 ; size = 4
_x7$ = 20 ; size = 4
_a4$ = 20 ; size = 4
_a5$ = 24 ; size = 4
tv326 = 28 ; size = 4
_x36$ = 28 ; size = 4
_x28$ = 28 ; size = 4
_a6$ = 28 ; size = 4
_out1$ = 32 ; size = 4
_x24$ = 36 ; size = 4
_out2$ = 36 ; size = 4
_out3$ = 40 ; size = 4
_out4$ = 44 ; size = 4
_s1 PROC
    sub esp, 20 ; 00000014H
    mov edx, DWORD PTR _a5$[esp+16]
    push ebx
    mov ebx, DWORD PTR _a4$[esp+20]
    push ebp
    push esi
    mov esi, DWORD PTR _a3$[esp+28]
    push edi
    mov edi, ebx
    not edi
    mov ebp, edi
    and edi, DWORD PTR _a5$[esp+32]
    mov ecx, edx
    not ecx
    and ebp, esi
    mov eax, ecx
    and eax, esi
    and ecx, ebx
    mov DWORD PTR _x1$[esp+36], eax
    xor eax, ebx
    mov esi, ebp
    or esi, edx
    mov DWORD PTR _x4$[esp+36], esi
    and esi, DWORD PTR _a6$[esp+32]
    mov DWORD PTR _x7$[esp+32], ecx
    mov edx, esi
    xor edx, eax
    mov DWORD PTR _x6$[esp+36], edx
    mov edx, DWORD PTR _a3$[esp+32]
    xor edx, ebx
    mov ebx, esi
    xor ebx, DWORD PTR _a5$[esp+32]
    mov DWORD PTR _x8$[esp+36], edx
    and ebx, edx
    mov ecx, edx
    mov edx, ebx
    xor edx, ebp
    or edx, DWORD PTR _a6$[esp+32]
    not ecx
    and ecx, DWORD PTR _a6$[esp+32]
    xor edx, edi
    mov edi, edx
    or edi, DWORD PTR _a2$[esp+32]
    mov DWORD PTR _x3$[esp+36], ebp
    mov ebp, DWORD PTR _a2$[esp+32]
    xor edi, ebx
    and edi, DWORD PTR _a1$[esp+32]
    mov ebx, ecx
    xor ebx, DWORD PTR _x7$[esp+32]
    not edi
    or ebx, ebp
    xor edi, ebx
    mov ebx, edi
    mov edi, DWORD PTR _out2$[esp+32]
    xor ebx, DWORD PTR [edi]
    not eax
    xor ebx, DWORD PTR _x6$[esp+36]
    and eax, edx
    mov DWORD PTR [edi], ebx
    mov ebx, DWORD PTR _x7$[esp+32]
    or ebx, DWORD PTR _x6$[esp+36]
    mov edi, esi
    or edi, DWORD PTR _x1$[esp+36]
    mov DWORD PTR _x28$[esp+32], ebx
    xor edi, DWORD PTR _x8$[esp+36]
    mov DWORD PTR _x24$[esp+32], edi
    xor edi, ecx
    not edi
    and edi, edx
    mov ebx, edi
    and ebx, ebp
    xor ebx, DWORD PTR _x28$[esp+32]
    xor ebx, eax
    not eax
    mov DWORD PTR _x33$[esp+32], ebx
    and ebx, DWORD PTR _a1$[esp+32]
    and eax, ebp
    xor eax, ebx
    mov ebx, DWORD PTR _out4$[esp+32]
    xor eax, DWORD PTR [ebx]
    xor eax, DWORD PTR _x24$[esp+32]
    mov DWORD PTR [ebx], eax
    mov eax, DWORD PTR _x28$[esp+32]
    and eax, DWORD PTR _a3$[esp+32]
    mov ebx, DWORD PTR _x3$[esp+36]
    or edi, DWORD PTR _a3$[esp+32]
    mov DWORD PTR _x36$[esp+32], eax
    not eax
    and eax, edx
    or ebx, ebp
    xor ebx, eax
    not eax
    and eax, DWORD PTR _x24$[esp+32]
    not ebp
    or eax, DWORD PTR _x3$[esp+36]
    not esi
    and ebp, eax
    or eax, edx
    xor eax, DWORD PTR _a5$[esp+32]
    mov edx, DWORD PTR _x36$[esp+32]
    xor edx, DWORD PTR _x4$[esp+36]
    xor ebp, edi
    mov edi, DWORD PTR _out1$[esp+32]
    not eax
    and eax, DWORD PTR _a2$[esp+32]
    not ebp
    and ebp, DWORD PTR _a1$[esp+32]
    and edx, esi
    xor eax, edx
    or eax, DWORD PTR _a1$[esp+32]
    not ebp
    xor ebp, DWORD PTR [edi]
    not ecx
    and ecx, DWORD PTR _x33$[esp+32]
    xor ebp, ebx
    not eax
    mov DWORD PTR [edi], ebp
    xor eax, ecx
    mov ecx, DWORD PTR _out3$[esp+32]
    xor eax, DWORD PTR [ecx]
    pop edi
    pop esi
    xor eax, ebx
    pop ebp
    mov DWORD PTR [ecx], eax
    pop ebx
    add esp, 20 ; 00000014H
    ret 0
_s1 ENDP
```

编译器在本地栈上分配了5个变量。 现在再让我们在MSVC 2008的64位环境中试一试：

清单23.2 使用MSVC 2008编译

```
a1$ = 56
a2$ = 64
a3$ = 72
a4$ = 80
x36$1$ = 88
a5$ = 88
a6$ = 96
out1$ = 104
out2$ = 112
out3$ = 120
out4$ = 128
s1 PROC
    $LN3:
    mov QWORD PTR [rsp+24], rbx
    mov QWORD PTR [rsp+32], rbp
    mov QWORD PTR [rsp+16], rdx
    mov QWORD PTR [rsp+8], rcx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    mov r15, QWORD PTR a5$[rsp]
    mov rcx, QWORD PTR a6$[rsp]
    mov rbp, r8
    mov r10, r9
    mov rax, r15
    mov rdx, rbp
    not rax
    xor rdx, r9
    not r10
    mov r11, rax
    and rax, r9
    mov rsi, r10
    mov QWORD PTR x36$1$[rsp], rax
    and r11, r8
    and rsi, r8
    and r10, r15
    mov r13, rdx
    mov rbx, r11
    xor rbx, r9
    mov r9, QWORD PTR a2$[rsp]
    mov r12, rsi
    or r12, r15
    not r13
    and r13, rcx
    mov r14, r12
    and r14, rcx
    mov rax, r14
    mov r8, r14
    xor r8, rbx
    xor rax, r15
    not rbx
    and rax, rdx
    mov rdi, rax
    xor rdi, rsi
    or rdi, rcx
    xor rdi, r10
    and rbx, rdi
    mov rcx, rdi
    or rcx, r9
    xor rcx, rax
    mov rax, r13
    xor rax, QWORD PTR x36$1$[rsp]
    and rcx, QWORD PTR a1$[rsp]
    or rax, r9
    not rcx
    xor rcx, rax
    mov rax, QWORD PTR out2$[rsp]
    xor rcx, QWORD PTR [rax]
    xor rcx, r8
    mov QWORD PTR [rax], rcx
    mov rax, QWORD PTR x36$1$[rsp]
    mov rcx, r14
    or rax, r8
    or rcx, r11
    mov r11, r9
    xor rcx, rdx
    mov QWORD PTR x36$1$[rsp], rax
    mov r8, rsi
    mov rdx, rcx
    xor rdx, r13
    not rdx
    and rdx, rdi
    mov r10, rdx
    and r10, r9
    xor r10, rax
    xor r10, rbx
    not rbx
    and rbx, r9
    mov rax, r10
    and rax, QWORD PTR a1$[rsp]
    xor rbx, rax
    mov rax, QWORD PTR out4$[rsp]
    xor rbx, QWORD PTR [rax]
    xor rbx, rcx
    mov QWORD PTR [rax], rbx
    mov rbx, QWORD PTR x36$1$[rsp]
    and rbx, rbp
    mov r9, rbx
    not r9
    and r9, rdi
    or r8, r11
    mov rax, QWORD PTR out1$[rsp]
    xor r8, r9
    not r9
    and r9, rcx
    or rdx, rbp
    mov rbp, QWORD PTR [rsp+80]
    or r9, rsi
    xor rbx, r12
    mov rcx, r11
    not rcx
    not r14
    not r13
    and rcx, r9
    or r9, rdi
    and rbx, r14
    xor r9, r15
    xor rcx, rdx
    mov rdx, QWORD PTR a1$[rsp]
    not r9
    not rcx
    and r13, r10
    and r9, r11
    and rcx, rdx
    xor r9, rbx
    mov rbx, QWORD PTR [rsp+72]
    not rcx
    xor rcx, QWORD PTR [rax]
    or r9, rdx
    not r9
    xor rcx, r8
    mov QWORD PTR [rax], rcx
    mov rax, QWORD PTR out3$[rsp]
    xor r9, r13
    xor r9, QWORD PTR [rax]
    xor r9, r8
    mov QWORD PTR [rax], r9
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    ret 0
s1 ENDP
```

编译器在栈上并没有分配任何内存空间，x36是a5的同义词。 顺带一提，我们可以在这儿看到的是，函数在调用者空间中保存了RCX和RDX，但是R8和R9虽然在一开始就使用了，但是却并没有保存。 还有，还有拥有更多GPR的CPU，比如Itanium（有128个寄存器）。

## 26.2 ARM

在ARM中，64位指令在ARMv8中才开始出现。

## 26.3 浮点数字

见24章以了解更多的x86-64处理器中是如何处理浮点数的。