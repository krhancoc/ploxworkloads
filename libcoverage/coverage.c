#include <sys/types.h>
#include <sys/socket.h>
#include <poll.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/select.h>
#include <sys/mman.h>
#include <sys/event.h>
#include <stdio.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <stdarg.h>
#include <string.h>
#include <sys/kcov.h>

#include <pthread.h>

const size_t KCOV_BUF_SIZE =  1ul << 27; // 64 MiB
#define KCOV_DEV_NULL (-420)
_Thread_local int kcov_device = KCOV_DEV_NULL; // We set it to NOT -1, as mmap could have -1 as a fd arg.
_Thread_local int kcov_log = KCOV_DEV_NULL;
_Thread_local uint64_t *kcov_buf = NULL;
const char *KCOV_LOG = "/tmp/kcov.log";
char pbuffer[1024];

#define PRINTF(...) \
	do { \
		snprintf(pbuffer, 1024, __VA_ARGS__); \
		write(2, pbuffer, strlen(pbuffer)); \
	} while (0)

void kcov_startup();
void kcov_done();

#define KCOV_SYS_ARG6(_name, SYS_num, return_type, arg1, arg2, arg3, arg4, arg5, arg6) \
return_type __sys_##_name(arg1, arg2, arg3, arg4, arg5, arg6); \
return_type __plox_##_name(arg1 a, arg2 b, arg3 c, arg4 d, arg5 e, arg6 f) { \
	if (getenv_as_int() == SYS_num) { \
		kcov_startup(); \
	}; \
	return_type returnval = __sys_##_name(a, b, c, d, e, f); \
	if (getenv_as_int() == SYS_num) { \
		kcov_done(); \
	}; \
	return returnval; \
} \
__strong_reference(__plox_##_name, _name)

#define KCOV_SYS_ARG5(_name, SYS_num, return_type, arg1, arg2, arg3, arg4, arg5) \
return_type __sys_##_name(arg1, arg2, arg3, arg4, arg5); \
return_type __plox_##_name(arg1 a, arg2 b, arg3 c, arg4 d, arg5 e) { \
	if (getenv_as_int() == SYS_num) { \
		kcov_startup(); \
	}; \
	return_type returnval = __sys_##_name(a, b, c, d, e); \
	if (getenv_as_int() == SYS_num) { \
		kcov_done(); \
	}; \
	return returnval; \
} \
__strong_reference(__plox_##_name, _name)


#define KCOV_SYS_ARG4(_name, SYS_num, return_type, arg1, arg2, arg3, arg4) \
typedef return_type (* f_##_name)(arg1, arg2, arg3, arg4); \
return_type __sys_##_name(arg1, arg2, arg3, arg4); \
return_type __plox_##_name(arg1 a, arg2 b, arg3 c, arg4 d) { \
	if (getenv_as_int() == SYS_num) { \
		kcov_startup(); \
	}; \
	return_type returnval = __sys_##_name(a, b, c, d); \
	if (getenv_as_int() == SYS_num) { \
		kcov_done(); \
	}; \
	return returnval; \
} \
__strong_reference(__plox_##_name, _name) 


#define KCOV_SYS_ARG3(_name, SYS_num, return_type, arg1, arg2, arg3) \
typedef return_type (* f_##_name)(arg1, arg2, arg3); \
return_type __sys_##_name(arg1, arg2, arg3); \
return_type __plox_##_name(arg1 a, arg2 b, arg3 c) { \
	if (getenv_as_int() == SYS_num) { \
		kcov_startup(); \
	}; \
	return_type returnval = __sys_##_name(a, b, c); \
	if (getenv_as_int() == SYS_num) { \
		kcov_done(); \
	}; \
	return returnval; \
} \
__strong_reference(__plox_##_name, _name)

#define KCOV_SYS_ARG2(_name, SYS_num, return_type, arg1, arg2) \
return_type __sys_##_name(arg1, arg2); \
return_type __plox_##_name(arg1 a, arg2 b) { \
	if (getenv_as_int() == SYS_num) { \
		kcov_startup(); \
	}; \
	return_type returnval = __sys_##_name(a, b); \
	if (getenv_as_int() == SYS_num) { \
		kcov_done(); \
	}; \
	return returnval; \
} \
__strong_reference(__plox_##_name, _name)


const char *SYSNUM = "SYSCALL_TRACE_NUMBER";
int getenv_as_int() {
	char* env_value = getenv(SYSNUM);
	if (env_value != NULL) {
		// Use atoi or strtol to convert the environment variable to an integer.
		// Here, we'll use strtol for better error handling.
		char* endptr;
		long int result = strtol(env_value, &endptr, 10);
		// Check for conversion errors
		if (*endptr == '\0') {
			return (int)result;
		} else {
			fprintf(stderr, "Conversion error: %s is not a valid integer.\n", SYSNUM);
		}
	} else {
		fprintf(stderr, "Environment variable %s not found.\n", SYSNUM);
	}

	return -1;
}


KCOV_SYS_ARG3(accept, SYS_accept, int, int, struct sockaddr *, socklen_t *);
KCOV_SYS_ARG4(accept4, SYS_accept4, int, int, struct sockaddr *, socklen_t *, int);
KCOV_SYS_ARG6(mmap, SYS_mmap, void *, void *,  size_t, int, int, int, off_t);
KCOV_SYS_ARG3(connect, SYS_connect, int, int, const struct sockaddr *, socklen_t);
KCOV_SYS_ARG4(fstatat, SYS_fstatat, int, int, const char *, struct stat *, int);
KCOV_SYS_ARG3(poll, SYS_poll, int, struct pollfd *, unsigned, int);
KCOV_SYS_ARG3(read, SYS_read, ssize_t, int, void *, size_t);
KCOV_SYS_ARG3(write, SYS_write, ssize_t, int, const void *, size_t);
KCOV_SYS_ARG5(select, SYS_select, int, int, struct fd_set *, struct fd_set *, struct fd_set *, struct timeval *);
KCOV_SYS_ARG6(recvfrom, SYS_recvfrom, ssize_t, int, void *, size_t, int, struct sockaddr *, socklen_t *);
KCOV_SYS_ARG6(sendto, SYS_sendto, ssize_t, int, const void *, size_t, int, const struct sockaddr *, socklen_t);
KCOV_SYS_ARG3(sendmsg, SYS_sendmsg, ssize_t, int, const struct msghdr *, int);
KCOV_SYS_ARG3(recvmsg, SYS_recvmsg, ssize_t, int, struct msghdr *, int);
KCOV_SYS_ARG2(truncate, SYS_truncate, int, const char *, off_t);
KCOV_SYS_ARG2(ftruncate, SYS_ftruncate, int, int, off_t);
KCOV_SYS_ARG3(socket, SYS_socket, int, int, int, int);
KCOV_SYS_ARG3(bind, SYS_bind, int, int, const struct sockaddr *, socklen_t);
KCOV_SYS_ARG2(listen, SYS_listen, int, int, int);
KCOV_SYS_ARG5(setsockopt, SYS_setsockopt, int, int, int, int, const void *, socklen_t);
KCOV_SYS_ARG5(getsockopt, SYS_getsockopt, int, int, int, int, void *, socklen_t *);
KCOV_SYS_ARG6(kevent, SYS_kevent, int, int, const struct kevent *, int, struct kevent *, int, const struct timespec *);

// open and ioctl needs to pull out va_args to be passed forward.
int __sys_open(const char *, int, ...);
int __plox_open(const char *path, int flags, ...) {
	int mode;
	va_list args;

	if((flags & O_CREAT) != 0) {
		va_start(args, flags);
		mode = va_arg(args, int);
		va_end(args);
	} else {
		mode = 0;
	}

	if (strncmp(path, "/dev/kcov", 9) == 0) {
		return __sys_open(path, flags, mode);
	}

	if (getenv_as_int() == SYS_open) {
		kcov_startup();
	}

	int returnval = __sys_open(path, flags, mode);

	if (getenv_as_int() == SYS_open) {
		kcov_done();
	}

	return returnval;
}
__strong_reference(__plox_open, open); 

int __sys_ioctl(int fd, unsigned long request, ...);
int __plox_ioctl(int fd, unsigned long request, ...) {
	va_list args;

	va_start(args, request);
	uint64_t inout = va_arg(args, uint64_t);
	va_end(args);

	if (fd == kcov_device)
		return __sys_ioctl(fd, request, inout);

	if (getenv_as_int() == SYS_open) {
		kcov_startup();
	}

	int returnval = __sys_ioctl(fd, request, inout);
	if (getenv_as_int() == SYS_open) {
		kcov_done();
	}
	return returnval;
}
__strong_reference(__plox_ioctl, ioctl); 

int __sys_fcntl(int fd, int request, ...);
int __plox_fcntl(int fd, int request, ...) {
	va_list args;

	va_start(args, request);
	uint64_t inout = va_arg(args, uint64_t);
	va_end(args);

	if (getenv_as_int() == SYS_fcntl) {
		kcov_startup();
	}

	int returnval = __sys_fcntl(fd, request, inout);
	if (getenv_as_int() == SYS_fcntl) {
		kcov_done();
	}
	return returnval;
}
__strong_reference(__plox_fcntl, fcntl); 



void kcov_startup() {
	if (kcov_device == KCOV_DEV_NULL) {
		kcov_device = __sys_open("/dev/kcov", O_RDWR, 0);
		if (kcov_device == -1)  {
			printf("Problem loading kcov device");
			exit(-1);
		}

		if (syscall(SYS_ioctl, kcov_device, KIOSETBUFSIZE, KCOV_BUF_SIZE / KCOV_ENTRY_SIZE) != 0) {
			perror("Problem with ioctl");
			exit(-1);
		}

		kcov_log = __sys_open(KCOV_LOG, O_WRONLY | O_APPEND | O_CREAT, 0666);
		if (kcov_log == -1 && errno == EPERM)
			kcov_log = syscall(SYS_open, KCOV_LOG, O_WRONLY | O_APPEND);

		if (kcov_log == -1) {
			perror("Problem opening kcov log");
			exit(-1);
		}

		kcov_buf = __sys_mmap(NULL, KCOV_BUF_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, kcov_device, 0);
		if (kcov_buf == MAP_FAILED) {
			perror("Problem mapping kcov buf");
			exit(-1);
		}
	}

	if (ioctl(kcov_device, KIOENABLE, KCOV_MODE_TRACE_PC) != 0) {
		perror("Problem with KIOENABLE");
	}

	kcov_buf[0] = 0;
	return;
}

void kcov_done() {
	char buf[256];

	if (ioctl(kcov_device, KIODISABLE, 0) != 0) {
		perror("Problem with KIODISABLE");
	}

	for (uint64_t i = 1; i < kcov_buf[0]; i++) {
		snprintf(buf, 256, "%#jx\n", (uintmax_t)kcov_buf[i]) ;
		__sys_write(kcov_log, buf, strlen(buf));
	}

	return;
}



