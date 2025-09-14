//
//  SimFramebuffer.m
//  SimulatorShimFrameworks
//
//  Created by Duy Tran on 4/9/25.
//

@import CoreGraphics;
@import Foundation;

const uint64_t simFramebufferGetStructName = 0xa9017bfda9be4ff4;

@interface SFBConnection : NSObject
@property(nonatomic) NSString *name;
@property(nonatomic) NSArray *displays;
@end
@interface SFBDisplay : NSObject
@property(nonatomic) int type;
@property(nonatomic) NSString *displayUID;
@property(nonatomic) NSString *name;
@property(nonatomic) CGSize size;
@end
@interface SFBSwapchain : NSObject
@end

@implementation SFBConnection
- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    self.name = name;
    
    SFBDisplay *display = [SFBDisplay new];
    self.displays = @[display];
    return self;
}
@end

@implementation SFBDisplay
- (instancetype)init {
    self = [super init];
    self.type = 0;
    self.displayUID = @"PurpleMain";
    self.name = @"LCD";
    self.size = CGSizeMake(1179, 2556); // TODO: get actual size
    return self;
}
@end

@implementation SFBSwapchain
@end

SFBConnection *SFBConnectionCreate(id x0, NSString *name) {
    return [[SFBConnection alloc] initWithName:name];
}
BOOL SFBConnectionConnect(SFBConnection *conn, NSError **error) {
    return YES;
}
NSArray *SFBConnectionCopyDisplays(SFBConnection *conn, NSError **error) {
    return conn.displays;
}
void SFBConnectionSetDisplayUpdatedHandler(SFBConnection *conn, dispatch_queue_t queue, void (^handler)(SFBDisplay *)) {
    // no-op
}

int SFBDisplayGetType(SFBDisplay *display) {
    return display.type;
}
NSString *SFBDisplayGetDisplayUID(SFBDisplay *display) {
    return display.displayUID;
}
NSString *SFBDisplayGetName(SFBDisplay *display) {
    return display.name;
}
SFBDisplay *SFBDisplayGetCurrentMode(SFBDisplay *display) {
    return display;
}
CGSize SFBDisplayGetDeviceSize(SFBDisplay *mode) {
    return mode.size;
}
CGSize SFBDisplayGetCurrentCanvasSize(SFBDisplay *mode) {
    return mode.size;
}
SFBSwapchain *SFBDisplayCreateSwapchain(SFBDisplay *display, CGSize size, int x1_scaleMaybe, int x2, NSError **error) {
    return [SFBSwapchain new];
}

BOOL SFBSwapchainSwapBegin(SFBSwapchain *swapchain, NSUInteger time, NSError **error) {
    // TODO: implement
    return YES;
}
BOOL SFBSwapchainSwapAddSurface(SFBSwapchain *swapchain, IOSurfaceRef surface, CGRect rect1, CGRect rect2,  NSUInteger x2, NSUInteger x3, NSError **error) {
    // TODO: implement
    return YES;
}
BOOL SFBSwapchainSwapSubmit(SFBSwapchain *swapchain, NSError **error) {
    return YES;
}

// stubs
void SFBConnectionCopyDisplay() { abort(); }
void SFBConnectionCopyDisplayByUID() { abort(); }
void SFBConnectionCreateDisplay() { abort(); }
void SFBConnectionGetID() { abort(); }
void SFBConnectionGetTypeID() { abort(); }
void SFBConnectionRemoveDisplay() { abort(); }
void SFBConnectionSetDisplayConnectedHandler() { abort(); }
void SFBConnectionSetDisplayDisconnectedHandler() { abort(); }
void SFBConnectionUpdateDisplay() { abort(); }
void SFBDisplayCopyExtendedPropertyProtocols() { abort(); }
void SFBDisplayGetCanvasSize() { abort(); }
void SFBDisplayGetCanvasSizeCount() { abort(); }
void SFBDisplayGetConnectionID() { abort(); }
void SFBDisplayGetDotPitch() { abort(); }
void SFBDisplayGetExtendedProperties() { abort(); }
void SFBDisplayGetFlags() { abort(); }
void SFBDisplayGetID() { abort(); }
void SFBDisplayGetMaskPath() { abort(); }
void SFBDisplayGetMaxLayerCount() { abort(); }
void SFBDisplayGetMaxSwapchainCount() { abort(); }
void SFBDisplayGetMode() { abort(); }
void SFBDisplayGetModeCount() { abort(); }
void SFBDisplayGetPowerState() { abort(); }
void SFBDisplayGetPreferredMode() { abort(); }
void SFBDisplayGetSupportedPresentationModes() { abort(); }
void SFBDisplayGetSupportedSurfaceFlags() { abort(); }
void SFBDisplayGetTypeID() { abort(); }
void SFBDisplaySetBacklightState() { abort(); }
void SFBDisplaySetBrightnessFactor() { abort(); }
void SFBDisplaySetCanvasSize() { abort(); }
void SFBDisplaySetCurrentMode() { abort(); }
void SFBDisplaySetCurrentUIOrientation() { abort(); }
void SFBSetCreateByAddingSet() { abort(); }
void SFBSetCreateByIntersectingSet() { abort(); }
void SFBSetCreateBySubtractingSet() { abort(); }
void SFBSetCreateFromArray() { abort(); }
void SFBSetGetEmpty() { abort(); }
void SFBSwapchainAcquireSurfaceFence() { abort(); }
void SFBSwapchainGetColorspace() { abort(); }
void SFBSwapchainGetConnectionID() { abort(); }
void SFBSwapchainGetDisplayID() { abort(); }
void SFBSwapchainGetFramebufferSize() { abort(); }
void SFBSwapchainGetHDRMode() { abort(); }
void SFBSwapchainGetID() { abort(); }
void SFBSwapchainGetMaxSurfacesPerOperation() { abort(); }
void SFBSwapchainGetPixelFormat() { abort(); }
void SFBSwapchainGetPresentationMode() { abort(); }
void SFBSwapchainGetTypeID() { abort(); }
void SFBSwapchainSwapCancel() { abort(); }
void SFBSwapchainSwapSetCallback() { abort(); }

/*
 OBJC_CLASS_$__SFBSwapSurfaceFence
 OBJC_METACLASS_$__SFBSwapSurfaceFence
 _SFBConnectionAssertQueue
 _SFBConnectionGetByIDAndRetain
 _SFBDisplayAddExtendedProperties
 _SFBDisplayAddExtendedPropertiesProtocol
 _SFBDisplayAddMaskPath
 _SFBDisplayAddMode
 _SFBDisplayCreate
 _SFBErrorCreate
 _SFBErrorCreateFromMach
 _SFBErrorCreateFromSimReplyError
 _SFBErrorCreateNotConnected
 _SFBGetServerPort
 _SFBSetFramebufferServerEnabled
 _SFBSetServerPort
 _SFBSwapchainCreate
 _SFBSwapchainGetByIDAndRetain
 _SFBSwapchainInvokeCallback
 _SimFramebufferCrashBuffer
 _SimFramebufferSetCrashMessage
 __SFBConnectionAllocated
 _displayCreatedOrUpdatedCallback
 _displayRemovedCallback
 _displaysCopyFromReply
 _nsToMachTime
 _presentCallback
 kSFBDisplayOptionKeyApplyMask
 kSFBDisplayOptionKeyMaskPath
 kSFBErrorDomain
 kSFBSwapchainOptionUseFences
 simFramebufferClientGetErrorDescription
 simFramebufferMessageAddCheckin
 simFramebufferMessageAddCheckinReply
 simFramebufferMessageAddData
 simFramebufferMessageAddDisplayExtendedProperties
 simFramebufferMessageAddDisplayExtendedProtocolName
 simFramebufferMessageAddDisplayMaskPath
 simFramebufferMessageAddDisplayMode
 simFramebufferMessageAddDisplayProperties
 simFramebufferMessageAddDisplaySetBacklightState
 simFramebufferMessageAddDisplaySetBrightnessFactor
 simFramebufferMessageAddDisplaySetCanvasSize
 simFramebufferMessageAddDisplaySetCurrentMode
 simFramebufferMessageAddDisplaySetCurrentUIOrientation
 simFramebufferMessageAddErrorReply
 simFramebufferMessageAddSwapchain
 simFramebufferMessageAddSwapchainCancel
 simFramebufferMessageAddSwapchainPresent
 simFramebufferMessageAddSwapchainPresentCallback
 simFramebufferMessageCopyDisplayMaskPath
 simFramebufferMessageCreate
 simFramebufferMessageCreateDescription
 simFramebufferMessageDealloc
 simFramebufferMessageEnumerate
 simFramebufferMessageEnumerateOfType
 simFramebufferMessageEnumerateOfTypeWithBlock
 simFramebufferMessageEnumerateProtocolNames
 simFramebufferMessageEnumerateProtocolNamesWithBlock
 simFramebufferMessageEnumerateWithBlock
 simFramebufferMessageGetDescriptor
 simFramebufferMessageGetMachHeader
 simFramebufferMessageGetSessionID
 simFramebufferMessageReceive
 simFramebufferMessageReceiveWithAuditToken
 simFramebufferMessageSendOneShot
 simFramebufferMessageSendReply
 simFramebufferMessageSendWithReply
 simFramebufferMessageSendWithReplyWithBlock
 simFramebufferMessageSendWithReplyWithBlockAsync
 simFramebufferMessageSize
 simFramebufferMessageValidateAllowedType
 simFramebufferMessageValidateAllowedTypes
 simFramebufferServerPortName
 */
@interface SFBSwapSurfaceFence : NSObject
@end
@implementation SFBSwapSurfaceFence
@end


