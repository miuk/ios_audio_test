//
//  udpsocket.c
//  ios_audio_test
//
//  Created by Kenji Miura on 2020/08/04.
//  Copyright © 2020 Kenji Miura. All rights reserved.
//

#include "udpsocket.h"

#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <netdb.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <poll.h>

static CALLBACK s_callback = NULL;
static void* s_ref = NULL;
static pthread_t s_recvThread;
static int s_sock = -1;

void
registerCallback(CALLBACK callback, void* ref)
{
    s_callback = callback;
    s_ref = ref;
}

static void*
recv_routine(void* arg)
{
    printf("recv_routine start\n");
    for (;;) {
        struct pollfd ev;
        ev.fd = s_sock;
        ev.events = POLLIN;
        int ret = poll(&ev, 1, 100);
        if (ret < 0) {
            perror("poll");
            break;
        }
        if (ret == 0) {
            break;
        }
        struct sockaddr_storage ss;
        socklen_t slen = sizeof(ss);
        char buf[2048];
        ret = (int)recvfrom(s_sock, buf, sizeof(buf), 0
                            , (struct sockaddr*)&ss, &slen);
        if (ret < 0) {
            perror("recvfrom");
            break;
        }
        /*printf("recv %d\n", ret);*/
        if (s_callback != NULL && ret > 0) {
            s_callback(s_ref, (const short*)buf, ret / 2);
        }
    }
    printf("recv_routine finish\n");
    return NULL;
}

int
openUDPSocket(const char* remoteHost, int remotePort, int localPort)
{
    struct addrinfo* res = NULL;
    struct addrinfo hints;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = PF_INET;
    hints.ai_socktype = SOCK_DGRAM;
    hints.ai_flags = AI_PASSIVE;
    char portstr[32];
    sprintf(portstr, "%d", localPort);
    int err = getaddrinfo(NULL, portstr, &hints, &res);
    if (err != 0) {
        printf("getaddrinfo failed: %s\n", gai_strerror(err));
        return -1;
    }
    int sock = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (sock < 0) {
        perror("socket");
        freeaddrinfo(res);
        return -1;
    }
    int opt = 1;
    setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    if (bind(sock, res->ai_addr, res->ai_addrlen) < 0) {
        freeaddrinfo(res);
        close(sock);
        return -1;
    }
    freeaddrinfo(res);
    sprintf(portstr, "%d", remotePort);
    err = getaddrinfo(remoteHost, portstr, &hints, &res);
    if (err != 0) {
        printf("getaddrinfo failed: %s\n", gai_strerror(err));
        close(sock);
        return -1;
    }
    if (connect(sock, res->ai_addr, res->ai_addrlen) < 0) {
        perror("connect");
        freeaddrinfo(res);
        close(sock);
        return -1;
    }

    s_sock = sock;
    pthread_create(&s_recvThread, NULL, recv_routine, NULL);

    return sock;
}

int
sendUDPDatagram(int sock, const short* data, int len)
{
    ssize_t ret = send(sock, data, sizeof(short) * len, 0);
    /*printf("send %d %zd\n", len, ret);*/
    return (int)ret;
}

void
closeUDPSocket(int sock)
{
    close(sock);
    s_sock = -1;
    void* arg = NULL;
    pthread_join(s_recvThread, arg);
}

int
getLocalPort(int sock)
{
    struct sockaddr_storage ss;
    socklen_t slen = sizeof(ss);
    if (getsockname(sock, (struct sockaddr*)&ss, &slen) != 0) {
        perror("getsockname");
        return -1;
    }
    struct sockaddr_in* sin = (struct sockaddr_in*)&ss;
    return ntohs(sin->sin_port);
}
