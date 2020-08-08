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

int openUDPSocket(const char* remoteHost, int remotePort, int localPort);
int sendUDPDatagram(int sock, const short* data, int len);
void closeUDPSocket(int sock);
int getLocalPort(int sock);

typedef void (*CALLBACK)(void* ref, const short*, int);
void registerCallback(CALLBACK callback, void* ref);

#endif /* udpsocket_h */
