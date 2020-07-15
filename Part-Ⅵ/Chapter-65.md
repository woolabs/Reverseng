# 第六十五章 
# 线程局部存储

TLS是每个线程特有的数据区域，每个线程可以把自己需要的数据存储在这里。一个著名的例子是C标准的全局变量errno。多个线程可以同时使用errno获取返回的错误码，如果是全局变量它是无法在多线程环境下正常工作的。因此errno必须保存在TLS。

C++11标准里面新添加了一个thread_local修饰符，标明每个线程都属于自己版本的变量。它可以被初始化并位于TLS中。

Listing 65.1: C++11

```
#include <iostream>
#include <thread>
thread_local int tmp=3;
int main()
{
    std::cout << tmp << std::endl;
};
```

使用MinGW GCC 4.8.1而不是MSVC2012编译。

如果我们查看它的PE文件，可以看到tmp变量被放到TLS section。

## 65.1 线性同余发生器

前面第20章的纯随机数生成器有一个缺陷：它不是线程安全的，因为它的内部状态变量可以被不同的线程同时读取或修改。

### 65.1.1 Win32

#### 未初始化的TLS数据

一个全局变量如果添加了_declspec(thread)修饰符，那么它会被分配在TLS。

```
#include <stdint.h>
#include <windows.h>
#include <winnt.h>

// from the Numerical Recipes book
#define RNG_a 1664525
#define RNG_c 1013904223

__declspec( thread ) uint32_t rand_state;

void my_srand (uint32_t init)
{
    rand_state=init;
}

int my_rand ()
{
    rand_state=rand_state*RNG_a;
    rand_state=rand_state+RNG_c;
    return rand_state & 0x7fff;
}

int main()
{
    my_srand(0x12345678);
    printf ("%d\n", my_rand());
};
```

使用Hiew可以看到PE文件多了一个section：.tls。

Listing 65.2: Optimizing MSVC 2013 x86

```
_TLS SEGMENT
    _rand_state DD 01H DUP (?)
_TLS ENDS

_DATA SEGMENT
    $SG84851 DB '%d', 0aH, 00H
_DATA ENDS

_TEXT SEGMENT

_init$ = 8  ; size = 4

_my_srand PROC
; FS:0=address of TIB
    mov eax, DWORD PTR fs:__tls_array ; displayed in IDA as FS:2Ch
; EAX=address of TLS of process
    mov ecx, DWORD PTR __tls_index
    mov ecx, DWORD PTR [eax+ecx*4]
; ECX=current TLS segment
    mov eax, DWORD PTR _init$[esp-4]
    mov DWORD PTR _rand_state[ecx], eax
    ret 0
_my_srand ENDP

_my_rand PROC
; FS:0=address of TIB
    mov eax, DWORD PTR fs:__tls_array ; displayed in IDA as FS:2Ch
; EAX=address of TLS of process
    mov ecx, DWORD PTR __tls_index
    mov ecx, DWORD PTR [eax+ecx*4]
; ECX=current TLS segment
    imul eax, DWORD PTR _rand_state[ecx], 1664525
    add eax, 1013904223 ; 3c6ef35fH
    mov DWORD PTR _rand_state[ecx], eax
    and eax, 32767 ; 00007fffH
    ret 0
_my_rand ENDP

_TEXT ENDS
```

rand_state现在处于TLS段，而且这个变量每个线程都拥有属于自己版本。它是这么访问的：从FS:2Ch加载TIB（Thread Information Block）的地址，然后添加一个额外的索引（如果需要的话），接着计算出在TLS段的地址。

最后可以通过ECX寄存器来访问rand_state变量，它指向每个线程特定的数据区域。

FS：这是每个逆向工程师都很熟悉的选择子了。它专门用于指向TIB，因此访问线程特定数据可以很快完成。

GS: 该选择子用于Win64，0x58的地址是TLS。

Listing 65.3: Optimizing MSVC 2013 x64

```
_TLS SEGMENT
    rand_state DD 01H DUP (?)
_TLS ENDS

_DATA SEGMENT
    $SG85451 DB '%d', 0aH, 00H
_DATA ENDS

_TEXT SEGMENT
init$ = 8

my_srand PROC
    mov edx, DWORD PTR _tls_index
    mov rax, QWORD PTR gs:88 ; 58h
    mov r8d, OFFSET FLAT:rand_state
    mov rax, QWORD PTR [rax+rdx*8]
    mov DWORD PTR [r8+rax], ecx
    ret 0
my_srand ENDP

my_rand PROC
    mov rax, QWORD PTR gs:88 ; 58h
    mov ecx, DWORD PTR _tls_index
    mov edx, OFFSET FLAT:rand_state
    mov rcx, QWORD PTR [rax+rcx*8]
    imul eax, DWORD PTR [rcx+rdx], 1664525 ;0019660dH
    add eax, 1013904223 ; 3c6ef35fH
    mov DWORD PTR [rcx+rdx], eax
    and eax, 32767 ; 00007fffH
    ret 0
my_rand ENDP

_TEXT ENDS
```

#### 初始化TLS数据

比方说，我们想为rand_state设置一些固定的值以避免程序员忘记初始化。

```
#include <stdint.h>
#include <windows.h>
#include <winnt.h>

// from the Numerical Recipes book
#define RNG_a 1664525
#define RNG_c 1013904223

__declspec( thread ) uint32_t rand_state=1234;

void my_srand (uint32_t init)
{
   rand_state=init;
}

int my_rand ()
{
   rand_state=rand_state*RNG_a;
   rand_state=rand_state+RNG_c;
   return rand_state & 0x7fff;
}

int main()
{
    printf ("%d\n", my_rand());
};
```

代码除了给rand_state设定初始值外与之前的并没有什么不同，但在IDA我们看到：

```
.tls:00404000 ; Segment type: Pure data
.tls:00404000 ; Segment permissions: Read/Write
.tls:00404000 _tls segment para public 'DATA' use32
.tls:00404000 assume cs:_tls
.tls:00404000 ;org 404000h
.tls:00404000 TlsStart db 0 ; DATA XREF: .rdata:TlsDirectory
.tls:00404001 db 0
.tls:00404002 db 0
.tls:00404003 db 0
.tls:00404004 dd 1234
.tls:00404008 TlsEnd db 0 ; DATA XREF: .rdata:TlsEnd_pt
...
```

每次一个新的线程运行的时候，会分配新的TLS给它，然后包括1234所有数据将被拷贝过去。

这是一个典型的场景：
- 线程A开始运行，然后分配给它一个TLS，并把1234拷贝到rand_state。
- 线程A里面多次调用my_rand()函数，rand_state已经不是1234。
- 线程B开始运行，然后分配给它一个TLS，并把1234拷贝到rand_state，这时候可以观察到两个线程使用同一个变量，但它们的值是不一样的。

#### TLS callbacks

如果我们想给TLS赋一个变量值呢？比方说：程序员忘记调用my_srand()函数来初始化PRNG，但是随机数生成器在开始的时候必须使用一个真正的随机数值而不是1234。这种情况下则可以使用TLS callbaks。

下面的代码的可移植性很差，原因你应该明白。我们定义了一个函数(tls_callback())，它在进程/线程开始执行前调用，该函数使用GetTickCount()函数的返回值来初始化PRNG。

```
#include <stdint.h>
#include <windows.h>
#include <winnt.h>

// from the Numerical Recipes book
#define RNG_a 1664525
#define RNG_c 1013904223

__declspec( thread ) uint32_t rand_state;

void my_srand (uint32_t init)
{
    rand_state=init;
}

void NTAPI tls_callback(PVOID a, DWORD dwReason, PVOID b)
{
    my_srand (GetTickCount());
}

#pragma data_seg(".CRT$XLB")
PIMAGE_TLS_CALLBACK p_thread_callback = tls_callback;
#pragma data_seg()

int my_rand ()
{
    rand_state=rand_state*RNG_a;
    rand_state=rand_state+RNG_c;
    return rand_state & 0x7fff;
}
int main()
{
    // rand_state is already initialized at the moment (using GetTickCount())
    printf ("%d\n", my_rand());
};
```

用IDA看一下：

Listing 65.4: Optimizing MSVC 2013

```
.text:00401020 TlsCallback_0 proc near ; DATA XREF: .rdata:TlsCallbacks
.text:00401020     call ds:GetTickCount
.text:00401026     push eax
.text:00401027     call my_srand
.text:0040102C     pop ecx
.text:0040102D     retn 0Ch
.text:0040102D TlsCallback_0 endp
...
.rdata:004020C0 TlsCallbacks dd offset TlsCallback_0 ; DATA XREF: .rdata:TlsCallbacks_ptr
...
.rdata:00402118 TlsDirectory dd offset TlsStart
.rdata:0040211C TlsEnd_ptr dd offset TlsEnd
.rdata:00402120 TlsIndex_ptr dd offset TlsIndex
.rdata:00402124 TlsCallbacks_ptr dd offset TlsCallbacks
.rdata:00402128 TlsSizeOfZeroFill dd 0
.rdata:0040212C TlsCharacteristics dd 300000h
```

TLS callbacks函数时常用于隐藏解包处理过程。为此有些人可能会困惑，为什么一些代码可以偷偷地在OEP（Original Entry Point）之前执行。

### 65.1.2 Linux

下面是GCC声明线程局部存储的方式：

```
__thread uint32_t rand_state=1234;
```

这不是标准C/C++的修饰符，但是是GCC的一个扩展特性。

GS：该选择子同样用于访问TLS，但稍微有点区别：

Listing 65.5: Optimizing GCC 4.8.1 x86

```
.text:08048460 my_srand proc near
.text:08048460
.text:08048460 arg_0 = dword ptr 4
.text:08048460
.text:08048460     mov eax, [esp+arg_0]
.text:08048464     mov gs:0FFFFFFFCh, eax
.text:0804846A     retn
.text:0804846A my_srand endp
.text:08048470 my_rand proc near
.text:08048470     imul eax, gs:0FFFFFFFCh, 19660Dh
.text:0804847B     add eax, 3C6EF35Fh
.text:08048480     mov gs:0FFFFFFFCh, eax
.text:08048486     and eax, 7FFFh
.text:0804848B     retn
.text:0804848B my_rand endp
```

更多例子：[ELF Handling For Thread-Local Storage](http://go.yurichev.com/17272)