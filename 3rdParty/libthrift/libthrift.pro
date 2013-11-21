TEMPLATE = lib

CONFIG = staticlib

QMAKE_CXXFLAGS += -std=c++0x -fPIC

LIBS += -lssl -lcrypto

DEFINES += HAVE_CONFIG_H

SOURCES += Thrift.cpp \
    TApplicationException.cpp \
    async/TAsyncChannel.cpp \
    async/TAsyncProtocolProcessor.cpp \
    #async/TEvhttpClientChannel.cpp \
    #async/TEvhttpServer.cpp \
    transport/TBufferTransports.cpp \
    transport/TFDTransport.cpp \
    transport/TFileTransport.cpp \
    transport/THttpClient.cpp \
    transport/THttpServer.cpp \
    transport/THttpTransport.cpp \
    transport/TServerSocket.cpp \
    transport/TSimpleFileTransport.cpp \
    transport/TSocket.cpp \
    transport/TSocketPool.cpp \
    transport/TSSLServerSocket.cpp \
    transport/TSSLSocket.cpp \
    transport/TTransportException.cpp \
    transport/TTransportUtils.cpp \
    transport/TZlibTransport.cpp \
    #concurrency/BoostMonitor.cpp \
    #concurrency/BoostMutex.cpp \
    #concurrency/BoostThreadFactory.cpp \
    concurrency/Monitor.cpp \
    concurrency/Mutex.cpp \
    concurrency/PosixThreadFactory.cpp \
    concurrency/ThreadManager.cpp \
    concurrency/TimerManager.cpp \
    concurrency/Util.cpp \

HEADERS += config.h

