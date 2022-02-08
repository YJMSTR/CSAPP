
examples.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <sum_list>:
   0:	f3 0f 1e fa          	endbr64 
   4:	55                   	push   %rbp
   5:	48 89 e5             	mov    %rsp,%rbp
   8:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
   c:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  13:	00 
  14:	eb 17                	jmp    2d <sum_list+0x2d>
  16:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  1a:	48 8b 00             	mov    (%rax),%rax
  1d:	48 01 45 f8          	add    %rax,-0x8(%rbp)
  21:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  25:	48 8b 40 08          	mov    0x8(%rax),%rax
  29:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  2d:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  32:	75 e2                	jne    16 <sum_list+0x16>
  34:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  38:	5d                   	pop    %rbp
  39:	c3                   	retq   

000000000000003a <rsum_list>:
  3a:	f3 0f 1e fa          	endbr64 
  3e:	55                   	push   %rbp
  3f:	48 89 e5             	mov    %rsp,%rbp
  42:	48 83 ec 20          	sub    $0x20,%rsp
  46:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  4a:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  4f:	75 07                	jne    58 <rsum_list+0x1e>
  51:	b8 00 00 00 00       	mov    $0x0,%eax
  56:	eb 2a                	jmp    82 <rsum_list+0x48>
  58:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  5c:	48 8b 00             	mov    (%rax),%rax
  5f:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  63:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  67:	48 8b 40 08          	mov    0x8(%rax),%rax
  6b:	48 89 c7             	mov    %rax,%rdi
  6e:	e8 00 00 00 00       	callq  73 <rsum_list+0x39>
  73:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  77:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  7b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  7f:	48 01 d0             	add    %rdx,%rax
  82:	c9                   	leaveq 
  83:	c3                   	retq   

0000000000000084 <copy_block>:
  84:	f3 0f 1e fa          	endbr64 
  88:	55                   	push   %rbp
  89:	48 89 e5             	mov    %rsp,%rbp
  8c:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  90:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  94:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  98:	48 c7 45 f0 00 00 00 	movq   $0x0,-0x10(%rbp)
  9f:	00 
  a0:	eb 33                	jmp    d5 <copy_block+0x51>
  a2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  a6:	48 8d 50 08          	lea    0x8(%rax),%rdx
  aa:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  ae:	48 8b 00             	mov    (%rax),%rax
  b1:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  b5:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  b9:	48 8d 50 08          	lea    0x8(%rax),%rdx
  bd:	48 89 55 e0          	mov    %rdx,-0x20(%rbp)
  c1:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  c5:	48 89 10             	mov    %rdx,(%rax)
  c8:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  cc:	48 31 45 f0          	xor    %rax,-0x10(%rbp)
  d0:	48 83 6d d8 01       	subq   $0x1,-0x28(%rbp)
  d5:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  da:	7f c6                	jg     a2 <copy_block+0x1e>
  dc:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  e0:	5d                   	pop    %rbp
  e1:	c3                   	retq   
