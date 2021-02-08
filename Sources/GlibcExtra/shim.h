#include <sys/resource.h>
#include <stdio.h>
#include <zlib.h>
#include <pty.h>
#include <sys/epoll.h>
#include <sys/timerfd.h>
#include <sys/signalfd.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/select.h>
#include <sys/inotify.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/wait.h>

//openssl
// #include <openssl/ssl.h>
// #include <openssl/err.h>
// #include <openssl/evp.h>
// #include <openssl/sha.h>
// #include <openssl/md5.h>

#ifdef __cplusplus
extern "C" {
#endif


static pid_t cwait (int * status) {
    return wait(status);
}

static int cstat(const char *pathname, struct stat *statbuf) {
    return stat(pathname, statbuf);
}


static int fcntl_int(int fd, int cmd) {
    return fcntl(fd, cmd);
}

static int fcntl_int_int(int fd, int cmd, int arg) {
    return fcntl(fd, cmd, arg);
}

static int fcntl_int_string(int fd, int cmd, const char* arg) {
    return fcntl(fd, cmd, arg);
}

static int C_S_ISREG (mode_t mode) {
    return S_ISREG(mode);
}

static int C_S_ISDIR (mode_t mode) {
    return S_ISDIR(mode);
}

static int C_S_ISLNK (mode_t mode) {
    return S_ISLNK(mode);
}

static int C_S_ISCHR (mode_t mode) {
    return S_ISCHR(mode);
}

static int C_S_ISBLK (mode_t mode) {
    return S_ISBLK(mode);
}


static int C_S_ISFIFO (mode_t mode) {
    return S_ISFIFO(mode);
}


static int C_S_ISSOCK (mode_t mode) {
    return S_ISSOCK(mode);
}

#ifdef __cplusplus
}
#endif


