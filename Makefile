TARGET := iphone:clang:latest:14.0
ARCHS = arm64
# TODO: replace iOSSimData?

include $(THEOS)/makefiles/common.mk

# iOS subprojects
SUBPROJECTS += launchd_sim_trampoline_hook

# iOS simulator subprojects
SUBPROJECTS += launchd_sim_hook

SUBPROJECTS += FakeMobileCoreServices
SUBPROJECTS += SimFramebuffer
SUBPROJECTS += SimRenderServer
SUBPROJECTS += simsendport
SUBPROJECTS += simxpctest
include $(THEOS_MAKE_PATH)/aggregate.mk
