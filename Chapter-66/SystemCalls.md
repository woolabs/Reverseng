#66章 系统调用(syscall-s)

众所周知，所有运行的进程在操作系统里面分为两类：一类拥有访问全部硬件设备的权限（内核空间）而另一类无法直接访问硬件设备(用户空间)。

操作系统内核和驱动程序通常是属于第一类的。

而应用程序通常是属于第二类的。

举个例子，Linux kernel运行于内核空间，而Glibc运行于用户空间。

这种分离对与操作系统的安全性是至关重要的：它最重要的一点是，不给任何进程有破坏到其它进程甚至是系统内核的机会。另一方面，一个错误的驱动或系统内核错误都会造成系统崩溃或者蓝屏。

保护模式下的x86处理器允许使用4个保护等级（ring）。但Linux和Windows两个操作系统都只使用了两个：ring0（内核空间）和ring3（用户空间）。

系统调用（syscall-s）是两个运行空间的连接点。可以说，这是提供给应用程序主要的API。

在Windows NT，系统调用表存在于SSDT。

通过系统调用实现shellcode在计算机病毒作者之间非常流行。因为很难确定所需函数在系统库里面的地址，但系统调用很容易确定。然而，由于系统调用属于比较底层的API，所以需要编写更多的代码。最后值得一提的是，在不同的操作系统版本里面，系统调用号是有可能不同的。

##66.1 Linux

在Linux系统中，系统调用通常使用int 0x80中断进行调用。通过EAX寄存器传递调用号，再通过其它寄存器传递所需参数。

Listing 66.1: A simple example of the usage of two syscalls

```
section .text
global _start
_start:
	mov edx,len	; buf len
	mov ecx,msg	; buf
	mov ebx,1	; file descriptor. stdout is 1
	mov eax,4	; syscall number. sys_write is 4
	int 0x80
	mov eax,1	; syscall number. sys_exit is 4
	int 0x80
section .data
msg db 'Hello, world!',0xa
len equ $ - msg
```

编译：

```
nasm -f elf32 1.s
ld 1.o
```

Linux所有的系统调用在这里可以查看：[http://go.yurichev.com/17319](http://go.yurichev.com/17319)。

在Linux中可以使用strace(71章)对系统调用进行跟踪或者拦截。

##66.2 Windows

Windows系统使用int 0x2e中断或x86下特有的指令SYSENTER调用用系统调用服务。

Windows所有的系统调用在这里可以查看：[http://go.yurichev.com/17320](http://go.yurichev.com/17320)。

扩展阅读：[“Windows Syscall Shellcode” by Piotr Bania](http://go.yurichev.com/17321.)