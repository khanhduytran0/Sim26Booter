@import Darwin;
@import Foundation;
#import <crt_externs.h>
#import "shared.h"

// From jbclient_mach.c in Dopamine
mach_port_t jbclient_mach_get_launchd_port(void) {
    mach_port_t launchdPort = MACH_PORT_NULL;
    task_get_bootstrap_port(task_self_trap(), &launchdPort);
    return launchdPort;
}

// launchd_sim_trampoline_tank acts like a boomerang which sends launchd_sim's own bootstrap port back to it
static dispatch_mig_callback_t mig_callback_orig;
static boolean_t mig_callback_orig_called;
static boolean_t mig_callback_get_launchd(mach_msg_header_t *message, mach_msg_header_t *reply) {
    send_port_msg *msg = (void *)message;
    send_port_msg *reply_msg = (void *)reply;
    
    fill_send_port_msg(reply_msg);
    reply_msg->header.msgh_remote_port = msg->task_port.name;
    reply_msg->header.msgh_id = message->msgh_id + 100;
    reply_msg->task_port.name = jbclient_mach_get_launchd_port();
    
    return true;
}

boolean_t hooked_dispatch_mig_callback(mach_msg_header_t *message, mach_msg_header_t *reply) {
    //NSLog(@"tank: message msgh_bits=0x%x id=0x%x size=%u", message->msgh_bits, message->msgh_id, message->msgh_size);
    switch(message->msgh_id) {
        case 0x400000ce: // https://github.com/opa334/Dopamine/blob/314f7f2/BaseBin/libjailbreak/src/jbclient_mach.c#L33
            return mig_callback_dopamine(message, reply);
        case TANK_SERVER_GET_LAUNCHD_PORT: // launchd_sim_hook requests launchd port
            return mig_callback_get_launchd(message, reply);
        case TANK_SERVER_VALIDATE: // launchd_sim_trampoline validates tank connection
        case TANK_SERVER_GET_SERVICE_PORT: // launchd_sim requests its bootstrap port
            mig_callback_orig_called = true;
            return mig_callback_orig(message, reply);
        default:
            NSLog(@"tank: unhandled message id 0x%x", message->msgh_id);
            return false;
    }
}

int hooked_xpc_pipe_try_receive(mach_port_t p, xpc_object_t *message, mach_port_t *recvp, dispatch_mig_callback_t callout, size_t maxmsgsz, uint64_t flags) {
    static int hookState = -1;
    if(hookState == -1) {
        char **argv = *_NSGetArgv();
        hookState = !strcmp(argv[0], "launchd_sim_trampoline_tank");
    }
    if(!hookState) {
        return xpc_pipe_try_receive(p, message, recvp, callout, maxmsgsz, flags);
    }
    
    mig_callback_orig = callout;
    size_t checkin_reply_size = HOOK_MACH_MAX_REPLY_SIZE;
    assert(maxmsgsz < checkin_reply_size);
    maxmsgsz = checkin_reply_size;
    mig_callback_orig_called = false;
    
    kern_return_t result;
    do {
        result = xpc_pipe_try_receive(p, message, recvp, hooked_dispatch_mig_callback, maxmsgsz, flags);
    } while(result == KERN_SUCCESS && !mig_callback_orig_called);
    
    return result;
}
DYLD_INTERPOSE(hooked_xpc_pipe_try_receive, xpc_pipe_try_receive);
