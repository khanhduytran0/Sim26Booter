//
//  SimFramebuffer.m
//  SimulatorShimFrameworks
//
//  Created by Duy Tran on 4/9/25.
//

@import CoreGraphics;
@import Foundation;
@import IOSurface;
#import "IOMobileFramebuffer.h"

const uint64_t simFramebufferGetStructName = 0xa9017bfda9be4ff4;

#pragma pack(push,1)
typedef struct {
    uint32_t mode_id;       // 0x00 = 1
    uint32_t width;         // 0x04 = 1206 (maybe width in pixels)
    uint32_t height;        // 0x08 = 2622 (maybe height in pixels)
    uint32_t scale;         // 0x0c = 3 (scale factor?)
    uint32_t unknown0; //refresh;       // 0x10 = 1 (Hz? or just flag)
    char     pixel_format[4]; // 0x14 = "ARGB"
    uint32_t unknown1; //color_depth;   // 0x18 = 1 (bits/component?)
    uint32_t timing;        // 0x1c = 6000 (maybe Hz*100? 60.00 Hz)
    uint8_t  flags[3];      // 0x20 = 01 01 01 (boolean flags)
} SFBDisplayMode;
#pragma pack(pop)

@interface SFBConnection : NSObject
@property(nonatomic) NSString *name;
@property(nonatomic) NSArray *displays;
@end
@interface SFBDisplay : NSObject
@property(nonatomic) int type;
@property(nonatomic) NSString *displayUID;
@property(nonatomic) NSString *name;
@property(nonatomic) CGSize size;
@property(nonatomic) IOMobileFramebufferRef fbConn;
@property(nonatomic) IOSurfaceRef surface;
@end
@interface SFBSwapchain : SFBDisplay
// For convenience, we make SFBSwapchain a subclass of SFBDisplay
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
    IOMobileFramebufferGetMainDisplay(&_fbConn);
    assert(_fbConn);
    IOMobileFramebufferGetDisplaySize(_fbConn, &_size);
    return self;
}
@end

SFBConnection *SFBConnectionCreate(id x0, NSString *name) {
    static SFBConnection *sharedConn = nil;
    if(!sharedConn) {
        sharedConn = [[SFBConnection alloc] initWithName:name];
    }
    return sharedConn;
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
void SFBDisplayGetCurrentMode(SFBDisplay *display, SFBDisplayMode *mode) {
    assert(display);
    assert(mode);
    mode->mode_id = 1;
    mode->width = display.size.width;
    mode->height = display.size.height;
    mode->scale = 3;
    mode->unknown0 = 1;
    memcpy(mode->pixel_format, "ARGB", 4);
    mode->unknown1 = 1;
    mode->timing = 6000; // 60.00 Hz
    mode->flags[0] = 1;
    mode->flags[1] = 1;
    mode->flags[2] = 1;
}
CGSize SFBDisplayGetDeviceSize(SFBDisplay *mode) {
    return mode.size;
}
CGSize SFBDisplayGetCurrentCanvasSize(SFBDisplay *mode) {
    return mode.size;
}
SFBSwapchain *SFBDisplayCreateSwapchain(SFBDisplay *display, CGSize size, int x1_scaleMaybe, int x2, NSError **error) {
    return (id)display;
}

// here we borrow IOSurfaceSetValue
BOOL SFBSwapchainSwapBegin(SFBSwapchain *swapchain, NSUInteger time, NSError **error) {
//    int token;
//    return IOMobileFramebufferSwapBegin(swapchain.fbConn, &token) == 0;
    //IOSurfaceSetValue(@"SwapCmd", @(1));
    return YES;
}
BOOL SFBSwapchainSwapAddSurface(SFBSwapchain *swapchain, IOSurfaceRef surface, CGRect rect1, CGRect rect2,  NSUInteger x2, NSUInteger x3, NSError **error) {
//    return IOMobileFramebufferSwapSetLayer(swapchain.fbConn, 0, surface, rect1, rect2, 0) == 0;
    // do note that both rect1 and rect2 are the same
    // for optimization we pack them into a single 48-bit integer
    swapchain.surface = surface;
    uint64_t packedFrame = ((uint64_t)rect1.origin.x << 36) | ((uint64_t)rect1.origin.y << 24) | ((uint64_t)rect1.size.width << 12) | ((uint64_t)rect1.size.height & 0xfff);
    IOSurfaceSetValue(surface, (__bridge CFTypeRef _Nonnull)@"SwapCmd", (__bridge CFTypeRef _Nonnull)@(packedFrame));
    return YES;
}
BOOL SFBSwapchainSwapSubmit(SFBSwapchain *swapchain, NSError **error) {
//    return IOMobileFramebufferSwapEnd(swapchain.display.fbConn) == 0;
    IOSurfaceSetValue(swapchain.surface, (__bridge CFTypeRef _Nonnull)@"SwapCmd", @(0));
    return YES;
}
BOOL SFBSwapchainSwapSetCallback(SFBSwapchain *swapchain, void *context, dispatch_queue_t queue, void (^callback)(NSError *error, SFBSwapchain *swapchain, uint64_t arg1, uint64_t arg2, void *context)) {
    // I'm not really sure what this callback is for, so let's just pretend like this function failed
    return NO;
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


