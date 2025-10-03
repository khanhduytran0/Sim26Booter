ARCHS = arm64
include $(THEOS)/makefiles/common.mk

TOOL_NAME = SimBooter

SimBooter_FILES = main.m \
  SimIndigoHIDServer/main.m SimIndigoHIDServer/hook.x \
  SimIndigoHIDServer/FBSimulatorControl/HID/FBSimulatorHID.m \
  SimIndigoHIDServer/FBSimulatorControl/HID/FBSimulatorHID+Struct26.m \
  SimIndigoHIDServer/FBSimulatorControl/HID/FBSimulatorIndigoHID.m \
  SimIndigoHIDServer/FBSimulatorControl/HID/FBSimulatorHIDEvent.m \
  SimIndigoHIDServer/FBControlCore/Async/FBFuture.m
SimBooter_CFLAGS = -fobjc-arc -I./SimIndigoHIDServer
SimBooter_LDFLAGS = -F../Frameworks
SimBooter_FRAMEWORKS = IOKit IOMobileFramebuffer
SimBooter_CODESIGN_FLAGS = -S../entitlements.plist
SimBooter_INSTALL_PATH = /usr/local/bin

include $(THEOS_MAKE_PATH)/tool.mk
