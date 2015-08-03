#第58章 
##调用assert

有时，assert()宏的出现也是有用的：通常这个宏会泄漏源文件名，行号和条件。

最有用的信息包含在assert的条件中，我们可以从中推断出变量名或者结构体名。另一个有用的信息是文件名。我们可以从中推断出使用了什么类型的代码。并且也可能通过文件名识别出有名的开源库。

```
.text:107D4B29 mov  dx, [ecx+42h].text:107D4B2D cmp  edx, 1.text:107D4B30 jz   short loc_107D4B4A.text:107D4B32 push 1ECh.text:107D4B37 push offset aWrite_c ; "write.c".text:107D4B3C push offset aTdTd_planarcon ; "td->td_planarconfig == PLANARCONFIG_CON"....text:107D4B41 call ds:_assert....text:107D52CA mov  edx, [ebp-4].text:107D52CD and  edx, 3.text:107D52D0 test edx, edx.text:107D52D2 jz   short loc_107D52E9.text:107D52D4 push 58h.text:107D52D6 push offset aDumpmode_c ; "dumpmode.c".text:107D52DB push offset aN30     ; "(n & 3) == 0".text:107D52E0 call ds:_assert....text:107D6759 mov  cx, [eax+6].text:107D675D cmp  ecx, 0Ch.text:107D6760 jle  short loc_107D677A.text:107D6762 push 2D8h.text:107D6767 push offset aLzw_c   ; "lzw.c".text:107D676C push offset aSpLzw_nbitsBit ; "sp->lzw_nbits <= BITS_MAX".text:107D6771 call ds:_assert
```

同时google一下条件和文件名是明智的，可能会因此找到开源库。举个例子，如果我们google查找“sp->lzw_nbits <= BITS_MAX”，将会显示一些与LZW压缩有关的开源代码。



