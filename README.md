# Sim26Booter
Boot iOS 26 simulator on iPhone

Only tested with Dopamine jailbreak on iOS 16.5, iPhone Xs Max.
While there is no hardcoded offset at the moment, some code paths are hardcoded for Dopamine.

## What works
- [x] Passing `launchd` mach port to child processes
- [x] Metal XPC
- [x] IOSurface
- [ ] Audio
- [ ] Sensors
- [x] HID Touchscreen Input

## Additional info
- [Simulator boot process](SimBootProcess.md) on macOS

## Credits
Some code have been borrowed from:
- [Dopamine](https://github.com/opa334/Dopamine)
- [idb/Indigo.h](https://github.com/facebook/idb/blob/d4f493eced373c3cf20ac001e8375c56fd4e53c1/PrivateHeaders/SimulatorApp/Indigo.h)
