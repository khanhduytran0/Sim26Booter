@import Darwin;
@import Foundation;
#import <rootless.h>

kern_return_t bootstrap_look_up(mach_port_t bp, const char *service_name, mach_port_t *sp);
void (*launch_sim_register_endpoint)(const char *launchd_sim_name, const char *service_name, mach_port_t service_port);
void xpc_add_bundle(const char *, int);
void xpc_connection_enable_sim2host_4sim(xpc_connection_t);
mach_port_t xpc_endpoint_copy_listener_port_4sim(xpc_object_t endpoint);

mach_port_t spawn_metal_simulator() {
    //xuuid_t uuid;
    //uuid_generate(uuid);
    static xpc_connection_t connection = NULL;
    connection = xpc_connection_create("com.apple.metal.simulator", NULL);
    //xpc_connection_set_instance(connection, uuid);
    xpc_connection_set_event_handler(connection, ^(xpc_object_t object) {
        NSLog(@"Process received event: %@", [object description]);
    });
    xpc_connection_enable_sim2host_4sim(connection);
    //xpc_connection_activate(connection);
    
    xpc_endpoint_t endpoint = xpc_endpoint_create(connection);
    mach_port_t port = xpc_endpoint_copy_listener_port_4sim(endpoint);
    assert(port != MACH_PORT_NULL);
    NSLog(@"Obtained port: 0x%x", port);
    return port;
}

mach_port_t spawn_iosurface_server() {
    //xuuid_t uuid;
    //uuid_generate(uuid);
    static xpc_connection_t connection = NULL;
    connection = xpc_connection_create("com.apple.IOSurface.Remote", NULL);
    //xpc_connection_set_instance(connection, uuid);
    xpc_connection_set_event_handler(connection, ^(xpc_object_t object) {
        NSLog(@"Process received event: %@", [object description]);
    });
    xpc_connection_enable_sim2host_4sim(connection);
    //xpc_connection_activate(connection);
    
    xpc_endpoint_t endpoint = xpc_endpoint_create(connection);
    mach_port_t port = xpc_endpoint_copy_listener_port_4sim(endpoint);
    assert(port != MACH_PORT_NULL);
    NSLog(@"Obtained port: 0x%x", port);
    return port;
}

void *dlopen_or_exit(const char *path) {
    void *handle = dlopen(path, RTLD_GLOBAL);
    if (!handle) {
        printf("Failed to dlopen %s: %s\n", path, dlerror());
        exit(1);
    } else {
        printf("Successfully dlopened %s\n", path);
    }
    return handle;
}

void validate_launchd_sim_connection() {
    const char *label = getenv("LAUNCHD_SIM_LABEL");
    mach_port_t port = MACH_PORT_NULL;
    bootstrap_look_up(bootstrap_port, label, &port);
    if(port == MACH_PORT_NULL) {
        printf("Failed to look up launchd_sim port for label %s\n", label);
        exit(1);
    }
}

int main(int argc, char *argv[], char *envp[]) {
    // other services:
    // "com.apple.accelerator.iosurface"
    
    setenv("LAUNCHD_SIM_LABEL", "com.apple.CoreSimulator.SimDevice.00000000-0000-0000-0000-000000000000", 0);
    validate_launchd_sim_connection();
    
    void *liblaunch_sim = dlopen_or_exit("/var/jb/iOSSimRootFS/usr/lib/system/host/liblaunch_sim.dylib");
    launch_sim_register_endpoint = dlsym(liblaunch_sim, "launch_sim_register_endpoint");
    assert(launch_sim_register_endpoint);
    
    const char *iosurfaceXPCPath = JBROOT_PATH("/usr/macOS/Frameworks/MTLSimDriver.framework/XPCServices/SimRenderServer.xpc");
    if(access(iosurfaceXPCPath, F_OK) != 0) {
        printf("SimRenderServer XPC service not found at %s\n", iosurfaceXPCPath);
        exit(1);
    }
    xpc_add_bundle(iosurfaceXPCPath, 2);
    
    const char *metalXPCPath = JBROOT_PATH("/usr/macOS/Frameworks/MTLSimDriver.framework/XPCServices/MTLSimDriverHost.xpc");
    if(access(metalXPCPath, F_OK) != 0) {
        printf("Metal XPC service not found at %s\n", metalXPCPath);
        exit(1);
    }
    xpc_add_bundle(metalXPCPath, 2);
    
    mach_port_t iosurface_port = spawn_iosurface_server();
    mach_port_t metal_port = spawn_metal_simulator();
    launch_sim_register_endpoint(getenv("LAUNCHD_SIM_LABEL"), "com.apple.IOSurface.Remote", iosurface_port);
    launch_sim_register_endpoint(getenv("LAUNCHD_SIM_LABEL"), "com.apple.xpc.launchd.host", bootstrap_port);
    launch_sim_register_endpoint(getenv("LAUNCHD_SIM_LABEL"), "com.apple.metal.simulator", metal_port);
    launch_sim_register_endpoint(getenv("LAUNCHD_SIM_LABEL"), "com.apple.metal.simulator.backboardd", metal_port);
    launch_sim_register_endpoint(getenv("LAUNCHD_SIM_LABEL"), "com.apple.metal.simulator.SpringBoard", metal_port);

    CFRunLoopRun();
    
    return 0;
}
