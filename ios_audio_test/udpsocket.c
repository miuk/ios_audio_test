//
//  udpsocket.c
//  ios_audio_test
//
//  Created by Kenji Miura on 2020/08/04.
//  Copyright © 2020 Kenji Miura. All rights reserved.
//

#include "udpsocket.h"

#include <netdb.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <poll.h>

static void*
recv_routine(void* arg)
{
    struct context* ctx = (struct context*)arg;
    printf("recv_routine start\n");
    while (ctx->bRunning) {
        struct pollfd ev;
        ev.fd = ctx->sock;
        ev.events = POLLIN;
        int ret = poll(&ev, 1, 100);
        if (ret < 0) {
            perror("poll");
            break;
        }
        if (ret == 0) {
            continue;
        }
        struct sockaddr_storage ss;
        socklen_t slen = sizeof(ss);
        char buf[2048];
        ret = (int)recvfrom(ctx->sock, buf, sizeof(buf), 0
                            , (struct sockaddr*)&ss, &slen);
        if (ret < 0) {
            perror("recvfrom");
            break;
        }
        /*printf("recv %d\n", ret);*/
        if (ctx->callback != NULL && ret > 0) {
            ctx->callback(ctx->ref, (const short*)buf, ret / 2);
        }
    }
    printf("recv_routine finish\n");
    return NULL;
}

struct context*
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
        return NULL;
    }
    int sock = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (sock < 0) {
        perror("socket");
        freeaddrinfo(res);
        return NULL;
    }
    int opt = 1;
    setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    if (bind(sock, res->ai_addr, res->ai_addrlen) < 0) {
        freeaddrinfo(res);
        close(sock);
        return NULL;
    }
    freeaddrinfo(res);
    sprintf(portstr, "%d", remotePort);
    err = getaddrinfo(remoteHost, portstr, &hints, &res);
    if (err != 0) {
        printf("getaddrinfo failed: %s\n", gai_strerror(err));
        close(sock);
        return NULL;
    }
    struct context* ctx = (struct context*)malloc(sizeof(struct context));
    memset(ctx, 0, sizeof(struct context));
    memcpy(&ctx->remote, res->ai_addr, res->ai_addrlen);
    ctx->slen = res->ai_addrlen;
    freeaddrinfo(res);
    ctx->sock = sock;
    ctx->bRunning = 1;
    pthread_create(&ctx->recvThread, NULL, recv_routine, ctx);

    return ctx;
}

int
sendUDPDatagram(struct context* ctx, const short* data, int len)
{
    ssize_t ret = sendto(ctx->sock, data, sizeof(short) * len, 0, (struct sockaddr*)&ctx->remote, ctx->slen);
    /*printf("send %d %zd\n", len, ret);*/
    return (int)ret;
}

void
closeUDPSocket(struct context* ctx)
{
    if (ctx == NULL)
        return;
    ctx->bRunning = 0;
    close(ctx->sock);
    void* arg = NULL;
    pthread_join(ctx->recvThread, &arg);
    free(ctx);
}

void
registerCallback(struct context* ctx, CALLBACK callback, void* ref)
{
    ctx->callback = callback;
    ctx->ref = ref;
}
