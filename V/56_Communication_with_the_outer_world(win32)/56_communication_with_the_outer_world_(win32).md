#第56章 
##与外部世界通信(win32)


有时理解函数的功能通过观察函数的输入与输出就足够了。这样可以节省时间。

文件和注册访问：对于最基本的分析，SysInternals的[Process Monitor](http://go.yurichev.com/17301)工具很有用。

对于基本网络访问分析，Wireshark很有帮助。

但接下来你仍需查看内部。

第一步是查看使用的是OS的API哪个函数，标准库是什么。

如果程序被分为主要的可执行文件和一系列DLL文件，那么DLL文件中的函数名可能会有帮助。

如果我们对指定文本调用MessageBox()的细节感兴趣，我们可以在数据段中查找这个文本，定位文本引用处，以及控制权交给我们感兴趣的MessageBox()的地方。

如果我们在谈论电子游戏，并且对里面的事件的随机性感兴趣，那么我们可以查找rand()函数或者类似函数(比如马特赛特旋转演算法)，然后定位调用这些函数的地方，更重要的是，函数执行结果如何被使用。

但如果不是一个游戏，并且仍然使用了rand{}函数，找出原因也很有意思。这里有一些关于在数据压缩算法中意外出现rand()函数调用的例子(模仿加密)：[blog.yurichev.com](blog.yurichev.com)


###56.1 Windows API中常用的函数

下面这些函数可能会被导入。值得注意的是并不是每个函数都在代码中使用。许多函数可能被库函数和CRT代码调用。

*	注册访问(advapi32.dll):RegEnumKeyEx, RegEnumValue, RegGetValue7, RegOpenKeyEx, RegQueryVal- ueEx
*	.ini-file访问(kernel32.dll): GetPrivateProfileString
*	资源访问(68.2.8): (user32.dll): LoadMen
*	TCP/IP网络(ws2_32.dll): WSARecv, WSASend
*	文件访问(kernel32.dll): CreateFile, ReadFile, ReadFileEx, WriteFile, WriteFileEx
*	Internet高级访问(wininet.dll): WinHttpOpen
*	可执行文件数字签名(wintrust.dll): WinVerifyTrust
*	标准MSVC库(如果是动态链接的) (msvcr*.dll): assert, itoa, ltoa, open, printf, read, strcmp, atol, atoi, fopen, fread, fwrite, memcmp, rand, strlen, strstr, strchr

###56.2 tracer:拦截所有函数特殊模块

这里有一个INT3断点，只触发了一次，但可以为指定DLL中的所有函数设置。

```
--one-time-INT3-bp:somedll.dll!.*
```

我们给所有前缀是xml的函数设置INT3断点吧：

```
--one-time-INT3-bp:somedll.dll!xml.*
```

另一方面，这样的断点只会触发一次。

Tracer会在函数调用发生时显示调用情况，但只有一次。但查看函数参数是不可能的。

尽管如此，在你知道这个程序使用了一个DLL，但不知道实际上使用了哪个函数并且有许多的函数的情况下，这个特性还是很有用的。

举个例子，我们来看看，cygwin的uptime工具使用了什么：

```tracer -l:uptime.exe --one-time-INT3-bp:cygwin1.dll!.*```
我们可以看见所有的至少调用了一次的cygwin1.dll库函数，以及位置：```
One-time INT3 breakpoint: cygwin1.dll!__main (called from uptime.exe!OEP+0x6d (0x40106d))One-time INT3 breakpoint: cygwin1.dll!_geteuid32 (called from uptime.exe!OEP+0xba3 (0x401ba3))One-time INT3 breakpoint: cygwin1.dll!_getuid32 (called from uptime.exe!OEP+0xbaa (0x401baa))One-time INT3 breakpoint: cygwin1.dll!_getegid32 (called from uptime.exe!OEP+0xcb7 (0x401cb7))One-time INT3 breakpoint: cygwin1.dll!_getgid32 (called from uptime.exe!OEP+0xcbe (0x401cbe))One-time INT3 breakpoint: cygwin1.dll!sysconf (called from uptime.exe!OEP+0x735 (0x401735))One-time INT3 breakpoint: cygwin1.dll!setlocale (called from uptime.exe!OEP+0x7b2 (0x4017b2))One-time INT3 breakpoint: cygwin1.dll!_open64 (called from uptime.exe!OEP+0x994 (0x401994))One-time INT3 breakpoint: cygwin1.dll!_lseek64 (called from uptime.exe!OEP+0x7ea (0x4017ea))One-time INT3 breakpoint: cygwin1.dll!read (called from uptime.exe!OEP+0x809 (0x401809))One-time INT3 breakpoint: cygwin1.dll!sscanf (called from uptime.exe!OEP+0x839 (0x401839))One-time INT3 breakpoint: cygwin1.dll!uname (called from uptime.exe!OEP+0x139 (0x401139))One-time INT3 breakpoint: cygwin1.dll!time (called from uptime.exe!OEP+0x22e (0x40122e))One-time INT3 breakpoint: cygwin1.dll!localtime (called from uptime.exe!OEP+0x236 (0x401236))One-time INT3 breakpoint: cygwin1.dll!sprintf (called from uptime.exe!OEP+0x25a (0x40125a))One-time INT3 breakpoint: cygwin1.dll!setutent (called from uptime.exe!OEP+0x3b1 (0x4013b1))One-time INT3 breakpoint: cygwin1.dll!getutent (called from uptime.exe!OEP+0x3c5 (0x4013c5))One-time INT3 breakpoint: cygwin1.dll!endutent (called from uptime.exe!OEP+0x3e6 (0x4013```