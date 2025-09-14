ARCHS = arm64
include $(THEOS)/makefiles/common.mk

FRAMEWORK_NAME = SimFramebuffer

SimFramebuffer_FILES = SimFramebuffer.m
SimFramebuffer_PUBLIC_HEADERS = SimFramebuffer.h
SimFramebuffer_INSTALL_PATH = /iOSSimData/override/System/Library/PrivateFrameworks
SimFramebuffer_CFLAGS = -fobjc-arc
SimFramebuffer_CODESIGN_FLAGS = bash ../vtool_and_sign.sh -S
TARGET_CODESIGN = env PLATFORM=7

include $(THEOS_MAKE_PATH)/framework.mk
