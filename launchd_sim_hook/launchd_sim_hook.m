@import Foundation;
#import "shared.h"

mach_port_t host_launchd_port = MACH_PORT_NULL;
// overrides implementation in dyld
mach_port_t jbclient_mach_get_launchd_port() {
    assert(host_launchd_port != MACH_PORT_NULL);
    return host_launchd_port;
}

void jbserver_sim_get_launchd(mach_msg_header_t *message) {
    send_port_msg *msg = (void *)message;
    uint8_t replyBuf[HOOK_MACH_MAX_REPLY_SIZE] = {0};
    send_port_msg *reply_msg = (void *)replyBuf;
    
    fill_send_port_msg(reply_msg);
    reply_msg->header.msgh_remote_port = msg->task_port.name;
    reply_msg->header.msgh_id = message->msgh_id + 100;
    reply_msg->task_port.name = jbclient_mach_get_launchd_port();
    
    mach_msg_return_t mr = mach_msg(&reply_msg->header, MACH_SEND_MSG, reply_msg->header.msgh_size, 0, 0, 0, 0);
    assert(mr == MACH_MSG_SUCCESS);
}

// https://github.com/opa334/Dopamine/blob/314f7f2/BaseBin/launchdhook/src/xpc_hook.c#L16-L61
int hooked_xpc_receive_mach_msg(void *msg, void *a2, void *a3, void *a4, xpc_object_t *xOut) {
    size_t msgBufSize = 0;
    struct jbserver_mach_msg *jbsMachMsg = (struct jbserver_mach_msg *)dispatch_mach_msg_get_msg(msg, &msgBufSize);
    bool wasProcessed = false;
    if (jbsMachMsg != NULL && msgBufSize >= sizeof(mach_msg_header_t)) {
        size_t msgSize = jbsMachMsg->hdr.msgh_size;
        if(jbsMachMsg->hdr.msgh_id == TANK_SERVER_GET_LAUNCHD_PORT) {
            // launchd_sim's subprocesses request launchd port
            jbserver_sim_get_launchd(&jbsMachMsg->hdr);
        }
    }
    
    int r = xpc_receive_mach_msg(msg, a2, a3, a4, xOut);
//    if (!wasProcessed && r == 0 && xOut && *xOut) {
//        if (jbserver_received_xpc_message(&gGlobalServer, *xOut) == 0) {
            // Returning non null here makes launchd disregard this message
            // For jailbreak messages we have the logic to handle them
            //xpc_release(*xOut);
//            return 22;
//        }
//    }
    return r;
}
DYLD_INTERPOSE(hooked_xpc_receive_mach_msg, xpc_receive_mach_msg);

static mach_port_t tank_mach_get_bootstrap_port(mach_port_t tank_port) {
    mach_port_t port = setup_recv_port();
    send_port(tank_port, port);
    mach_port_t bootstrap_port = recv_port(port);
    mach_port_deallocate(mach_task_self(), port);
    NSLog(@"Obtained host's launchd port: 0x%x", bootstrap_port);
    return bootstrap_port;
}

__attribute__((constructor)) static void init() {
    // Obtain host's launchd port using our launchd_sim_trampoline_tank hook
    mach_port_t tank_port = MACH_PORT_NULL;
    task_get_special_port(mach_task_self(), TASK_BOOTSTRAP_PORT, &tank_port);
    assert(tank_port != MACH_PORT_NULL);
    host_launchd_port = tank_mach_get_bootstrap_port(tank_port);
    assert(host_launchd_port != MACH_PORT_NULL);
};
