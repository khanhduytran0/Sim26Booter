ARCHS = arm64
include $(THEOS)/makefiles/common.mk

TOOL_NAME = simxpctest

simxpctest_FILES = main.m
simxpctest_CFLAGS = -fobjc-arc
simxpctest_INSTALL_PATH = /usr/local/bin
simxpctest_CODESIGN_FLAGS = bash ../vtool_and_sign.sh -S../entitlements.plist
TARGET_CODESIGN = env PLATFORM=7

include $(THEOS_MAKE_PATH)/tool.mk
