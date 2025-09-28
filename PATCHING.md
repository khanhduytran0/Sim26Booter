# Patching
This file contains my patching history to the simulator runtime

## 2025-09-02
- Fix `launchd_sim_trampoline_tank` crashing by passing through Dopamine calls

## 2025-09-03
- Internalize device by creating `/AppleInternal` folder.
- Patch to use virtual display
```
QuartzCore`__CADeviceUseVirtualMainDisplay_block_invoke:
->  0x100c142dc <+76>: adrp   x3, 294
    0x100c142e0 <+80>: add    x3, x3, #0x1d5            ; "ca_virtual_main_display"
    0x100c142e4 <+84>: mov    w2, #0x0                  ; =0 
    0x100c142e8 <+88>: bl     0x100c13948               ; CABootArgGetInt(std::__1::vector<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>>, std::__1::allocator<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>>>> const&, int, char const*)
```

## 2025-09-11
- Because `diagnosticd` is temporarily removed, force `com.apple.private.disable-log-mach-ports`
```
libsystem_trace.dylib`__client_has_mach_ports_disabled_block_invoke:
    0x1099c72f8 <+0>:  stp    x29, x30, [sp, #-0x10]!
    0x1099c72fc <+4>:  mov    x29, sp
    0x1099c7300 <+8>:  adrp   x0, 20
    0x1099c7304 <+12>: add    x0, x0, #0xf92            ; "com.apple.private.disable-log-mach-ports"
    0x1099c7308 <+16>: mov    x1, #0x0                  ; =0 
    0x1099c730c <+20>: bl     0x1099dab28               ; symbol stub for: xpc_copy_entitlement_for_token # replace: cmp xzr, xzr
    0x1099c7310 <+24>: adrp   x8, 25
    0x1099c7314 <+28>: ldr    x8, [x8, #0x5f0]
->  0x1099c7318 <+32>: cmp    x0, x8 # replace: mov x0, x8
    0x1099c731c <+36>: b.eq   0x1099c732c               ; <+52>
    0x1099c7320 <+40>: cbnz   x0, 0x1099c7338           ; <+64>
    0x1099c7324 <+44>: ldp    x29, x30, [sp], #0x10
    0x1099c7328 <+48>: ret    
    0x1099c732c <+52>: mov    w8, #0x1                  ; =1 
```

## 2025-09-12
No app list because it skipped symlink
```
* thread #5, queue = 'com.apple.lsd.registrationIO', stop reason = breakpoint 9.1
    frame #0: 0x0000000105cf0488 InstalledContentLibrary`-[MIFileManager enumerateURLsForItemsInDirectoryAtURL:ignoreSymlinks:withBlock:]
InstalledContentLibrary`-[MIFileManager enumerateURLsForItemsInDirectoryAtURL:ignoreSymlinks:withBlock:]:
->  0x105cf0488 <+0>:  sub    sp, sp, #0x70
    0x105cf048c <+4>:  stp    x22, x21, [sp, #0x40]
    0x105cf0490 <+8>:  stp    x20, x19, [sp, #0x50]
    0x105cf0494 <+12>: stp    x29, x30, [sp, #0x60]
(lldb) po $x2
file:///var/jb/iOSSimRootFS/Applications/

(lldb) po $x3
1

(lldb) po $x4
<__NSStackBlock__: 0x16cfc9fc0>
 signature: "B20@?0@"NSURL"8C16"
 invoke   : 0x105cc44f4 (/private/preboot/31ACA0FA3DDF276A407C5C8B9B2C662B5EC7EEC4DB3E271DAAD289B2BE6214306D453EB8740C55EE18DA7FC691498195/dopamine-uBqPhv/procursus/iOSSim/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 26.0.simruntime/Contents/Resources/RuntimeRoot/System/Library/PrivateFrameworks/InstalledContentLibrary.framework/InstalledContentLibrary`__52-[MIFilesystemScanner _scanAppsDirectory:withError:]_block_invoke)

(lldb) reg w x3 0
```

## 2025-09-13
When modifying dyldhook, I encountered this issue when running `MachOMerger`:
```
FIXME: sortingRequired not implemented!
```
This is due to unresolved symbols in dyld

## 2025-09-16
Fixed launchd mach port passing

## 2025-09-24
Found the culprit of `xpc_connection_enable_sim2host_4sim` not working: iOS expects version `0`, while it sets `2`. Now Metal XPC is working.

## 2025-09-26
Implemented `IOSurface` XPC server

## 2025-09-27
`-[SWSystemSleepMonitorProvider registerForSystemPowerOnQueue:withDelegate:]` crashes due to missing entitlement in `backboardd` and `SpringBoard`. TODO: find out which one

## 2025-09-29
Made a fake `MobileCoreServices` that is loaded to all simulator processes to patch out unsupported instructions on A12-A13 (temporary, should emulate later instead?)
