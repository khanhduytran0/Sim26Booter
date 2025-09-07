ARCHS = arm64
include $(THEOS)/makefiles/common.mk

# Inject to launchd_sim
LIBRARY_NAME = ldfix
ldfix_FILES = ../shared.m launchd_sim_hook.m
ldfix_CFLAGS = -fobjc-arc
ldfix_LDFLAGS = -reexport-lobjc -shared -current_version 1.0.0 -compatibility_version 1.0.0
ldfix_INSTALL_PATH = /iOSSimData/override/sbin
ldfix_CODESIGN_FLAGS = bash ../vtool_and_sign.sh -S
TARGET_CODESIGN = env PLATFORM=7

include $(THEOS_MAKE_PATH)/library.mk
