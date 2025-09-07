@import Darwin;
@import XPC;

#define TANK_SERVER_VALIDATE 707
#define TANK_SERVER_GET_SERVICE_PORT 708
#define TANK_SERVER_GET_LAUNCHD_PORT 1000
#define HOOK_MACH_MAX_REPLY_SIZE (sizeof(struct jbserver_mach_msg_checkin_reply) + MAX_TRAILER_SIZE)

// https://stackoverflow.com/a/35447525
typedef struct {
    mach_msg_header_t          header;
    mach_msg_body_t            body;
    mach_msg_port_descriptor_t task_port;
} send_port_msg;
void fill_send_port_msg(send_port_msg *msg);

boolean_t mig_callback_dopamine(mach_msg_header_t *message, mach_msg_header_t *reply);
void send_port(mach_port_t remote_port, mach_port_t port);
mach_port_t recv_port(mach_port_t recv_port);
mach_port_t setup_recv_port(void);

// interpose.h
#define DYLD_INTERPOSE(_replacement,_replacee) \
   __attribute__((used)) static struct{ const void* replacement; const void* replacee; } _interpose_##_replacee \
            __attribute__ ((section ("__DATA,__interpose"))) = { (const void*)(unsigned long)&_replacement, (const void*)(unsigned long)&_replacee };

// Dopamine/BaseBin/libjailbreak/src/jbserver.h
#define JBSERVER_MACH_MAGIC 0x444F50414D494E45
#define JBSERVER_MACH_CHECKIN 0
#define JBSERVER_MACH_FORK_FIX 1
#define JBSERVER_MACH_TRUST_FILE 2
struct jbserver_mach_msg {
    mach_msg_header_t hdr;
    uint64_t magic;
    uint64_t action;
};
struct jbserver_mach_msg_reply {
    struct jbserver_mach_msg msg;
    uint64_t status;
};
struct jbserver_mach_msg_checkin_reply {
    struct jbserver_mach_msg_reply base;
    bool fullyDebugged;
    char jbRootPath[PATH_MAX];
    char bootUUID[37];
    char sandboxExtensions[2000];
};
struct jbserver_mach_msg_forkfix_reply {
    struct jbserver_mach_msg_reply base;
};
struct jbserver_mach_msg_trust_fd_reply {
    struct jbserver_mach_msg_reply base;
};

typedef boolean_t (*dispatch_mig_callback_t)(mach_msg_header_t *message, mach_msg_header_t *reply);
extern mach_msg_header_t* dispatch_mach_msg_get_msg(void *message, size_t *size_ptr);
extern int xpc_pipe_try_receive(mach_port_t p, xpc_object_t *message, mach_port_t *recvp, dispatch_mig_callback_t callout, size_t maxmsgsz, uint64_t flags);
extern int xpc_receive_mach_msg(void *msg, void *a2, void *a3, void *a4, xpc_object_t *xOut);

mach_port_t jbclient_mach_get_launchd_port();
kern_return_t jbclient_mach_send_msg(mach_msg_header_t *hdr, struct jbserver_mach_msg_reply *reply);

#define JBSERVER_SIM_MACH_GET_LAUNCHD_PORT 1000
