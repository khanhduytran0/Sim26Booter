@import Darwin;
#import <rootless.h>

kern_return_t bootstrap_look_up(mach_port_t bp, const char *service_name, mach_port_t *sp);
void xpc_add_bundle(char *, int);
void xpc_connection_set_instance(xpc_connection_t, const uuid_t);
void launch_sim_register_endpoint(const char *launchd_sim_name, const char *service_name, mach_port_t service_port);
void xpc_connection_enable_sim2host_4sim(xpc_connection_t, int);

int main(int argc, char *argv[], char *envp[]) {
    xpc_object_t (*xpc_connection_create_mach_service)(const char *name, dispatch_queue_t targetq, uint64_t flags) = dlsym(RTLD_DEFAULT, "xpc_connection_create_mach_service");
    assert(xpc_connection_create_mach_service);
    
    char *frameworkPath = "/var/jb/usr/macOS/Frameworks/MTLSimDriver.framework/XPCServices/MTLSimDriverHost.xpc";
    xpc_add_bundle(frameworkPath, 2);
    xpc_add_bundle(frameworkPath, 2);
    
    //uuid_t uuid;
    //uuid_generate(uuid);
    xpc_connection_t connection = xpc_connection_create_mach_service("com.apple.metal.simulator", NULL, 0);
    xpc_connection_enable_sim2host_4sim(connection, 1);
    //xpc_connection_set_instance(connection, uuid);
    xpc_connection_set_event_handler(connection, ^(xpc_object_t object) {
        NSLog(@"Process received event: %@", [object description]);
    });
    xpc_connection_resume(connection);
    
    xpc_object_t dict = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_uint64(dict, "requestType", 9); // XPCCompilerConnection::checkConnectionActive(bool&)
    xpc_object_t object = xpc_connection_send_message_with_reply_sync(connection, dict);
    NSLog(@"Received synced event: %@", [object description]);
    NSLog(@"XPC connection now: %@", [connection description]);
    sleep(1);
    
    return 0;
}
