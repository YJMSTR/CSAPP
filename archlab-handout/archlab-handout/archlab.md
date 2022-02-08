# archlab

## Init

我的环境是wsl2的ubuntu

在make时出现：

```shell
/usr/bin/ld: cannot find -ltk
/usr/bin/ld: cannot find -ltcl
collect2: error: ld returned 1 exit status
```

折腾半天没法搞定，只得先把makefile中相关代码注释了，等之后填坑...

改完makefile直接`make clean; make`，就可以接着做lab了。

## Part A

用Y86-64汇编语言实现3个程序，随后用YAS编译并用YIS运行

### sum.ys

遍历给出的链表并求和

书上有个遍历数组的例子，可以直接对着改

```assembly
.pos 0
    irmovq stack, %rsp
    call main
    halt

# Sample linked list
.align 8
ele1:
    .quad 0x00a
    .quad ele2
ele2:
    .quad 0x0b0
    .quad ele3
ele3:
    .quad 0xc00
    .quad 0
main:
    irmovq ele1, %rdi
    call sum
    ret
sum:
    irmovq $8, %r8
    xorq %rax, %rax
    andq %rdi, %rdi
    jmp test
loop:
    mrmovq (%rdi), %r10
    addq %r10, %rax
    mrmovq 8(%rdi), %rdi
test:
    andq %rdi, %rdi
    jne loop
    ret
#stack
    .pos 0x200
stack:
```

改完后输入`./yas sum.ys` 报错：

```shell
Error on line 37: Missing end-of-line on final line

Line 37, Byte 0x0200:     .pos 0x200
```

在wsl中用vim打一个空格即可解决，可能是windows和linux的不同导致的。

随后运行`./yis sum.yo`

```assembly
Stopped in 31 steps at PC = 0x13.  Status 'HLT', CC Z=1 S=0 O=0
Changes to registers:
%rax:   0x0000000000000000      0x0000000000000cba
%rsp:   0x0000000000000000      0x0000000000000200
%r8:    0x0000000000000000      0x0000000000000008
%r10:   0x0000000000000000      0x0000000000000c00

Changes to memory:
0x01f0: 0x0000000000000000      0x000000000000005b
0x01f8: 0x0000000000000000      0x0000000000000013
```

### rsum.ys

递归版本的链表求和。

```assembly
.pos 0
    irmovq stack, %rsp
    call main
    halt

# Sample linked list
.align 8
ele1:
    .quad 0x00a
    .quad ele2
ele2:
    .quad 0x0b0
    .quad ele3
ele3:
    .quad 0xc00
    .quad 0
main:
    irmovq ele1, %rdi
    call rsum
    ret
rsum:
    pushq %rbp
    xorq %rax, %rax
    andq %rdi, %rdi
    je return
    mrmovq (%rdi), %rbp
    mrmovq 8(%rdi), %rdi
    call rsum
    addq %rbp, %rax
return:
    popq %rbp
    ret
#stack
    .pos 0x200
stack:
```

### copy.ys

```assembly
.pos 0
    irmovq stack, %rsp
    call main
    halt

.align 8
# Source block
src:
    .quad 0x00a
    .quad 0x0b0
    .quad 0xc00
# Destination block
dest:
    .quad 0x111
    .quad 0x222
    .quad 0x333

main:
    irmovq src, %rdi
    irmovq dest, %rsi
    irmovq $3, %rdx
    irmovq $8, %r8
    irmovq $1, %r9
    call copy
    ret
copy:
    xorq %rax, %rax
    jmp test
loop:
    subq %r9, %rdx
    mrmovq (%rdi), %r10
    rmmovq %r10, (%rsi)
    xorq %rdi, %rax
    addq %r8, %rdi
    addq %r8, %rsi
test:
    andq %rdx, %rdx
    jne loop 
    ret
    .pos 0x200
stack:


```

## Part B 



