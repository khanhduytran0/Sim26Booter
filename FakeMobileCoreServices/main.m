//
//  main.m
//  
//
//  Created by Duy Tran on 26/9/25.
//

@import Darwin;
@import CoreServices;

const char *MobileCoreServicesVersionString = "@(#)PROGRAM:MobileCoreServices  PROJECT:CoreServices-1226\n";
const uint64_t MobileCoreServicesVersionNumber = 0x4093280000000000;

void ModifyExecutableRegion(void *addr, size_t size, void(^callback)(void)) {
    vm_protect(mach_task_self(), (vm_address_t)addr, size, false, PROT_READ | PROT_WRITE | VM_PROT_COPY);
    callback();
    vm_protect(mach_task_self(), (vm_address_t)addr, size, false, PROT_READ | PROT_EXEC);
}

void handleFaultyTextPage(int signum, struct __siginfo *siginfo, void *context) {
    struct __darwin_ucontext *ucontext = (struct __darwin_ucontext *) context;
    struct __darwin_mcontext64 *machineContext = (struct __darwin_mcontext64 *) ucontext->uc_mcontext;
    arm_thread_state64_t *state = &machineContext->__ss;
    uint32_t *pc = (uint32_t *)__darwin_arm_thread_state64_get_pc(*state);
    ModifyExecutableRegion((void *)pc, sizeof(uint32_t), ^{
        *pc = 0xd503201f; // nop
    });
}

#define CS_DEBUGGED 0x10000000
int csops(pid_t pid, unsigned int ops, void *useraddr, size_t usersize);
int fork();
int ptrace(int, int, int, int);
int isJITEnabled() {
    int flags;
    csops(getpid(), 0, &flags, sizeof(flags));
    return (flags & CS_DEBUGGED) != 0;
}

__attribute__((constructor)) static void MobileCoreServicesInit() {
    // enable JIT
    if (!isJITEnabled()) {
        // Enable JIT
        int pid = fork();
        if (pid == 0) {
            ptrace(0, 0, 0, 0);
            exit(0);
        } else if (pid > 0) {
            while (wait(NULL) > 0) {
                usleep(1000);
            }
        }
    }
    
    // catch SIGILL
    struct sigaction sigAction;
    sigAction.sa_sigaction = handleFaultyTextPage;
    sigAction.sa_flags = SA_SIGINFO;
    sigaction(SIGILL, &sigAction, NULL);
}
