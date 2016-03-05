# SIMD

SIMD是Single Instruction, Multiple Data的首字母。简单说就是单指令多数据流。

就像FPU，FPU看起来更像独立于x86处理器。

SIMD开始于MMX x86。8个新的64位寄存器MM0-MM7被添加。

每个MMX寄存器包含2个32-bit值/4个16-bit值/8字节。比如可以通过一次添加两个值到MMX寄存器来添加8个8-bit（字节）。

一个简单的例子就是图形编辑器，将图像表示为一个二维数组，当用户改变图像的亮度，编辑器必须添加每个像素的差值。为了简单起见，将每个像素定义为一个8位字节，就可以同时改变8个像素的亮度。

当使用MMX的时候，这些寄存器实际上位于FPU寄存器。所以可以同时使用FPU和MMX寄存器。有人可能会认为，intel基于晶体管保存，事实上，这种共生关系的原因是：老的操作系统不知道额外的CPU寄存器，上下文切换是不会保存这些寄存器，可以节省FPU寄存器。这样激活MMX的CPU+旧的操作系统+利用MMX特性的处理器=所有一起工作。

SSE-SIMD寄存器扩展至128bits，独立于FPU。

AVX-另一种256bits扩展。

实际应用还包括内存复制(memcpy)和内存比较(memcmp)等等。

一个例子是：DES加密算法需要64-bits block，56-bits key,加密块生成64位结果。DES算法可以认为是一个非常大的电子电路，带有网格和AND/OR/NOT门。

Bitslice DES2—可以同时处理块和密钥。比如说unsigned int类型变量在X86下可以容纳32位，因此，使用64+56 unsigned int类型的变量，可以同时存储32个blocks-keys对。

我写了一个爆破Oracle RDBMS密码/哈希（基于DES）的工具。稍微修改了DES算法（SSE2和AVX）现在可以同时加密128或256block-keys对。

[http://conus.info/utils/ops_SIMD/](http://conus.info/utils/ops_SIMD/)

## 22.1 Vectorization

向量化3，例如循环用两个数组生成一个数组。循环体从输入数组中取值，处理后存储到另一个数组。重要的一点是操作了每一个元素。向量化—同时处理多个元素。

向量化并不是新的技术：本书的作者在1998年使用Cray Y-MP EL“lite”时从Cray Y-MP supercomputer line看到过。

例子：

```
for (i = 0; i < 1024; i++)
{
    C[i] = A[i]*B[i];
}
```

这段代码从A和B中取出元素，相乘，并把结果保存到C。

如果每个元素为32位int型，那么可以从A中加载4个元素到128bits XMM寄存器，B加载到另一个XMM寄存器，通过执行PMULID（Multiply Packed Signed Dword Integers and Store Low Result）和PMULHW(Multiply Packed Signed Integers and Store High Result)，一次可以得到4个64位结果。

循环次数从1024变成1024/4，当然更快。

一些简单的情况下某些编译器可以自动向量化，Intel C++5.

函数如下：

```
int f (int sz, int *ar1, int *ar2, int *ar3)
{
        for (int i=0; i<sz; i++)
                ar3[i]=ar1[i]+ar2[i];
        return 0;
};
```

### 22.1.1 Intel C++

Intel C++ 11.1.051 win32下编译：

`icl intel.cpp /QaxSSE2 /Faintel.asm /Ox`

可以得到(IDA中):

```
; int __cdecl f(int, int *, int *, int *)
                public ?f@@YAHHPAH00@Z
?f@@YAHHPAH00@Z proc near

var_10          = dword ptr -10h
sz              = dword ptr 4
ar1             = dword ptr 8
ar2             = dword ptr 0Ch
ar3             = dword ptr 10h
                push    edi
                push    esi
                push    ebx
                push    esi
                mov     edx, [esp+10h+sz]
                test    edx, edx
                jle     loc_15B
                mov     eax, [esp+10h+ar3]
                cmp     edx, 6
                jle     loc_143
                cmp     eax, [esp+10h+ar2]
                jbe     short loc_36
                mov     esi, [esp+10h+ar2]
                sub     esi, eax
                lea     ecx, ds:0[edx*4]
                neg     esi
                cmp     ecx, esi
                jbe     short loc_55
 
loc_36:                                         ; CODE XREF: f(int,int *,int *,int *)+21
                cmp     eax, [esp+10h+ar2]
                jnb     loc_143
                mov     esi, [esp+10h+ar2]
                sub     esi, eax
                lea     ecx, ds:0[edx*4]
                cmp     esi, ecx
                jb      loc_143
loc_55: ; CODE XREF: f(int,int *,int *,int *)+34
                cmp     eax, [esp+10h+ar1]
                jbe     short loc_67
                mov     esi, [esp+10h+ar1]
                sub     esi, eax
                neg     esi
                cmp     ecx, esi
                jbe     short loc_7F
 
loc_67:                                          ; CODE XREF: f(int,int *,int *,int *)+59
                cmp     eax, [esp+10h+ar1]
                jnb     loc_143
                mov     esi, [esp+10h+ar1]
                sub     esi, eax
                cmp     esi, ecx
                jb      loc_143
 
loc_7F:                                          ; CODE XREF: f(int,int *,int *,int *)+65
                mov     edi, eax ; edi = ar1
                and     edi, 0Fh ; is ar1 16-byte aligned?
                jz      short loc_9A ; yes
                test    edi, 3
                jnz     loc_162
                neg     edi
                add     edi, 10h
                shr     edi, 2
 
loc_9A:                                          ; CODE XREF: f(int,int *,int *,int *)+84
                lea     ecx, [edi+4]
                cmp     edx, ecx
                jl      loc_162
                mov     ecx, edx
                sub     ecx, edi
                and     ecx, 3
                neg     ecx
                add     ecx, edx
                test    edi, edi
                jbe     short loc_D6
                mov     ebx, [esp+10h+ar2]
                mov     [esp+10h+var_10], ecx
                mov     ecx, [esp+10h+ar1]
                xor     esi, esi
 
loc_C1:                                          ; CODE XREF: f(int,int *,int *,int *)+CD
                mov     edx, [ecx+esi*4]
                add     edx, [ebx+esi*4]
                mov     [eax+esi*4], edx
                inc     esi
                cmp     esi, edi
                jb      short loc_C1
                mov     ecx, [esp+10h+var_10]
                mov     edx, [esp+10h+sz]
 
loc_D6:                                           ; CODE XREF: f(int,int *,int *,int *)+B2
                mov     esi, [esp+10h+ar2]
                lea     esi, [esi+edi*4] ; is ar2+i*4 16-byte aligned?
                test    esi, 0Fh
                jz      short loc_109 ; yes!
                mov     ebx, [esp+10h+ar1]
                mov     esi, [esp+10h+ar2]
 
loc_ED:                                           ; CODE XREF: f(int,int *,int *,int *)+105
                movdqu  xmm1, xmmword ptr [ebx+edi*4]
                movdqu  xmm0, xmmword ptr [esi+edi*4] ; ar2+i*4 is not 16-byte aligned, so load
                it to   xmm0
                paddd   xmm1, xmm0
                movdqa  xmmword ptr [eax+edi*4], xmm1
                add     edi, 4
                cmp     edi, ecx
                jb      short loc_ED
                jmp     short loc_127
; ---------------------------------------------------------------------------
loc_109:                                          ; CODE XREF: f(int,int *,int *,int *)+E3
                mov     ebx, [esp+10h+ar1]
                mov     esi, [esp+10h+ar2]
loc_111:                                          ; CODE XREF: f(int,int *,int *,int *)+125
                movdqu  xmm0, xmmword ptr [ebx+edi*4]
                paddd   xmm0, xmmword ptr [esi+edi*4]
                movdqa  xmmword ptr [eax+edi*4], xmm0
                add     edi, 4
                cmp     edi, ecx
                jb      short loc_111
 
loc_127:                                          ; CODE XREF: f(int,int *,int *,int *)+107
                                                  ; f(int,int *,int *,int *)+164
                cmp     ecx, edx
                jnb     short loc_15B
                mov     esi, [esp+10h+ar1]
                mov     edi, [esp+10h+ar2]
 
loc_133: ; CODE XREF: f(int,int *,int *,int *)+13F
                mov     ebx, [esi+ecx*4]
                add     ebx, [edi+ecx*4]
                mov     [eax+ecx*4], ebx
                inc     ecx
                cmp     ecx, edx
                jb      short loc_133
                jmp     short loc_15B
; ---------------------------------------------------------------------------
loc_143:                                          ; CODE XREF: f(int,int *,int *,int *)+17
                                                  ; f(int,int *,int *,int *)+3A ...
                mov     esi, [esp+10h+ar1]
                mov     edi, [esp+10h+ar2]
                xor     ecx, ecx
 
loc_14D:                                          ; CODE XREF: f(int,int *,int *,int *)+159
                mov     ebx, [esi+ecx*4]
                add     ebx, [edi+ecx*4]
                mov     [eax+ecx*4], ebx
                inc     ecx
                cmp     ecx, edx
                jb      short loc_14D
 
loc_15B:                                          ; CODE XREF: f(int,int *,int *,int *)+A
                                                  ; f(int,int *,int *,int *)+129 ...
                xor     eax, eax
                pop     ecx
                pop     ebx
                pop     esi
                pop     edi
                retn
; ---------------------------------------------------------------------------
loc_162:                                           ; CODE XREF: f(int,int *,int *,int *)+8C
                                                   ; f(int,int *,int *,int *)+9F
                xor     ecx, ecx
                jmp     short loc_127
?f@@YAHHPAH00@Z endp
```

SSE2相关指令是：

```
MOVDQU (Move Unaligned Double Quadword)—仅仅从内存加载16个字节到XMM寄存器。
PADDD (Add Packed Integers)—把源存储器与目的寄存器按双字对齐无符号整数普通相加,结果送入目的寄存器,内存变量必须对齐内存16字节.
MOVDQA (Move Aligned Double Quadword)—把源存储器内容值送入目的寄存器,当有m128时,必须对齐内存16字节.
```

如果工作元素超过4对，并且指针ar3按照16字节对齐，SSE2指令将被执行： 如果ar2按照16字节对齐，则代码如下：

```
movdqu  xmm0, xmmword ptr [ebx+edi*4] ; ar1+i*4
paddd   xmm0, xmmword ptr [esi+edi*4] ; ar2+i*4
movdqa  xmmword ptr [eax+edi*4], xmm0 ; ar3+i*4
```

否则,ar2处的值将用MOVDQU加载到XMM0，它不需要对齐指针，代码如下：

```
movdqu  xmm1, xmmword ptr [ebx+edi*4] ; ar1+i*4
movdqu  xmm0, xmmword ptr [esi+edi*4] ; ar2+i*4 is not 16-byte aligned, so load it to xmm0
paddd   xmm1, xmm0
movdqa  xmmword ptr [eax+edi*4], xmm1 ; ar3+i*4
```

其他情况，将没有SSE2代码被执行。

### 22.1.2 GCC

gcc用-O3 选项同时打开SSE2支持: -msse2.

可以得到(GCC 4.4.1):

```
; f(int, int *, int *, int *)
                public _Z1fiPiS_S_
_Z1fiPiS_S_     proc near
 
var_18          = dword ptr -18h
var_14          = dword ptr -14h
var_10          = dword ptr -10h
arg_0           = dword ptr 8
arg_4           = dword ptr 0Ch
arg_8           = dword ptr 10h
arg_C           = dword ptr 14h
                push    ebp
                mov     ebp, esp
                push    edi
                push    esi
                push    ebx
                sub     esp, 0Ch
                mov     ecx, [ebp+arg_0]
                mov     esi, [ebp+arg_4]
                mov     edi, [ebp+arg_8]
                mov     ebx, [ebp+arg_C]
                test    ecx, ecx
                jle     short loc_80484D8
                cmp     ecx, 6
                lea     eax, [ebx+10h]
                ja      short loc_80484E8
 
loc_80484C1:                    ; CODE XREF: f(int,int *,int *,int *)+4B
                                ; f(int,int *,int *,int *)+61 ...
                xor     eax, eax
                nop
                lea     esi, [esi+0]
loc_80484C8:                    ; CODE XREF: f(int,int *,int *,int *)+36
                mov     edx, [edi+eax*4]
                add     edx, [esi+eax*4]
                mov     [ebx+eax*4], edx
                add     eax, 1
                cmp     eax, ecx
                jnz     short loc_80484C8
 
loc_80484D8:                    ; CODE XREF: f(int,int *,int *,int *)+17
                                ; f(int,int *,int *,int *)+A5
                add     esp, 0Ch
                xor     eax, eax
                pop     ebx
                pop     esi
                pop     edi
                pop     ebp
                retn
; ---------------------------------------------------------------------------
                align 8
loc_80484E8:                    ; CODE XREF: f(int,int *,int *,int *)+1F
                test    bl, 0Fh
                jnz     short loc_80484C1
                lea     edx, [esi+10h]
                cmp     ebx, edx
                jbe     loc_8048578
 
loc_80484F8:                    ; CODE XREF: f(int,int *,int *,int *)+E0
                lea     edx, [edi+10h]
                cmp     ebx, edx
                ja      short loc_8048503
                cmp     edi, eax
                jbe     short loc_80484C1
 
loc_8048503:                    ; CODE XREF: f(int,int *,int *,int *)+5D
                mov     eax, ecx
                shr     eax, 2
                mov     [ebp+var_14], eax
                shl     eax, 2
                test    eax, eax
                mov     [ebp+var_10], eax
                jz      short loc_8048547
                mov     [ebp+var_18], ecx
                mov     ecx, [ebp+var_14]
                xor     eax, eax
                xor     edx, edx
                nop
 
loc_8048520:                    ; CODE XREF: f(int,int *,int *,int *)+9B
                movdqu  xmm1, xmmword ptr [edi+eax]
                movdqu  xmm0, xmmword ptr [esi+eax]
                add     edx, 1
                paddd   xmm0, xmm1
                movdqa  xmmword ptr [ebx+eax], xmm0
                add     eax, 10h
                cmp     edx, ecx
                jb      short loc_8048520
                mov     ecx, [ebp+var_18]
                mov     eax, [ebp+var_10]
                cmp     ecx, eax
                jz      short loc_80484D8
 
loc_8048547:                    ; CODE XREF: f(int,int *,int *,int *)+73
                lea     edx, ds:0[eax*4]
                add     esi, edx
                add     edi, edx
                add     ebx, edx
                lea     esi, [esi+0]
 
loc_8048558:                    ; CODE XREF: f(int,int *,int *,int *)+CC
                mov     edx, [edi]
                add     eax, 1
                add     edi, 4
                add     edx, [esi]
                add     esi, 4
                mov     [ebx], edx
                add     ebx, 4
                cmp     ecx, eax
                jg      short loc_8048558
                add     esp, 0Ch
                xor     eax, eax
                pop     ebx
                pop     esi
                pop     edi
                pop     ebp
                retn
; ---------------------------------------------------------------------------
loc_8048578:                    ; CODE XREF: f(int,int *,int *,int *)+52
                cmp     eax, esi
                jnb     loc_80484C1
                jmp     loc_80484F8
_Z1fiPiS_S_     endp
```

几乎一样，但没有Intel的细致。

## 22.2 SIMD strlen() implementation

SIMD指令可能通过特殊的宏8插入到C/C++代码中。MSVC中他们被保存在intrin.h中。

Strlen()函数9的实现使用了SIMD指令，比常规的实现快了2-2.5倍。该函数将16个字符加载到一个XMM寄存器并检查是否为零

```
size_t strlen_sse2(const char *str)
{
        register size_t len = 0;
        const char *s=str;
        bool str_is_aligned=(((unsigned int)str)&0xFFFFFFF0) == (unsigned int)str;

        if (str_is_aligned==false)
                return strlen (str);

        __m128i xmm0 = _mm_setzero_si128();
        __m128i xmm1;
        int mask = 0;

        for (;;)
        {
                xmm1 = _mm_load_si128((__m128i *)s);
                xmm1 = _mm_cmpeq_epi8(xmm1, xmm0);
                if ((mask = _mm_movemask_epi8(xmm1)) != 0)
                {
                        unsigned long pos;
                        _BitScanForward(&pos, mask);
                        len += (size_t)pos;
                        break;
                }
                s += sizeof(__m128i);
                len += sizeof(__m128i);
        };

        return len;
}
```

(这里的例子基于源代码).

MSVC 2010 /Ox 编译选项:

```
_pos$75552 = -4                 ; size = 4
_str$ = 8                       ; size = 4
?strlen_sse2@@YAIPBD@Z PROC     ; strlen_sse2
 
    push    ebp
    mov     ebp, esp
    and     esp, -16 ; fffffff0H
    mov     eax, DWORD PTR _str$[ebp]
    sub     esp, 12 ; 0000000cH
    push    esi
    mov     esi, eax
    and     esi, -16 ; fffffff0H
    xor     edx, edx
    mov     ecx, eax
    cmp     esi, eax
    je      SHORT $LN4@strlen_sse
    lea     edx, DWORD PTR [eax+1]
    npad    3
$LL11@strlen_sse:
    mov     cl, BYTE PTR [eax]
    inc     eax
    test    cl, cl
    jne     SHORT $LL11@strlen_sse
    sub     eax, edx
    pop     esi
    mov     esp, ebp
    pop     ebp
    ret     0
$LN4@strlen_sse:
    movdqa  xmm1, XMMWORD PTR [eax]
    pxor    xmm0, xmm0
    pcmpeqb         xmm1, xmm0
    pmovmskb        eax, xmm1
    test    eax, eax
    jne     SHORT $LN9@strlen_sse
$LL3@strlen_sse:
    movdqa  xmm1, XMMWORD PTR [ecx+16]
    add     ecx, 16 ; 00000010H
    pcmpeqb         xmm1, xmm0
    add     edx, 16 ; 00000010H
    pmovmskb        eax, xmm1
    test    eax, eax
    je      SHORT $LL3@strlen_sse
$LN9@strlen_sse:
    bsf     eax, eax
    mov     ecx, eax
    mov     DWORD PTR _pos$75552[esp+16], eax
    lea     eax, DWORD PTR [ecx+edx]
    pop     esi
    mov     esp, ebp
    pop     ebp
    ret     0
?strlen_sse2@@YAIPBD@Z ENDP ; strlen_sse2
```

首先，检查str指针，如果不是按照16字节对齐则调用常规实现。

然后使用movdqa指令加载16个字节到xmm1.这里不使用movdqu的原因是如果指针不一致则从内存中加载的数据可能会不一致。

是的，它可能会以这种方式做，如果指针对齐，使用MOVDQA加载数据，否则使用比较慢的MOVDQU。

但是我们应该注意到这样的警告：

在windowsNT操作系统但不限于该操作系统，内存页按4kb对齐。每个win32进程独占4GB虚拟内存。事实上，只有部分地址空间与真实物理内存对应，如果进程访问的内存没有对应物理内存，将触发异常。这是虚拟内存的工作方式10.

一个函数一次加载16个字节，可能会跨内存分块访问。我们考虑这样一种情况，操作系统在x008c0000分配8192（0x2000）字节,因此块字节从地质0x008c0000到0x008c1fff。 内存块之后从0x008c2000什么都没有，操作系统没有分配任何内存。访问该地址将触发异常。

假如内存块包含的最后5个字符如下：

```
0x008c1ff8      ’h’
0x008c1ff9      ’e’
0x008c1ffa      ’l’
0x008c1ffb      ’l’
0x008c1ffc      ’o’
0x008c1ffd      ’x00’
0x008c1ffe      random noise
0x008c1fff      random noise
```

正常情况下，strlen()只会读取到”hello”。

如果我们使用MOVDQU读取16个字节，将会触发异常，应该避免这种情况。

因为我们要确保16字节对齐，保证我们不会读取未分配的内存。

让我们回到函数：

```
_mm_setzero_si128()—宏pxor xmm0, xmm0—清空XMM0寄存器。
_mm_load_si128()—宏 MOVDQA, 从内存加载16个字节到XMM寄存器。
_mm_cmpeq_epi8()—宏PCMPEQB,比较XMM寄存器的字节位，如果相等则为0xff否则为0。
```

比如：

```
XMM1: 11223344556677880000000000000000
XMM0: 11ab3444007877881111111111111111
```

执行pcmpeqb xmm1, xmm0之后，XMM1寄存器的值为：

`XMM1: ff0000ff0000ffff0000000000000000`

在本例中该指令比较每一个16字节块与16字节0字节块对比，XMM0通过pxor xmm0 xmm0置零。

接下来宏_mm_movemask_epi8() —这是PMOVMSKB指令。

`pmovmskb eax, xmm1`

pmovmskb创建源操作数每一个字节的自高位掩码，并保存结果到目的操作数的低byte。源操作数必须为MMX寄存器，目的操作数必须为32位通用寄存器。

比如：

`XMM1: 0000ff00000000000000ff0000000000`

对应的EAX：

`EAX=0010000000100000b`

之后bsf eax,eax被执行，eax值为5，意味着第一个是1的位置是5（从0开始）。

MSVC关于这个指令的宏是：_BitScanForward.

至此，找到结尾0的位置，然后程序返回长度计数。

整个过程大致就是这样。

顺便提一下，MSVC为了优化，使用了两个并排的循环。

SSE 4.2(英特尔core i7)提供了更多的指令,这些可能更容易字符串操作。

[http://www.strchr.com/strcmp_and_strlen_using_sse_4.2](http://www.strchr.com/strcmp_and_strlen_using_sse_4.2)