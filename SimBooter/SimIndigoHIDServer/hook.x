@import Darwin;

// Fix IOHIDEventSystemCreate not working

typedef char* name_t;
kern_return_t bootstrap_look_up2(mach_port_t bp, const name_t service_name, mach_port_t *sp, pid_t target_pid, uint64_t flags);
kern_return_t bootstrap_check_in(mach_port_t bp, const name_t service_name, mach_port_t *sp);

%hookf(kern_return_t, bootstrap_look_up2, mach_port_t bp, const name_t service_name, mach_port_t *sp, pid_t target_pid, uint64_t flags) {
    if(!strcmp(service_name, "com.apple.iohideventsystem")) {
        return %orig(bp, "com.apple.iohideventsystem.4sim", sp, target_pid, flags);
    }
    return %orig(bp, service_name, sp, target_pid, flags);
}
%hookf(kern_return_t, bootstrap_check_in, mach_port_t bp, const name_t service_name, mach_port_t *sp) {
    if(!strcmp(service_name, "com.apple.iohideventsystem")) {
        return %orig(bp, "com.apple.iohideventsystem.4sim", sp);
    }
    return %orig(bp, service_name, sp);
}
