format ELF64

public _start

;COSTANTI SYSCALL
syscall_exit = 60
syscall_socket = 41
syscall_accept = 43
syscall_sendfile = 40
syscall_listen = 50
syscall_open = 2
syscall_close = 3
syscall_read = 0
syscall_write = 1
syscall_bind = 49

;COSTANTI FILE DESCRIPTOR
stdout = 1
file_readonly = 0

;COSTANTI PER LA CREAZIONE DEL SOCKET
AF_INET = 2          ;ipv4
SOCK_STREAM = 1      ;tipo di socket tcp
dimensione_address_socket = 1
coda_richieste = 1


path_file_inviabile: db 'index.html', 0

section '.text' executable
    crea_socket:
        ; CREAZIONE DEL SOCKET
        ; CHIAMATA A int socket(int domain, int type, int protocol)

        mov rax, syscall_socket
        mov rdi, AF_INET                ;int domain 4 byte
        mov rsi, SOCK_STREAM            ;int type 4 byte
        mov rdx, 0                      ;int protocol 4 byte
        syscall
        ;il valore ritornato è il file descriptor del socket di 4 byte
        ret

    bind_socket:
        ; BINDING DEL SOCKET
        ; CHIAMATA A int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
        mov rax, syscall_bind
        mov rdi, [socket_fd]            ;int sockfd 4 byte
        mov rsi, protocollo             ;puntatore a socket_address 1 byte a struct da 16 byte
        mov rdx, 16                     ;lunghezza address, è una typedef a un unsigned long da 4 byte
        syscall
        ret

    listen_socket:
        ; AVVIO LISTEN DEL SOCKET
        ; int listen(int sockfd, int backlog);
        mov rax, syscall_listen
        mov rdi, [socket_fd]            ; int sockfd 4 byte
        mov rsi, coda_richieste         ; int coda richieste
        syscall
        ret

    accept_richiesta:
        ;chiamata ad accept
        ; int accept(int sockfd, struct sockaddr *_Nullable restrict addr, socklen_t *_Nullable restrict addrlen)
        mov rax, syscall_accept
        mov rdi, [socket_fd]                            ;int sockfd 4 byte
        mov rsi, 0                                      ; nullable
        mov rdx, 0                                      ; nullable
        syscall
        ret
    
    copia_richiest_in_buffer:
        ;LETTURA DELLA RICHIESTA
        ;il descriptor del client è già creato
        ;ssize_t read(int fd, void buf[.count], size_t count);
        ;read copia sul buffer fornito il contenuto della richiesta
        mov rax, syscall_read
        mov rdi, [client_fd]                                    ; puntatore 1 byte a int 4-byte
        mov rsi, buffer_richiesta_client                ; puntatore 1 byte ad array di 256 * 1 byte
        mov rdx, 256                                    ; dimensione buffer
        syscall
        ret

    _start:

        call crea_socket
        ;copia fd del socket
        mov [socket_fd], rax

        call bind_socket

        call listen_socket

        

        accetta_richiesta_loop:

            call accept_richiesta
            ;output di 4 byte, client file descriptor
            mov [client_fd], rax

            call copia_richiest_in_buffer

            ;apertura del file richiesto
            mov rax, syscall_open
            mov rdi, path_index
            mov rsi, file_readonly
            syscall

            mov [file_richiesto_fd], rax

            ;lettura del buffer dal file inviato
            mov rax, syscall_read
            mov rdi, [file_richiesto_fd]
            mov rsi, buffer_file_richiesto
            mov rdx, 256
            syscall

            mov rax, syscall_write
            mov rdi, [client_fd]
            mov rsi, buffer_file_richiesto
            mov rdx, 256
            syscall

            mov rax, syscall_close
            mov rdi, [client_fd]
            syscall

            mov rax, syscall_close
            mov rdi, [file_richiesto_fd]
            syscall

            ;uscita dal programma con return code 0
            mov rax, syscall_exit
            mov rdi, 0
            syscall

section '.data' writeable

    path_index: db 'index.html', 0

    socket_fd: dw 0
    client_fd: dw 0
    file_richiesto_fd: dw 0
    ;STRUCT ADDRESS, PASSATA A SOCKET
        protocollo dw AF_INET
        porta dw 0x901f
        interfaccia dd 0 ;interfaccia a 0 per occupare tutte le interfacce
        padding dq 0
    ;buffer
    buffer_richiesta_client: db 256 dup 0
    buffer_file_richiesto: db 256 dup 0
    path_file_richiesto: db 256 dup 0