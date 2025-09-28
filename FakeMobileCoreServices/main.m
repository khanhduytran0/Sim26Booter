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

__attribute__((constructor)) static void MobileCoreServicesInit() {
    // catch SIGILL
    struct sigaction sigAction;
    sigAction.sa_sigaction = handleFaultyTextPage;
    sigAction.sa_flags = SA_SIGINFO;
    sigaction(SIGILL, &sigAction, NULL);
}
