pkg_search_module(SSL openssl REQUIRED)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
)

add_definitions( -DHAVE_CONFIG_H )

SET(libthrift_SRCS
    Thrift.cpp
    TApplicationException.cpp
    async/TAsyncChannel.cpp
    async/TAsyncProtocolProcessor.cpp
    #async/TEvhttpClientChannel.cpp
    #async/TEvhttpServer.cpp
    transport/TBufferTransports.cpp
    transport/TFDTransport.cpp
    transport/TFileTransport.cpp
    transport/THttpClient.cpp
    transport/THttpServer.cpp
    transport/THttpTransport.cpp
    transport/TServerSocket.cpp
    transport/TSimpleFileTransport.cpp
    transport/TSocket.cpp
    transport/TSocketPool.cpp
    transport/TSSLServerSocket.cpp
    transport/TSSLSocket.cpp
    transport/TTransportException.cpp
    transport/TTransportUtils.cpp
    transport/TZlibTransport.cpp
    #concurrency/BoostMonitor.cpp
    #concurrency/BoostMutex.cpp
    #concurrency/BoostThreadFactory.cpp
    concurrency/Monitor.cpp
    concurrency/Mutex.cpp
    concurrency/PosixThreadFactory.cpp
    concurrency/ThreadManager.cpp
    concurrency/TimerManager.cpp
    concurrency/Util.cpp
)

add_library(libthrift STATIC ${libthrift_SRCS})
target_link_libraries(libthrift ${SSL_LDFLAGS})
