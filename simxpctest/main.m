@import Darwin;
@import Metal;
@import QuartzCore;
#import <rootless.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOTypes.h>
#include <IOKit/hid/IOHIDEventSystem.h>
#include <IOKit/hid/IOHIDEventSystemClient.h>

void* _xpc_serializer_pack(uint64_t x0, xpc_object_t x1_inputMsg, uint64_t x2_xpcVersion, uint64_t x3);

kern_return_t bootstrap_look_up(mach_port_t bp, const char *service_name, mach_port_t *sp);
void xpc_add_bundle(char *, int);
void xpc_connection_set_instance(xpc_connection_t, const uuid_t);
void launch_sim_register_endpoint(const char *launchd_sim_name, const char *service_name, mach_port_t service_port);
void xpc_connection_enable_sim2host_4sim(xpc_connection_t, int);

void handle_event(void* target, void* refcon, IOHIDServiceRef service, IOHIDEventRef event) {
    int type = IOHIDEventGetType(event);
    NSLog(@"Got event of type %d", type);
    switch(type) {
        case kIOHIDEventTypeDigitizer:
            NSLog(@"Got digitizer event: %@", event);
            break;
    }
}

IOHIDEventSystemClientRef IOHIDEventSystemClientCreate( CFAllocatorRef );
int main(int argc, char *argv[], char *envp[]) {
    printf("Test IOHID\n");
    IOHIDEventSystemRef systemRef = IOHIDEventSystemCreate(NULL);
    IOHIDEventSystemOpen(systemRef, handle_event, NULL, NULL, NULL);
    IOHIDEventSystemClientRef eventSystemClient = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    IOHIDEventSystemClientScheduleWithRunLoop(IOHIDEventSystemClient(), CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    
    void *handle = dlopen("/System/Library/PrivateFrameworks/BackBoardHIDEventFoundation.framework/BackBoardHIDEventFoundation", RTLD_GLOBAL);
    assert(handle);
    void (*IndigoHIDSystemSpawnLoopback)(IOHIDEventSystemRef) = dlsym(handle, "IndigoHIDSystemSpawnLoopback");
    assert(IndigoHIDSystemSpawnLoopback);
    IndigoHIDSystemSpawnLoopback(systemRef);
    
#if 0
    xpc_connection_t connection;
    xpc_object_t dict;
    xpc_object_t object;
    xpc_object_t (*xpc_connection_create_mach_service)(const char *name, dispatch_queue_t targetq, uint64_t flags) = dlsym(RTLD_DEFAULT, "xpc_connection_create_mach_service");
    assert(xpc_connection_create_mach_service);
    
    printf("Test IOSurface\n");
//    xpc_connection_t connection = xpc_connection_create_mach_service("com.apple.IOSurface.Remote", NULL, 0);
//    xpc_connection_enable_sim2host_4sim(connection, 1);
//    //xpc_connection_set_instance(connection, uuid);
//    xpc_connection_set_event_handler(connection, ^(xpc_object_t object) {
//        printf("Process received event: %s", [object description].UTF8String);
//    });
//    xpc_connection_resume(connection);
//    
//    dict = xpc_dictionary_create(NULL, NULL, 0);
//    xpc_dictionary_set_uint64(dict, "Method", 0);
//    object = xpc_connection_send_message_with_reply_sync(connection, dict);
//    printf("Received synced event: %s\n", [object description].UTF8String);
//    printf("XPC connection now: %s\n", [connection description].UTF8String);
//    sleep(1);
    
    CGRect frame = CGRectMake(0, 0, 100, 100);
//    IOMobileFramebufferRef fbConn;
//    IOMobileFramebufferGetMainDisplay(&fbConn);
//    IOMobileFramebufferGetDisplaySize(fbConn, &frame.size);
//    printf("Got framebuffer size: %fx%f\n", frame.size.width, frame.size.height);
    
    int bytesPerElement = 8;
    NSDictionary *surfaceProps = @{
        //@"IOSurfaceAllocSize": @(totalBytes),
        @"IOSurfaceCacheMode": @1024,
        @"IOSurfaceWidth": @(frame.size.width),
        @"IOSurfaceHeight": @(frame.size.height),
        @"IOSurfaceMapCacheAttribute": @0,
        @"IOSurfaceMemoryRegion": @"PurpleGfxMem",
        @"IOSurfacePixelSizeCastingAllowed": @0,
        @"IOSurfaceBytesPerElement": @(bytesPerElement),
        @"IOSurfacePixelFormat": @((uint32_t)'BGRA'),
    };
    IOSurfaceRef surface = IOSurfaceCreate((__bridge CFDictionaryRef)surfaceProps);
    printf("Got surface: %p\n", surface);
    
    
    
    printf("Test metal\n");

//    char *frameworkPath = "/var/jb/usr/macOS/Frameworks/MTLSimDriver.framework/XPCServices/MTLSimDriverHost.xpc";
//    xpc_add_bundle(frameworkPath, 2);
//    xpc_add_bundle(frameworkPath, 2);

    //uuid_t uuid;
    //uuid_generate(uuid);
    connection = xpc_connection_create_mach_service("com.apple.metal.simulator", NULL, 0);
    xpc_connection_enable_sim2host_4sim(connection, 1);
    //xpc_connection_set_instance(connection, uuid);
    xpc_connection_set_event_handler(connection, ^(xpc_object_t object) {
        printf("Process received event: %s", [object description].UTF8String);
    });
    xpc_connection_resume(connection);
    
    dict = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_uint64(dict, "requestType", 9); // XPCCompilerConnection::checkConnectionActive(bool&)
    object = xpc_connection_send_message_with_reply_sync(connection, dict);
    printf("Received synced event: %s\n", [object description].UTF8String);
    printf("XPC connection now: %s\n", [connection description].UTF8String);
#endif
    
    CFRunLoopRun();
    
    return 0;
}
