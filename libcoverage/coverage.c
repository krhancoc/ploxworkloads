#include <sys/types.h>
#include <sys/socket.h>
#include <poll.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/select.h>
#include <sys/mman.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <stdarg.h>
#include <string.h>
#include <sys/kcov.h>

#include <pthread.h>

const size_t KCOV_BUF_SIZE =  1ul << 26; // 64 MiB
__thread int kcov_device = -1;
__thread int kcov_log = -1;
__thread uint64_t *kcov_buf = NULL;
//pthread_mutex_t kcov_lock = PTHREAD_MUTEX_INITIALIZER;
const char *KCOV_LOG = "/tmp/kcov.log";

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
__strong_reference(__plox_##_name, _name); \
__strong_reference(__plox_##_name, _##_name)

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
__strong_reference(__plox_##_name, _name); \
__strong_reference(__plox_##_name, _##_name)


#define KCOV_SYS_ARG4(_name, SYS_num, return_type, arg1, arg2, arg3, arg4) \
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
__strong_reference(__plox_##_name, _name); \
__strong_reference(__plox_##_name, _##_name)


#define KCOV_SYS_ARG3(_name, SYS_num, return_type, arg1, arg2, arg3) \
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
__strong_reference(__plox_##_name, _name); \
__strong_reference(__plox_##_name, _##_name)
  
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
__strong_reference(__plox_##_name, _name); \
__strong_reference(__plox_##_name, _##_name)


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
KCOV_SYS_ARG3(connect, SYS_connect, int, int, const struct sockaddr *, socklen_t);
KCOV_SYS_ARG4(fstatat, SYS_fstatat, int, int, const char *, struct stat *, int);
KCOV_SYS_ARG6(mmap, SYS_mmap, void *, void *, size_t, int, int, int, off_t);
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

int __sys_open(const char *, int, ...);
int __plox_open(const char *path, int flags, ...) {
  int mode;
  va_list args;

  if (getenv_as_int() == SYS_open) {
    kcov_startup();
  }

  if((flags & O_CREAT) != 0) {
    va_start(args, flags);
    mode = va_arg(args, int);
    va_end(args);
  } else {
    mode = 0;
  }

  int returnval = __sys_open(path, flags, mode);
  if (getenv_as_int() == SYS_open) {
    kcov_done();
  }
  return returnval;
}

__strong_reference(__plox_open, open); 
__strong_reference(__plox_open, _open);

int __sys_ioctl(int fd, unsigned long request, ...);
int __plox_ioctl(int fd, unsigned long request, ...) {
  va_list args;

  if (getenv_as_int() == SYS_open) {
    kcov_startup();
  }
  va_start(args, request);
  uint64_t inout = va_arg(args, uint64_t);
  va_end(args);

  int returnval = __sys_ioctl(fd, request, inout);
  if (getenv_as_int() == SYS_open) {
    kcov_done();
  }
  return returnval;
}
__strong_reference(__plox_ioctl, ioctl); 
__strong_reference(__plox_ioctl, _ioctl);



void kcov_startup() {
  if (kcov_device == -1) {
    kcov_device = __sys_open("/dev/kcov", O_RDWR, 0);
    if (kcov_device == -1)  {
      perror("Problem loading kcov device");
      exit(-1);
    }
    kcov_log = __sys_open(KCOV_LOG, O_APPEND | O_CREAT, 0666);
    if (kcov_log == -1 && errno == EPERM)
      kcov_log = __sys_open(KCOV_LOG, O_APPEND, 0666);

    if (kcov_log == -1) {
      perror("Problem opening kcov log");
      exit(-1);
    }

    kcov_buf = mmap(NULL, KCOV_BUF_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, kcov_device, 0);
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
  for (uint64_t i = 1; i < buf[0]; i++) {
    snprintf(buf, 256, "%#jx\n", (uintmax_t)buf[i]) ;
    write(kcov_log, buf, strlen(buf));
  }

  if (ioctl(kcov_device, KIODISABLE, 0) != 0) {
    perror("Problem with KIODISABLE");
  }

  return;
}



