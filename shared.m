@import Darwin;
@import Foundation;
#import "shared.h"

boolean_t mig_callback_dopamine(mach_msg_header_t *message, mach_msg_header_t *reply) {
    mach_port_t sender_reply_port = message->msgh_remote_port;

    struct jbserver_mach_msg *jb_msg = (struct jbserver_mach_msg *)message;
    struct jbserver_mach_msg_reply *jb_reply = (struct jbserver_mach_msg_reply *)reply;
    assert(jb_msg->magic == JBSERVER_MACH_MAGIC);

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
kern_return_t jbclient_mach_send_msg(mach_msg_header_t *hdr, struct jbserver_mach_msg_reply *reply) {
    mach_port_t replyPort = mig_get_reply_port();
    if (!replyPort)
        return KERN_FAILURE;
    
    mach_port_t launchdPort = jbclient_mach_get_launchd_port();
    if (!launchdPort)
        return KERN_FAILURE;
    
    hdr->msgh_bits |= MACH_MSGH_BITS(MACH_MSG_TYPE_COPY_SEND, MACH_MSG_TYPE_MAKE_SEND_ONCE);

    // size already set
    hdr->msgh_remote_port  = launchdPort;
    hdr->msgh_local_port   = replyPort;
    hdr->msgh_voucher_port = 0;
    hdr->msgh_id           = 0x40000000 | 206;
    // 206: magic value to make WebContent work (seriously, this is the only ID that the WebContent sandbox allows)
    
    kern_return_t kr = mach_msg(hdr, MACH_SEND_MSG, hdr->msgh_size, 0, 0, 0, 0);
    if (kr != KERN_SUCCESS) {
        mach_port_deallocate(task_self_trap(), launchdPort);
        return kr;
    }
    
    kr = mach_msg(&reply->msg.hdr, MACH_RCV_MSG, 0, reply->msg.hdr.msgh_size, replyPort, 0, 0);
    if (kr != KERN_SUCCESS) {
        mach_port_deallocate(task_self_trap(), launchdPort);
        return kr;
    }
    
    // Get rid of any rights we might have received
    mach_msg_destroy(&reply->msg.hdr);
    mach_port_deallocate(task_self_trap(), launchdPort);
    return KERN_SUCCESS;
}

// https://stackoverflow.com/a/35447525
void fill_send_port_msg(send_port_msg *msg) {
    msg->header.msgh_local_port = MACH_PORT_NULL;
    msg->header.msgh_bits = MACH_MSGH_BITS (MACH_MSG_TYPE_COPY_SEND, 0) |
        MACH_MSGH_BITS_COMPLEX;
    msg->header.msgh_size = sizeof(*msg);

    msg->body.msgh_descriptor_count = 1;
    msg->task_port.disposition = MACH_MSG_TYPE_COPY_SEND;
    msg->task_port.type = MACH_MSG_PORT_DESCRIPTOR;
}

void send_port(mach_port_t remote_port, mach_port_t port) {
    kern_return_t err;

    send_port_msg msg;
    fill_send_port_msg(&msg);
    msg.header.msgh_remote_port = remote_port;
    msg.header.msgh_id = TANK_SERVER_GET_LAUNCHD_PORT;
    msg.task_port.name = port;
    
    err = mach_msg_send(&msg.header);
    assert(err == KERN_SUCCESS);
}

mach_port_t recv_port(mach_port_t recv_port) {
    kern_return_t err;
    struct {
        mach_msg_header_t          header;
        mach_msg_body_t            body;
        mach_msg_port_descriptor_t task_port;
        mach_msg_trailer_t         trailer;
    } msg;

    err = mach_msg(&msg.header, MACH_RCV_MSG,
                    0, sizeof msg, recv_port,
                    MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
    assert(err == KERN_SUCCESS);

    return msg.task_port.name;
}

mach_port_t setup_recv_port(void) {
    kern_return_t       err;
    mach_port_t         port = MACH_PORT_NULL;
    err = mach_port_allocate(mach_task_self (),
                              MACH_PORT_RIGHT_RECEIVE, &port);
    assert(err == KERN_SUCCESS);
    err = mach_port_insert_right(mach_task_self (),
                                  port,
                                  port,
                                  MACH_MSG_TYPE_MAKE_SEND);
    assert(err == KERN_SUCCESS);

    return port;
}
