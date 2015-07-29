#第59章 
##常量

通常人们在生活中或者程序员在编写代码时喜欢使用像10，100，1000这样的整数。

有经验的逆向工程师会对这些数字的十六进制形式很熟悉：10=0xA, 100=0x64, 1000=0x3E8, 10000=0x2710。

常量 0xAAAAAAAA (10101010101010101010101010101010)和0x55555555 (01010101010101010101010101010101)也很常用——构成alternating bits。举个例子，0x55AA在引导扇区，MBR，IBM兼容扩展卡中使用过。

某些算法，特别是密码学方面的使用的常量很有代表性，我们可以在IDA中轻松找到。

举个例子，MD5算法这样初始化内部变量：

var int h0 := 0x67452301
var int h1 := 0xEFCDAB89
var int h2 := 0x98BADCFE
var int h3 := 0x10325476

如果你在代码中某行发现这四个常量，那么极有可能这个函数与MD5有关。

另一个有关CRC16/CRC32算法的例子，通常使用预先计算好的表来计算：

```
/** CRC table for the CRC-16. The poly is 0x8005 (x^16 + x^15 + x^2 + 1) */u16 const crc16_table[256] = {        0x0000, 0xC0C1, 0xC181, 0x0140, 0xC301, 0x03C0, 0x0280, 0xC241,        0xC601, 0x06C0, 0x0780, 0xC741, 0x0500, 0xC5C1, 0xC481, 0x0440,        0xCC01, 0x0CC0, 0x0D80, 0xCD41, 0x0F00, 0xCFC1, 0xCE81, 0x0E40,        ...
```

CRC3预计算表同见：第37节

###59.1 幻数

许多文件格式定义了标准的文件头，使用了幻数。

举个例子，所有的Win32和MS-DOS可执行文件以"MZ"这两个字符开始。

MIDI文件的开始有"MThd"标志。如果我们有一个使用MIDI文件的程序，它很有可能会检查至少4字节的文件头来确认文件类型。

可以这样实现：

(buf指向文件加载到内存的开始处)

```
cmp [buf], 0x6468544D ; "MThd"
jnz _error_not_a_MIDI_file

```
也可能会调用某个函数比如memcmp()或者等同于CMPSB指令(A.6.3节)的代码用于比对内存块。

当你发现这样的地方，你就可以确定的MIDI文件加载的开始处，同时我们可以看到缓冲区存放MIDI文件内容的地方，什么内容被使用以及如何使用。


####59.1.1 DHCP

这对于网络协议也同样适用。举个例子，DHCP协议网络包包含了称为所谓的magic cookie：0x6353826。任何生成DHCP包的代码在某处一定将这个常量嵌入了包中。我们在代码中发现它的地方可能就是执行这些操作的位置，或者不仅是如此。任何接收DHCP的包都会检查这个magic cookie，比对是否相同。

举个例子，我们使用Windows 7 x64的dhcpcore.dll文件搜索这个常量。我们发现了两处：看上去这个常量在两个函数中使用，名为DhcpExtractOptionsForValidation()和 、DhcpExtractFullOptions():

```
.rdata:000007FF6483CBE8 dword_7FF6483CBE8 dd 63538263h ; DATA XREF: ⤦ 
	DhcpExtractOptionsForValidation+79￼￼￼￼￼￼￼￼￼￼￼.rdata:000007FF6483CBEC dword_7					      DATA XREF: ⤦ 
	DhcpExtractFullOptions+97
	```

下面是这些常量被获取的地址：
```
.text:000007FF6480875F  mov	eax, [rsi].text:000007FF64808761  cmp	eax, cs:dword_7FF6483CBE8.text:000007FF64808767  jnz	loc_7FF64817179```

还有：
```
.text:000007FF648082C7  mov	eax, [r12].text:000007FF648082CB  cmp	eax, cs:dword_7FF6483CBEC.text:000007FF648082D1  jnz	loc_7FF648173AF```
###59.2 搜索常量
在IDA中很容易：ALT-B或者ALT-I。在大量文件中或者在不可执行文件中搜索常量时，我会使用自己编写一个叫[binary grep](http://go.yurichev.com/17017)的小工具。