//
//  SimRenderServer.m
//  SimulatorShimFrameworks
//
//  Created by Duy Tran on 26/9/25.
//

@import Darwin;
@import Foundation;
@import IOSurface;

@interface IOSurfaceRemoteServer : NSObject
- (instancetype)initWithListener:(xpc_connection_t)listener options:(NSDictionary *)options;
@end

void fixed_xpc_connection_enable_sim2host_4sim(xpc_connection_t connection) {
    if (xpc_get_type(connection) != XPC_TYPE_CONNECTION) {
        fprintf(stderr, "Given object not of required type.\n");
        abort();
    }
    char *connection_ptr = (__bridge void *)connection;
    if (*(uint32_t *)(connection_ptr + 0x40) != 0) {
        fprintf(stderr, "Attempt to change the sim-to-host mode on a live connection.");
        abort();
    }
    // on iOS, this is set to 2 which turns out to be inaccurate
    // on macOS, this is set to 0
    *(uint32_t *)(connection_ptr + 0xC0) = 0;
}

// decompiled from MTLSimDriverHost.xpc with some modifications
xpc_connection_t xpc_connection_create_listener(const char* name, dispatch_queue_t queue);
xpc_connection_t xpc_connection_create_mach_service(const char *name, dispatch_queue_t targetq, uint64_t flags);
int main(int argc, const char **argv, const char **envp) {
    static IOSurfaceRemoteServer *server;
    xpc_object_t (*xpc_connection_create_mach_service)(const char *name, dispatch_queue_t targetq, uint64_t flags) = dlsym(RTLD_DEFAULT, "xpc_connection_create_mach_service");
    // com.apple.accelerator.iosurface
    xpc_connection_t peerConnection = xpc_connection_create_mach_service("com.apple.IOSurface.Remote", dispatch_get_main_queue(), XPC_CONNECTION_MACH_SERVICE_LISTENER);
    fixed_xpc_connection_enable_sim2host_4sim(peerConnection);
    dispatch_async(dispatch_get_main_queue(), ^{
        server = [[IOSurfaceRemoteServer alloc] initWithListener:peerConnection options:@{}];
    });
    dispatch_main();
}
