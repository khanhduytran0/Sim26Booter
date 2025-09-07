@import Foundation;
#import "shared.h"

mach_port_t host_launchd_port = MACH_PORT_NULL;
mach_port_t jbclient_mach_get_launchd_port() {
    assert(host_launchd_port != MACH_PORT_NULL);
    return host_launchd_port;
}

//kern_return_t hooked_task_set_special_port(task_t task, int which_port, mach_port_t special_port) {
//    if(which_port == TASK_BOOTSTRAP_PORT && special_port == MACH_PORT_NULL) {
//        return task_set_special_port(task, which_port, host_launchd_port);
//    } else {
//        return task_set_special_port(task, which_port, special_port);
//    }
//}
//DYLD_INTERPOSE(hooked_task_set_special_port, task_set_special_port);

void jbserver_received_mach_message(audit_token_t *auditToken, struct jbserver_mach_msg *jbsMachMsg) {
    mach_port_t sender_reply_port = jbsMachMsg->hdr.msgh_remote_port;
    
    uint8_t replyBuf[HOOK_MACH_MAX_REPLY_SIZE] = {0};
    mach_msg_header_t *reply = (mach_msg_header_t *)replyBuf;
    if(mig_callback_dopamine(&jbsMachMsg->hdr, reply)) {
        // Fixup the reply message header, based on jbserver_send_mach_reply
        uint32_t bits = MACH_MSGH_BITS_REMOTE(jbsMachMsg->hdr.msgh_bits);
        if (bits == MACH_MSG_TYPE_COPY_SEND)
            bits = MACH_MSG_TYPE_MOVE_SEND;
        reply->msgh_bits = MACH_MSGH_BITS(bits, 0);
        reply->msgh_remote_port = sender_reply_port;
        reply->msgh_local_port = MACH_PORT_NULL;
        reply->msgh_id = jbsMachMsg->hdr.msgh_id + 100;
        
        // Forward the reply to the original sender
        mach_msg_return_t mr = mach_msg(reply, MACH_SEND_MSG, reply->msgh_size, 0, 0, 0, 0);
        if (mr != MACH_MSG_SUCCESS) {
            dprintf(6, "ERROR: mach_msg failed sending to 0x%x\n", sender_reply_port);
        }
        assert(mr == MACH_MSG_SUCCESS); // temp
    } else {
        dprintf(6, "ERROR: mig_callback_dopamine failed\n");
    }
}

// https://github.com/opa334/Dopamine/blob/314f7f2/BaseBin/launchdhook/src/xpc_hook.c#L16-L61
int hooked_xpc_receive_mach_msg(void *msg, void *a2, void *a3, void *a4, xpc_object_t *xOut) {
    size_t msgBufSize = 0;
    struct jbserver_mach_msg *jbsMachMsg = (struct jbserver_mach_msg *)dispatch_mach_msg_get_msg(msg, &msgBufSize);
    bool wasProcessed = false;
    if (jbsMachMsg != NULL && msgBufSize >= sizeof(mach_msg_header_t)) {
        size_t msgSize = jbsMachMsg->hdr.msgh_size;
        if (msgSize <= msgBufSize && msgSize >= sizeof(struct jbserver_mach_msg) && jbsMachMsg->magic == JBSERVER_MACH_MAGIC) {
            mach_msg_context_trailer_t *trailer = (mach_msg_context_trailer_t *)((uint8_t *)jbsMachMsg + round_msg(jbsMachMsg->hdr.msgh_size));
            jbserver_received_mach_message(&trailer->msgh_audit, jbsMachMsg);
            wasProcessed = true;
            // Pass the message to xpc_receive_mach_msg anyway, it will get rid of it for us
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
