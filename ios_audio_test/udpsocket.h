//
//  udpsocket.h
//  ios_audio_test
//
//  Created by Kenji Miura on 2020/08/04.
//  Copyright © 2020 Kenji Miura. All rights reserved.
//

#ifndef udpsocket_h
#define udpsocket_h

#include <stdio.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <pthread.h>

typedef void (*CALLBACK)(void* ref, const short*, int);

struct context {
    CALLBACK callback;
    void* ref;
    pthread_t recvThread;
    int sock;
    struct sockaddr_storage remote;
    socklen_t slen;
    int bRunning;
};

struct context* openUDPSocket(const char* remoteHost, int remotePort, int localPort);
int sendUDPDatagram(struct context* ctx, const short* data, int len);
void closeUDPSocket(struct context* ctx);
void registerCallback(struct context* ctx, CALLBACK callback, void* ref);

#endif /* udpsocket_h */
