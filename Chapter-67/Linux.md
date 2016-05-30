#67章 Linux

##67.1 位置无关代码

在分析Linux共享库的时候(.so)的时候，可能会经常看到类似下面的代码：

Listing 67.1: libc-2.17.so x86

```
.text:0012D5E3 __x86_get_pc_thunk_bx proc near ; CODE XREF: sub_17350+3
.text:0012D5E3 ; sub_173CC+4 ...
.text:0012D5E3     mov ebx, [esp+0]
.text:0012D5E6     retn
.text:0012D5E6 __x86_get_pc_thunk_bx endp
...
.text:000576C0 sub_576C0 proc near ; CODE XREF: tmpfile+73
...
.text:000576C0     push ebp
.text:000576C1     mov ecx, large gs:0
.text:000576C8     push edi
.text:000576C9     push esi
.text:000576CA     push ebx
.text:000576CB     call __x86_get_pc_thunk_bx
.text:000576D0     add ebx, 157930h
.text:000576D6     sub esp, 9Ch
...
.text:000579F0     lea eax, (a__gen_tempname - 1AF000h)[ebx] ; "__gen_tempname"
.text:000579F6     mov [esp+0ACh+var_A0], eax
.text:000579FA     lea eax, (a__SysdepsPosix - 1AF000h)[ebx] ; "../sysdeps/posix/tempname.c"
.text:00057A00     mov [esp+0ACh+var_A8], eax
.text:00057A04     lea eax, (aInvalidKindIn_ - 1AF000h)[ebx] ; "! \"invalid KIND in __gen_tempname\""
.text:00057A0A     mov [esp+0ACh+var_A4], 14Ah
.text:00057A12     mov [esp+0ACh+var_AC], eax
.text:00057A15     call __assert_fail
```

在每个函数开始处，所有指向字符串的指针都需要通过EBX和一些常量值来修正地址。这就是所谓的PIC（位置无关代码），它的目的是让这段代码即使放在内存中某个随机位置都能正确地执行。这也是为什么不能使用绝对地址的原因。

PIC（位置无关代码）对于早期的操作系统和现在那些没有虚拟内存支持的嵌入式系统来说至关重要（所有进程都放在同一个连续的内存块）。此外，它还用于*NIX系统的共享库。这样共享库只需要加载一次到内存之后就可以让所有需要的进程使用。而且这些进程可以把同一个共享库映射到各自不同的内存地址上。这也是为什么共享库不使用绝对地址也能够正常地工作的原因。

让我们做一个简单的实验：

```
#include <stdio.h>
int global_variable=123;
int f1(int var)
{
    int rt=global_variable+var;
    printf ("returning %d\n", rt);
    return rt;
};
```

用GCC 4.7.3编译它并用IDA查看.so文件的反汇编代码：

```
gcc -fPIC -shared -O3 -o 1.so 1.c
```

```
.text:00000440 public __x86_get_pc_thunk_bx
.text:00000440 __x86_get_pc_thunk_bx proc near ; CODE XREF: _init_proc+4
.text:00000440 ; deregister_tm_clones+4 ...
.text:00000440     mov ebx, [esp+0]
.text:00000443     retn
.text:00000443 __x86_get_pc_thunk_bx endp
.text:00000570 public f1
.text:00000570 f1 proc near
.text:00000570
.text:00000570 var_1C = dword ptr -1Ch
.text:00000570 var_18 = dword ptr -18h
.text:00000570 var_14 = dword ptr -14h
.text:00000570 var_8 = dword ptr -8
.text:00000570 var_4 = dword ptr -4
.text:00000570 arg_0 = dword ptr 4
.text:00000570
.text:00000570     sub esp, 1Ch
.text:00000573     mov [esp+1Ch+var_8], ebx
.text:00000577     call __x86_get_pc_thunk_bx
.text:0000057C     add ebx, 1A84h
.text:00000582     mov [esp+1Ch+var_4], esi
.text:00000586     mov eax, ds:(global_variable_ptr - 2000h)[ebx]
.text:0000058C     mov esi, [eax]
.text:0000058E     lea eax, (aReturningD - 2000h)[ebx] ; "returning %d\n"
.text:00000594     add esi, [esp+1Ch+arg_0]
.text:00000598     mov [esp+1Ch+var_18], eax
.text:0000059C     mov [esp+1Ch+var_1C], 1
.text:000005A3     mov [esp+1Ch+var_14], esi
.text:000005A7     call ___printf_chk
.text:000005AC     mov eax, esi
.text:000005AE     mov ebx, [esp+1Ch+var_8]
.text:000005B2     mov esi, [esp+1Ch+var_4]
.text:000005B6     add esp, 1Ch
.text:000005B9     retn
.text:000005B9 f1 endp
```

如上所示：每个函数执行时都会修正指向“returning %d\n”和global_variable的指针。__x86_get_pc_thunk_bx()函数通过EBX返回一个指向自身的指针（返回的是0x57C）。这是一种获取程序计数器（EIP）的简单方法。0x1A84常量是这个函数开始处到（Global Offset Table Procedure Linkage Table(GOT PLT)）它们之间的距离差。IDA会把这些偏移处理成更容易理解后再显示出来，所以实际上的代码是：

```
.text:00000577 call __x86_get_pc_thunk_bx
.text:0000057C add ebx, 1A84h
.text:00000582 mov [esp+1Ch+var_4], esi
.text:00000586 mov eax, [ebx-0Ch]
.text:0000058C mov esi, [eax]
.text:0000058E lea eax, [ebx-1A30h]
```

这里的EBX指向了GOT PLT section。当计算global_variable（存储在GOT）的地址时须减去0x0C偏移量。当计算"returning %d\n"字符串的地址时须减去0x1A30偏移量。

顺便说一下，AMD64的指令支持使用RIP用于相对寻址，这使得它可以产生出更简洁的PIC代码。

让我们用相同的GCC编译器编译相同的C代码，但使用x64平台。

IDA会简化了反汇编代码，造成我们无法看到使用RIP相对寻址的细节，所以我在这里使用了objdump来查看反汇编代码：

```
0000000000000720 <f1>:
720: 48 8b 05 b9 08 20 00    mov rax,QWORD PTR [rip+0x2008b9] # 200fe0 <_DYNAMIC+0x1d0>
727: 53                      push rbx
728: 89                      fb mov ebx,edi
72a: 48 8d 35 20 00 00 00    lea rsi,[rip+0x20] #751 <_fini+0x9>
731: bf 01 00 00 00          mov edi,0x1
736: 03 18                   add ebx,DWORD PTR [rax]
738: 31 c0                   xor eax,eax
73a: 89 da                   mov edx,ebx
73c: e8 df fe ff ff          call 620 <__printf_chk@plt>
741: 89 d8                   mov eax,ebx
743: 5b                      pop rbx
744: c3                      ret
```

0x2008b9是0x720处指令地址到global_variable地址的差，0x20是0x72a处指令地址到"returning %d\n"字符串地址的差。

你可能会看到，频繁重新计算地址会导致执行效率变差（虽然在x64会更好）。所以如果你比较关心性能的话最好还是使用静态链接。

###67.1.1 Windows

Windows的DLL并没有使用PIC机制。如果Windows加载器需加载DLL到另外一个基地址，它需要把DLL在内存中的“重定位段”（在固定的位置）里所有地址都调整为正确的。这意味着多个Windows进程不能在不同进程内存块的不同地址共享一份DLL，因为每个实例加载在内存后只固定在这些地址工作。

##67.2 LD_PRELOAD hack in Linux

Linux允许让我们自己的动态链接库加载在其它动态链接库之前，甚至是系统库（如 libc.so.6）。

反过来想，也就是允许我们用自己写的函数去“代替”系统库的函数。举个例子，我们可以很容易地拦截掉time()，read()，write()等等这些函数。

来瞧瞧我们是如何愚弄uptime这个程序的。我们知道，该程序显示计算机已经工作了多长时间。借助strace的帮助可以看到，该程序通过/proc/uptime文件获取到计算机的工作时长。

```
$ strace uptime
...
open("/proc/uptime", O_RDONLY) = 3
lseek(3, 0, SEEK_SET) = 0
read(3, "416166.86 414629.38\n", 2047) = 20
...
```

/proc/uptime并不是存放在磁盘的真实文件。而是由Linux Kernel产生的一个虚拟的文件。它有两个数值：

```
$ cat /proc/uptime
416690.91 415152.03
```

我们可以用wikipedia来看一下它的含义：
```
第一个数值是系统运行总时长，第二个数值是系统空闲的时间。都以秒为单位表示。
```

我们来写一个含open()，read()，close()函数的动态链接库。

首先，我们的open()函数会比较一下文件名是不是我们所想要打开的，如果是，则将文件描述符记录下来。然后，read()函数会判断如果我们调用的是不是我们所保存的文件描述符，如果是则代替它输出，否则调用libc.so.6里面原来的函数。最后，close()函数会关闭我们所保存的文件描述符。

在这里我们借助了dlopen()和dlsym()函数来确定原先在libc.so.6的函数的地址，因为我们需要控制“真实”的函数。

题外话，如果我们的程序想劫持strcmp()函数来监控每个字符串的比较，则需要我们自己实现一个strcmp()函数而不能用原先的函数。

```
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>
#include <dlfcn.h>
#include <string.h>

void *libc_handle = NULL;
int (*open_ptr)(const char *, int) = NULL;
int (*close_ptr)(int) = NULL;
ssize_t (*read_ptr)(int, void*, size_t) = NULL;
bool inited = false;

_Noreturn void die (const char * fmt, ...)
{
    va_list va;
    va_start (va, fmt);
    vprintf (fmt, va);
    exit(0);
};

static void find_original_functions ()
{
    if (inited)
        return;
    libc_handle = dlopen ("libc.so.6", RTLD_LAZY);
    if (libc_handle==NULL)
        die ("can't open libc.so.6\n");
    open_ptr = dlsym (libc_handle, "open");
    if (open_ptr==NULL)
        die ("can't find open()\n");
    close_ptr = dlsym (libc_handle, "close");
    if (close_ptr==NULL)
        die ("can't find close()\n");
    read_ptr = dlsym (libc_handle, "read");
    if (read_ptr==NULL)
        die ("can't find read()\n");
    inited = true;
}

static int opened_fd=0;

int open(const char *pathname, int flags)
{
    find_original_functions();
    int fd=(*open_ptr)(pathname, flags);
    if (strcmp(pathname, "/proc/uptime")==0)
        opened_fd=fd; // that's our file! record its file descriptor
    else
        opened_fd=0;
    return fd;
};

int close(int fd)
{
    find_original_functions();
    if (fd==opened_fd)
        opened_fd=0; // the file is not opened anymore
    return (*close_ptr)(fd);
};

ssize_t read(int fd, void *buf, size_t count)
{
    find_original_functions();
    if (opened_fd!=0 && fd==opened_fd)
    {
        // that's our file!
        return snprintf (buf, count, "%d %d", 0x7fffffff, 0x7fffffff)+1;
    };
    // not our file, go to real read() function
    return (*read_ptr)(fd, buf, count);
};

```

把它编译成动态链接库：
```
gcc -fpic -shared -Wall -o fool_uptime.so fool_uptime.c -ldl
```

运行uptime，并让它在加载其它库之前加载我们的库：

```
LD_PRELOAD=`pwd`/fool_uptime.so uptime
```

可以看到：

```
01:23:02 up 24855 days, 3:14, 3 users, load average: 0.00, 0.01, 0.05
```

如果LD_PRELOAD环境变量一直指向我们的动态链接库文件名，其它程序在启动的时候也会加载我们的动态链接库。

更多的例子请看：

- [Verysimpleinterceptionofthestrcmp()(YongHuang)](http://go.yurichev.
com/17043)
- [KevinPulo—FunwithLD_PRELOAD.Alotofexamplesandideas.](http://go.yurichev.com/17145)
- [File functions interception for compression/decompression files on fly (zlibc).](http://go.yurichev.com/17146)
