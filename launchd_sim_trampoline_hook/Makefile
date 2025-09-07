ARCHS = arm64
include $(THEOS)/makefiles/common.mk

# Inject to launchd_sim_trampoline, short name since there is insufficient space in load command
LIBRARY_NAME = ltfix
ltfix_FILES = ../shared.m trampoline_hook.m
ltfix_CFLAGS = -fobjc-arc
ltfix_LDFLAGS = -reexport-lobjc -shared -current_version 1.0.0 -compatibility_version 1.0.0
ltfix_INSTALL_PATH = /iOSSimData/override/sbin

include $(THEOS_MAKE_PATH)/library.mk
