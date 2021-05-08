GLOBAL _start

%define AF_INET 	2
%define SOCK_STREAM 	1
%define IPPROTO_TCP 	6

%define SYS_SOCKETCALL	102
%define SYS_WRITE	4
%define SYS_CLOSE	6

%define CALL_SOCKET	1
%define CALL_BIND	2
%define CALL_LISTEN	4
%define CALL_ACCEPT	5

%define QUEUE_SIZE	0x7f	;Keep it 7-bit

%macro MAKE_PORT 1
	db %1 >> 8, %1 & 0xff
%endm

%macro MAKE_INTERFACE 4
	db %1, %2, %3, %4
%endm

%macro smov 2
	%defstr reg %1
	%substr reg_id reg 2
	%strcat byte_reg_str reg_id, "l"
	%deftok byte_reg byte_reg_str
	
	xor %1, %1
	mov byte_reg, %2
%endm

SECTION .text

_start:

  ;--- Create the socket  ---	
  
  push IPPROTO_TCP			;Making DWORDs from 8-bit constants using the 
  push SOCK_STREAM			;stack is 2*n_const vs 4*n_const of using dd
  push AF_INET
  smov ebx, CALL_SOCKET			;Shorter form of mov r32, imm8 using xor + mov
  call socketcall
  
 
  ;--- Bind the socket  ---
  
  push 0x10				;Using the stack here is again a win
  push inet_addr
  push eax
  mov bl, CALL_BIND
  call socketcall			;NOTE: this will put the first parameter in edi
  					;In this case it will put eax (socket descriptor) 
  					;in edi
  
  
  ;--- Make the socket listen ---
_listen:  
  push QUEUE_SIZE			;Again using the stack we get away with
  push edi				;just 4 bytes
  mov bl, CALL_LISTEN
  call socketcall 
 
  
_server_loop:  

  ;--- Accept ---
  
  push 0
  push 0
  push edi				
  mov bl, CALL_ACCEPT
  call socketcall
  
  push eax				;Save for later
  
  
  ;--- Write the response ---
  
  mov ebx, eax
  smov eax, SYS_WRITE
  mov ecx, html
  smov edx, html_len
  int 0x80
  
  ;--- Close the new socket ---
  
  pop ebx
  mov al, SYS_CLOSE		;eax[31:8] was 0 from the previous syscall (if no errors)
  int 0x80
 
 jmp _server_loop 
  
  
;====================================

socketcall:
  ;ebx must be set by the caller

  smov eax, SYS_SOCKETCALL
  lea ecx, [esp+4]
  int 80h
  
  mov edi, DWORD [esp+4]	;Return in edi the first parameter of syscall
  				;This is usually the socket descriptor
  				
  ret 4				;We clean up only ONE parameter
  				;This is ok since every use has at least one
  				;parameter and in the server_loop spares us from
  				;rebalancing the stack
  
  
;====================================

  ;We can put read only data in the code section. It's bad for performance but
  ;we only care about space  
  
  html: db "HTTP/1.0 200 OK\", 13, 10, 13, 10, "<h1>Hello!</h1>"
  html_len EQU $-html
  
  inet_addr: 
  	dw AF_INET 
  	MAKE_PORT 8800
  	;MAKE_INTERFACE 0, 0, 0, 0

	;The MAKE_INTERFACE is commented because on x86 a page is always allocated
	;and zeroed by the kernel. So we know there are zeros after our code.
	;Thus we get a free MAKE_INTERFACE 0, 0, 0, 0
	;One can also fuse AF_INET and the port, if this is lower than 256, using:
	;
	;db AF_INET, 0, <port-number>
   	



  
  

