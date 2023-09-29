format ELF64 executable
segment readable executable

macro sys_call type,arg1,arg2,arg3,arg4,arg5,arg6
{
	if type eq
	else 
		mov rax,type
	end if
	if arg1 eq
	else
		mov rdi, arg1
	end if
	if arg2 eq
	else
		mov rsi, arg2
	end if
	if arg3 eq
	else
		mov rdx, arg3
	end if
	if arg4 eq
	else
		mov r10, arg4
	end if
	if arg5 eq
	else 
		mov r8, arg5
	end if
	if arg6 eq
	else
		mov r9, arg6
	end if
	syscall
}

macro exit code
{
	sys_call SYS_exit, code
}

macro write fd,buf,buf_len
{
	sys_call SYS_write, fd, buf, buf_len
}

macro close fd
{
	sys_call SYS_close, fd
}

macro socket domain,type,protocol
{
	sys_call SYS_socket, domain, type, protocol
}

macro bind socket,sockaddr,socklen_t
{
	sys_call SYS_bind,socket,sockaddr,socklen_t
}

macro listen socket,backlog
{
	sys_call SYS_listen,socket,backlog
}

macro accept socket, sockaddr,socklen_t
{
	sys_call SYS_accept,socket,sockaddr,socklen_t
}

macro setsockopt socket,level,optname,optval,optlen
{
	sys_call SYS_setsockopt, socket, level, optname, optval, optlen
}

SYS_write  	equ 1
SYS_close  	equ 3
SYS_socket 	equ 41
SYS_accept 	equ 43
SYS_recvmsg	equ 47
SYS_bind   	equ 49
SYS_listen	equ 50
SYS_setsockopt	equ 54
SYS_exit   	equ 60

stdin  equ 0
stdout equ 1
stderr equ 2

EXIT_SUCCESS equ 0
EXIT_FAILURE equ 1

AF_INET 	equ  2
SOCK_STREAM 	equ  1
INADDR_ANY	equ  0
SOL_SOCKET	equ  1
SO_REUSEADDR	equ  2

define PORT 55055
define BACKLOG 10

main:
	socket AF_INET,SOCK_STREAM,0 ; socket syscall returns -1 on error
	cmp rax,0
	jl error
	mov qword [server_socket], rax

	setsockopt [server_socket], SOL_SOCKET, SO_REUSEADDR, reuse_addr, reuse_addr_sz
	cmp rax, 0
	jl error

	mov byte [server_addr.sin_family],AF_INET
	mov eax,PORT
	rol ax,8
	mov word  [server_addr.sin_port], ax
	mov dword [server_addr.sin_addr], INADDR_ANY
	bind [server_socket], server_addr.sin_family,server_addr_sz
	cmp rax, 0
	jl error

	listen [server_socket], BACKLOG
	cmp rax, 0
	jl error

request_loop:
	accept [server_socket], client_addr.sin_family,client_addr_sz
	cmp rax, 0
	jl error

	mov qword [client_socket],rax

	write [client_socket], content, content_sz
	close [client_socket]
	jmp request_loop

	close [client_socket]
	close [server_socket]
	exit  [server_socket]
error:
	write stderr, error_msg, error_msg_sz
	close [client_socket]
	close [server_socket]
	exit EXIT_FAILURE

segment readable writeable 

;typedef uint16_t in_port_t;
;typedef uint32_t in_addr_t;
;struct in_addr { in_addr_t s_addr; };
;
;struct sockaddr_in {
;	sa_family_t sin_family;
;	in_port_t sin_port;
;	struct in_addr sin_addr;
;	uint8_t sin_zero[8];
;}

struc sockaddr_in 
{
	.sin_family dw 0
	.sin_port   dw 0 
	.sin_addr   dd 0
	.sin_zero   dq 0
}

server_socket dq -1
client_socket dq -1
reuse_addr    dd  1
reuse_addr_sz = $ - reuse_addr

server_addr sockaddr_in
server_addr_sz = $ - server_addr.sin_family
client_addr sockaddr_in
client_addr_sz dd server_addr_sz

segment readable

hello_msg db "Hello,World!", 10
hello_msg_sz = $ - hello_msg
error_msg db "Failed to setup the server", 10
error_msg_sz = $ - error_msg

content db 	"HTTP/1.1 200 OK", 13, 10
	db	"Content-Type: text/html; charset=utf-8", 13, 10
	db	"Connection: close", 13, 10, 13, 10
	db	"<h1> Hello,World! </h1>"
content_sz = $ - content 
