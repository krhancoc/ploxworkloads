#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>

#include <sys/types.h>
#include <sys/prctl.h>
#include <sys/syscall.h>
#include <sys/socket.h>

#include <linux/filter.h>
#include <linux/seccomp.h>
#include <linux/audit.h>


#define ArchField offsetof(struct seccomp_data, arch)

#define Allow(syscall) \
    BPF_JUMP(BPF_JMP+BPF_JEQ+BPF_K, __NR_##syscall, 0, 1), \
    BPF_STMT(BPF_RET+BPF_K, SECCOMP_RET_ALLOW)

struct sock_filter lighttpd_filter[] = {
    /* validate arch */
    BPF_STMT(BPF_LD+BPF_W+BPF_ABS, ArchField),
    BPF_JUMP( BPF_JMP+BPF_JEQ+BPF_K, AUDIT_ARCH_X86_64, 1, 0),
    BPF_STMT(BPF_RET+BPF_K, SECCOMP_RET_KILL),
    Allow(execve),
    Allow(brk),
    Allow(arch_prctl),
    Allow(mmap),
    Allow(access),
    Allow(openat),
    Allow(newfstatat),
    Allow(close),
    Allow(read),
    Allow(pread64),
    Allow(set_tid_address),
    Allow(set_robust_list),
    Allow(rseq),
    Allow(mprotect),
    Allow(prlimit64),
    Allow(munmap),
    Allow(getuid),
    Allow(getrandom),
    Allow(lseek),
    Allow(getcwd),
    Allow(getpid),
    Allow(dup2),
    Allow(socket),
    Allow(fcntl),
    Allow(setsockopt),
    Allow(bind),
    Allow(listen),
    Allow(rt_sigaction),
    Allow(getgid),
    Allow(write),
    Allow(epoll_create1),
    Allow(epoll_ctl),
    Allow(pipe2),
    Allow(epoll_wait),
    Allow(sysinfo),
    Allow(accept4),
    Allow(getsockopt),
    Allow(shutdown),
    Allow(recvfrom),
    Allow(writev),
    Allow(rt_sigreturn),
    Allow(exit_group),

    /* load syscall */
    BPF_STMT(BPF_LD+BPF_W+BPF_ABS, offsetof(struct seccomp_data, nr)),
    /* and if we don't match above, die */
    BPF_STMT(BPF_RET+BPF_K, SECCOMP_RET_KILL),
};

struct sock_filter nginx_filter[] = {
    /* validate arch */
    BPF_STMT(BPF_LD+BPF_W+BPF_ABS, ArchField),
    BPF_JUMP( BPF_JMP+BPF_JEQ+BPF_K, AUDIT_ARCH_X86_64, 1, 0),
    BPF_STMT(BPF_RET+BPF_K, SECCOMP_RET_KILL),

    /* load syscall */
    BPF_STMT(BPF_LD+BPF_W+BPF_ABS, offsetof(struct seccomp_data, nr)),

    Allow(execve),
    Allow(brk),
    Allow(arch_prctl),
    Allow(mmap),
    Allow(access),
    Allow(openat),
    Allow(newfstatat),
    Allow(close),
    Allow(read),
    Allow(mprotect),
    Allow(pread64),
    Allow(set_tid_address),
    Allow(set_robust_list),
    Allow(rseq),
    Allow(prlimit64),
    Allow(munmap),
    Allow(getrandom),
    Allow(lseek),
    Allow(getpid),
    Allow(getppid),
    Allow(futex),
    Allow(sysinfo),
    Allow(uname),
    Allow(epoll_create),
    Allow(geteuid),
    Allow(socket),
    Allow(connect),
    Allow(mkdir),
    Allow(fcntl),
    Allow(setsockopt),
    Allow(ioctl),
    Allow(bind),
    Allow(listen),
    Allow(rt_sigaction),
    Allow(pwrite64),
    Allow(dup2),
    Allow(rt_sigprocmask),
    Allow(socketpair),
    Allow(clone),
    Allow(rt_sigsuspend),
    Allow(setgid),
    Allow(setgroups),
    Allow(setuid),
    Allow(prctl),
    Allow(eventfd2),
    Allow(epoll_ctl),
    Allow(epoll_wait),
    Allow(accept4),
    Allow(recvfrom),
    Allow(gettid),
    Allow(write),
    Allow(writev),
    Allow(rt_sigreturn),
    Allow(sendmsg),
    Allow(setitimer),
    Allow(exit_group),
    Allow(wait4),
    Allow(unlink),
    /* and if we don't match above, die */
    BPF_STMT(BPF_RET+BPF_K, SECCOMP_RET_KILL),
};


struct sock_filter memcached_filter[] = {
    /* validate arch */
    BPF_STMT(BPF_LD+BPF_W+BPF_ABS, ArchField),
    BPF_JUMP( BPF_JMP+BPF_JEQ+BPF_K, AUDIT_ARCH_X86_64, 1, 0),
    BPF_STMT(BPF_RET+BPF_K, SECCOMP_RET_KILL),

    /* load syscall */
    BPF_STMT(BPF_LD+BPF_W+BPF_ABS, offsetof(struct seccomp_data, nr)),
    Allow(execve),
    Allow(brk),
    Allow(arch_prctl),
    Allow(mmap),
    Allow(access),
    Allow(openat),
    Allow(newfstatat),
    Allow(close),
    Allow(read),
    Allow(mprotect),
    Allow(pread64),
    Allow(set_tid_address),
    Allow(set_robust_list),
    Allow(rseq),
    Allow(prlimit64),
    Allow(munmap),
    Allow(getrandom),
    Allow(rt_sigaction),
    Allow(getuid),
    Allow(socket),
    Allow(connect),
    Allow(lseek),
    Allow(setgroups),
    Allow(setgid),
    Allow(setuid),
    Allow(geteuid),
    Allow(getgid),
    Allow(getegid),
    Allow(epoll_create1),
    Allow(pipe2),
    Allow(rt_sigprocmask),
    Allow(clone3),
    Allow(dup),
    Allow(futex),
    Allow(eventfd2),
    Allow(epoll_ctl),
    Allow(epoll_wait),
    Allow(fcntl),
    Allow(clock_nanosleep),
    Allow(setsockopt),
    Allow(bind),
    Allow(listen),
    Allow(accept4),
    Allow(write),
    Allow(getpeername),
    Allow(sendmsg),
    Allow(rt_sigreturn),
    Allow(madvise),
    Allow(exit),
    Allow(exit_group),
    /* and if we don't match above, die */
    BPF_STMT(BPF_RET+BPF_K, SECCOMP_RET_KILL),
};



struct sock_filter redis_filter[] = {
    /* validate arch */
    BPF_STMT(BPF_LD+BPF_W+BPF_ABS, ArchField),
    BPF_JUMP( BPF_JMP+BPF_JEQ+BPF_K, AUDIT_ARCH_X86_64, 1, 0),
    BPF_STMT(BPF_RET+BPF_K, SECCOMP_RET_KILL),

    /* load syscall */
    BPF_STMT(BPF_LD+BPF_W+BPF_ABS, offsetof(struct seccomp_data, nr)),
    Allow(execve),
    Allow(brk),
    Allow(arch_prctl),
    Allow(mmap),
    Allow(access),
    Allow(openat),
    Allow(newfstatat),
    Allow(close),
    Allow(read),
    Allow(munmap),
    Allow(mprotect),
    Allow(pread64),
    Allow(set_tid_address),
    Allow(set_robust_list),
    Allow(rseq),
    Allow(prlimit64),
    Allow(readlink),
    Allow(open),
    Allow(madvise),
    Allow(prctl),
    Allow(lseek),
    Allow(getpid),
    Allow(umask),
    Allow(ioctl),
    Allow(pipe2),
    Allow(fcntl),
    Allow(futex),
    Allow(sysinfo),
    Allow(chdir),
    Allow(clone),
    Allow(setsid),
    Allow(dup2),
    Allow(exit_group),
    Allow(write),
    Allow(rt_sigaction),
    Allow(epoll_create),
    Allow(socket),
    Allow(setsockopt),
    Allow(bind),
    Allow(listen),
    Allow(epoll_ctl),
    Allow(rt_sigprocmask),
    Allow(clone3),
    Allow(epoll_wait),
    Allow(accept),
    /* and if we don't match above, die */
    BPF_STMT(BPF_RET+BPF_K, SECCOMP_RET_KILL),
};


int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <program> [arg1] [arg2] ...\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    struct sock_fprog filterprog;

    if (strncmp(argv[1], "redis", 5) == 0) {
        filterprog.len = sizeof(redis_filter)/sizeof(redis_filter[0]);
        filterprog.filter = redis_filter;
    } else if (strncmp(argv[1], "memcached", 9) == 0) {
        filterprog.len = sizeof(memcached_filter)/sizeof(memcached_filter[0]);
        filterprog.filter = memcached_filter;
    } else if (strncmp(argv[1], "nginx", 5) == 0) {
        filterprog.len = sizeof(nginx_filter)/sizeof(nginx_filter[0]);
        filterprog.filter = nginx_filter;
    } else if (strncmp(argv[1], "lighttpd", 8) == 0) {
        filterprog.len = sizeof(lighttpd_filter)/sizeof(lighttpd_filter[0]);
        filterprog.filter = lighttpd_filter;
    } else {
      fprintf(stderr, "Usage: %s <program> [arg1] [arg2] ...\n", argv[0]);
      exit(EXIT_FAILURE);
    }

    // Set process name to the executed program for clarity
    prctl(PR_SET_NAME, argv[2]);
    /* set up the restricted environment */
    if (prctl(PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0)) {
        perror("Could not start seccomp:");
        exit(1);
    }
    if (prctl(PR_SET_SECCOMP, SECCOMP_MODE_FILTER, &filterprog) == -1) {
        perror("Could not start seccomp:");
        exit(1);
    }


    // Execute the specified program with its arguments
    execvp(argv[2], &argv[2]);

    // If execvp fails, print an error message
    perror("execvp");
    exit(EXIT_FAILURE);

    return 0; // This line is never reached
}
