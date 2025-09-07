# Sim26Booter
Boot iOS 26 simulator on iPhone?

## Simulator boot process
> [!NOTE]
> `93463F5E-ECBC-4762-ABC7-7CE6E88FED59` is an example simulator data UUID.

### `com.apple.CoreSimulator.CoreSimulatorService`
- When it receives a request to boot a simulator, it will submit a launch job to `launchd` to spawn `simulator-trampoline`.
```c
* thread #5, queue = 'com.apple.CoreSimulator.SimDevice.bootstrapQueue.93463F5E-ECBC-4762-ABC7-7CE6E88FED59', stop reason = breakpoint 3.1
  * frame #0: 0x00000001934863e8 ServiceManagement`SMJobSubmit
    frame #1: 0x000000010021f7b0 CoreSimulator`-[SimDevice createLaunchdJobWithBinpref:extraEnvironment:disabledJobs:error:] + 4732
    frame #2: 0x0000000100221db0 CoreSimulator`-[SimDevice _onBootstrapQueue_bootWithOptions:deathMonitorPort:error:] + 932

(lldb) po $x1
{
    ExitTimeOut = 33;
    Label = "com.apple.CoreSimulator.SimDevice.93463F5E-ECBC-4762-ABC7-7CE6E88FED59";
    LaunchOnlyOnce = 1;
    LegacyTimers = 1;
    LimitLoadToSessionType = Background;
    MachServices =     {
        "com.apple.CoreSimulator.SimDevice.93463F5E-ECBC-4762-ABC7-7CE6E88FED59" =         {
            ResetAtClose = 1;
        };
    };
    POSIXSpawnType = Interactive;
    Program = "/Library/Developer/PrivateFrameworks/CoreSimulator.framework/Resources/simulator-trampoline";
    ProgramArguments =     (
        "simulator-trampoline",
        "/Library/Developer/CoreSimulator/Volumes/iOS_20E247/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 16.4.simruntime/Contents/Resources/RuntimeRoot/sbin/launchd_sim_trampoline",
        "/Library/Developer/CoreSimulator/Volumes/iOS_20E247/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 16.4.simruntime/Contents/Resources/RuntimeRoot/sbin/launchd_sim",
        "/Users/duy/Library/Developer/CoreSimulator/Devices/93463F5E-ECBC-4762-ABC7-7CE6E88FED59/data/var/run/launchd_bootstrap.plist"
    );
}
```

- At this point, `simulator-trampoline` has not been spawned yet, but you can ask launchd to spawn it early:
```sh
launchctl kickstart user/501/com.apple.CoreSimulator.SimDevice.93463F5E-ECBC-4762-ABC7-7CE6E88FED59
```
- It will then spawn `simulator-trampoline` and pass some host mach ports to it:
> [!NOTE]
> Many optional ports are excluded from this list, but I still left the important ones:
> - `IndigoHIDRegistrationPort`: proxy HID events. Without this port, keyboard and touch input won't work.
> - `com.apple.metal.simulator`: proxy Metal via XPC. Without this port, simulator will fallback to software rendering.
```c
* thread #5, queue = 'com.apple.CoreSimulator.SimDevice.bootstrapQueue.93463F5E-ECBC-4762-ABC7-7CE6E88FED59', stop reason = breakpoint 1.1
  * frame #0: 0x0000000100238374 CoreSimulator`-[SimLaunchHostClient startNewSession:endpointsToRegister:bindPort:deathQueue:deathHandler:error:]
    frame #1: 0x000000010022065c CoreSimulator`-[SimDevice startLaunchdWithDeathPort:error:] + 812
    frame #2: 0x0000000100221ec4 CoreSimulator`-[SimDevice _onBootstrapQueue_bootWithOptions:deathMonitorPort:error:] + 1208

(lldb) po $x3                                                                                                
{
    IndigoHIDRegistrationPort = "<SimMachPort 0x600002f00d80 port 0x13023 (77859) send>";
    "com.apple.CoreSimulator.SimFramebufferServer" = "<SimMachPort 0x600002f00b40 port 0x1da3b (121403) send>";
    "com.apple.IOSurface.Remote" = "<SimMachPort 0x600002f056a0 port 0x1b90f (112911) send>";
    "com.apple.SystemConfiguration.configd" = "<SimMachPort 0x600002f1b520 port 0x1c903 (116995) send>";
    "com.apple.metal.simulator" = "<SimMachPort 0x600002f002a0 port 0x18023 (98339) send>";
}
```
- Afterwards, `simulator-trampoline` starts

### `simulator-trampoline`
- It performs signature validation on `launchd_sim` using `SecStaticCodeCheckValidity`. This can be bypassed by setting a default which requires patching internal OS check:
```sh
defaults write com.apple.CoreSimulator DisableLaunchdSignatureCheck -bool true
```

- It then sends a request to `SimulatorTrampoline.xpc` to set responsibility something idk. This can also be bypassed by setting a default:
```sh
defaults write com.apple.CoreSimulator DisableResponsibility -bool true
```

- Finally, it execve's `launchd_sim_trampoline` with the remaining arguments passed previously.

### `launchd_sim_trampoline`
- It enables case sensitive filesystem by using a hidden policy flag as described in [this writeup](https://worthdoingbadly.com/casesensitive-iossim/).
- It calls `bootstrap_check_in("com.apple.CoreSimulator.SimDevice.93463F5E-ECBC-4762-ABC7-7CE6E88FED59")` to register itself with the host `launchd`.
- ~~It `setenv("XPC_SIMULATOR_HOLDING_TANK_FD_HACK")`~~ something I haven't looked into yet
- It spawns another process of itself with `argv[0] = "launchd_sim_trampoline_tank"`
- It obtains `launchd_sim_trampoline_tank`'s mach port using `bootstrap_look_up2("com.apple.xpc.sim.launchd.rendezvous")`, and proceeds to validate it by sending a message with `msgh_id = 707`
- Finally, it passes `launchd_sim_trampoline_tank`'s mach port to `posix_spawnattr_setspecialport_np(TASK_BOOTSTRAP_PORT)` and jumps to `launchd_sim` with the remaining plist path argument

### `launchd_sim_trampoline_tank`
- Spawned by `launchd_sim_trampoline` to stash the `launchd_sim_trampoline`'s bootstrap port in order to be retrieved later by `launchd_sim`.
- It calls `bootstrap_check_in2("com.apple.xpc.sim.launchd.rendezvous")` to allow `launchd_sim_trampoline` to validate and set it as the temporary bootstrap port when jumping to `launchd_sim`
- I haven't looked into this much, but it handles at least 2 `msgh_id`:
    + `707`: used to validate the connection with `launchd_sim_trampoline` before `execve`'ing to `launchd_sim`
    + `708`: used by `launchd_sim` to retrieve the stashed bootstrap port. After sending the reply, it will exit.

### `launchd_sim`
- Here comes the interesting part: `launchd_sim` is the real `launchd` for the simulator.
- It first retrieves the stashed bootstrap port from `launchd_sim_trampoline_tank` by sending a message with `msgh_id = 708` and save it somewhere, then the temporary bootstrap port is discarded. Then it waits for `launchd_sim_trampoline_tank` to exit
- It reads the plist file passed as argument to get the simulator's environment and other configurations
- Finally it enters the main loop to spawn and handle launch jobs
