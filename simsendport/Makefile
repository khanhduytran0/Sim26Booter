ARCHS = arm64
include $(THEOS)/makefiles/common.mk

TOOL_NAME = simsendport

simsendport_FILES = main.m
simsendport_CFLAGS = -fobjc-arc
simsendport_CODESIGN_FLAGS = -Sentitlements.plist
simsendport_INSTALL_PATH = /usr/local/bin

include $(THEOS_MAKE_PATH)/tool.mk
