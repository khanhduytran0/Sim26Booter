ARCHS = arm64
include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = SimRenderServer

SimRenderServer_DYNAMIC_LIBRARY = 0
SimRenderServer_BUNDLE_EXTENSION = xpc
SimRenderServer_FILES = main.m
SimRenderServer_CFLAGS = -fobjc-arc
SimRenderServer_CODESIGN_FLAGS = -S../entitlements.plist
SimRenderServer_INSTALL_PATH = /usr/macOS/Frameworks/MTLSimDriver.framework/XPCServices

include $(THEOS_MAKE_PATH)/bundle.mk
