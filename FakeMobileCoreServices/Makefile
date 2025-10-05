ARCHS = arm64
include $(THEOS)/makefiles/common.mk

# Borrow MobileCoreServices to inject to all binaries
FRAMEWORK_NAME = MobileCoreServices
MobileCoreServices_FILES = main.m
MobileCoreServices_CFLAGS = -fobjc-arc
MobileCoreServices_LDFLAGS = -reexport-lobjc -reexport_framework CoreServices -shared -current_version 1226.0.0 -compatibility_version 1.0.0
MobileCoreServices_INSTALL_PATH = /iOSSimData/override/System/Library/Frameworks
MobileCoreServices_CODESIGN_FLAGS = bash ../vtool_and_sign.sh -S
TARGET_CODESIGN = env PLATFORM=7

include $(THEOS_MAKE_PATH)/framework.mk
