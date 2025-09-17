@import Darwin;
@import Foundation;
#import "shared.h"

boolean_t mig_callback_dopamine(mach_msg_header_t *message, mach_msg_header_t *reply) {
    struct jbserver_mach_msg *jb_msg = (struct jbserver_mach_msg *)message;
    struct jbserver_mach_msg_reply *jb_reply = (struct jbserver_mach_msg_reply *)reply;
    assert(jb_msg->magic == JBSERVER_MACH_MAGIC);
    
    mach_port_t sender_reply_port = message->msgh_remote_port;
    switch(jb_msg->action) {
        case JBSERVER_MACH_CHECKIN:
            reply->msgh_size = sizeof(struct jbserver_mach_msg_checkin_reply) + MAX_TRAILER_SIZE;
            break;
        case JBSERVER_MACH_FORK_FIX:
            reply->msgh_size = sizeof(struct jbserver_mach_msg_forkfix_reply) + MAX_TRAILER_SIZE;
            break;
        case JBSERVER_MACH_TRUST_FILE:
            reply->msgh_size = sizeof(struct jbserver_mach_msg_trust_fd_reply) + MAX_TRAILER_SIZE;
            break;
    }

    // Forward the message to jbserver in host launchd
    kern_return_t result = jbclient_mach_send_msg(message, jb_reply);
    if(result != KERN_SUCCESS) {
        //NSLog(@"jbclient_mach_send_msg failed: 0x%x", result);
        return false;
    }

    // Fixup the reply message header, based on jbserver_send_mach_reply
    uint32_t bits = MACH_MSGH_BITS_REMOTE(message->msgh_bits);
    if (bits == MACH_MSG_TYPE_COPY_SEND)
        bits = MACH_MSG_TYPE_MOVE_SEND;
    reply->msgh_bits = MACH_MSGH_BITS(bits, 0);
    reply->msgh_remote_port = sender_reply_port;
    reply->msgh_local_port = MACH_PORT_NULL;
    reply->msgh_id = message->msgh_id + 100;

    return true;
}

// https://github.com/opa334/Dopamine/blob/314f7f2/BaseBin/libjailbreak/src/jbclient_mach.c#L17-L52
kern_return_t jbclient_mach_send_msg_internal(mach_msg_header_t *hdr, struct jbserver_mach_msg_reply *reply, mach_port_t launchdPort, mach_port_t replyPort, boolean_t isReceivingPort)
{
    //mach_port_t replyPort = mig_get_reply_port();
    if (!replyPort)
        return KERN_FAILURE;
    
    //mach_port_t launchdPort = jbclient_mach_get_launchd_port();
    if (!launchdPort)
        return KERN_FAILURE;
    
    hdr->msgh_bits |= MACH_MSGH_BITS(MACH_MSG_TYPE_COPY_SEND, (isReceivingPort ? MACH_MSG_TYPE_MAKE_SEND : MACH_MSG_TYPE_MAKE_SEND_ONCE));
    
    // size already set
    hdr->msgh_remote_port  = launchdPort;
    hdr->msgh_local_port   = replyPort;
    hdr->msgh_voucher_port = 0;
    hdr->msgh_id           = 0x40000000 | 206;
    // 206: magic value to make WebContent work (seriously, this is the only ID that the WebContent sandbox allows)
    
    kern_return_t kr = mach_msg(hdr, MACH_SEND_MSG, hdr->msgh_size, 0, 0, 0, 0);
    if (kr != KERN_SUCCESS) {
        return kr;
    }
    
    kr = mach_msg(&reply->msg.hdr, MACH_RCV_MSG, 0, reply->msg.hdr.msgh_size, replyPort, 0, 0);
    if (kr != KERN_SUCCESS) {
        return kr;
    }
    
    // Get rid of any rights we might have received
    if(isReceivingPort)
        mach_port_deallocate(task_self_trap(), replyPort);
    return KERN_SUCCESS;
}
kern_return_t jbclient_mach_send_msg(mach_msg_header_t *hdr, struct jbserver_mach_msg_reply *reply)
{
    return jbclient_mach_send_msg_internal(hdr, reply, jbclient_mach_get_launchd_port(), mig_get_reply_port(), false);
}

void fill_send_port_msg(send_port_msg *msg) {
    msg->header.msgh_local_port = MACH_PORT_NULL;
    msg->header.msgh_bits = MACH_MSGH_BITS (MACH_MSG_TYPE_COPY_SEND, 0) |
        MACH_MSGH_BITS_COMPLEX;
    msg->header.msgh_size = sizeof(*msg);

    msg->body.msgh_descriptor_count = 1;
    msg->special_port.disposition = MACH_MSG_TYPE_COPY_SEND;
    msg->special_port.type = MACH_MSG_PORT_DESCRIPTOR;
}

mach_port_t setup_recv_port(void)
{
    mach_port_t p = MACH_PORT_NULL;
    kern_return_t kr = _kernelrpc_mach_port_allocate_trap(task_self_trap(), MACH_PORT_RIGHT_RECEIVE, &p);
    assert(kr == KERN_SUCCESS);
    kr = _kernelrpc_mach_port_insert_right_trap(task_self_trap(), p, p, MACH_MSG_TYPE_MAKE_SEND);
    assert(kr == KERN_SUCCESS);
    return p;
}
kern_return_t task_get_launchd_port(mach_port_t task, mach_port_t *special_port) {
    struct jbserver_mach_msg msg;
    msg.hdr.msgh_size = sizeof(msg);
    msg.hdr.msgh_bits = 0;
    msg.action = JBSERVER_MACH_GET_HOST_LAUNCHD_PORT;
    msg.magic = JBSERVER_MACH_MAGIC;

    struct {
        mach_msg_header_t Head;
        /* start of the kernel processed data */
        mach_msg_body_t msgh_body;
        mach_msg_port_descriptor_t special_port;
        /* end of the kernel processed data */
        mach_msg_trailer_t trailer;
    } reply;
    reply.Head.msgh_size = sizeof(reply);

    mach_port_t launchdPort = MACH_PORT_NULL;
    task_get_bootstrap_port(task_self_trap(), &launchdPort);
    kern_return_t kr = jbclient_mach_send_msg_internal(&msg.hdr, (struct jbserver_mach_msg_reply *)&reply, launchdPort, setup_recv_port(), true);
    if (kr != KERN_SUCCESS) return kr;

    *special_port = reply.special_port.name;
    return KERN_SUCCESS;
}
