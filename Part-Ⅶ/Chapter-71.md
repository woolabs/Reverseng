# 第七十一章
# 系统调用跟踪

## 71.0.1 stace/dtruss

显示当前进程的系统调用(第697页)。比如：

```
# strace df -h...access("/etc/ld.so.nohwcap", F_OK)      = -1 ENOENT (No such file or directory)open("/lib/i386-linux-gnu/libc.so.6", O_RDONLY|O_CLOEXEC) = 3read(3, "\177ELF\1\1\1\0\0\0\0\0\0\0\0\0\3\0\3\0\1\0\0\0\220\232\1\0004\0\0\0"..., 512) = 512fstat64(3, {st_mode=S_IFREG|0755, st_size=1770984, ...}) = 0mmap2(NULL, 1780508, PROT_READ|PROT_EXEC, MAP_PRIVATE|MAP_DENYWRITE, 3, 0) = 0xb75b3000

```

Mac OS X 的dtruss也有这个功能。

Cygwin也有strace，但如果我理解正确的话，它只为cygwin环境编译exe文件工作。