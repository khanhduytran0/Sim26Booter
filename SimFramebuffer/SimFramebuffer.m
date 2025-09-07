//
//  SimFramebuffer.m
//  SimulatorShimFrameworks
//
//  Created by Duy Tran on 4/9/25.
//

@import CoreGraphics;
@import Foundation;

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
