/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSimulatorHID.h"
#import "Indigo.h"
#import "IOMobileFramebuffer.h"

#import <objc/runtime.h>

#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

#import <mach/mach.h>
#import <mach/mach_time.h>

@interface FBSimulatorHID ()

@property (nonatomic, strong, readonly) FBSimulatorIndigoHID *indigo;
@property (nonatomic, assign, readonly) CGSize mainScreenSize;
@property (nonatomic, assign, readonly) float mainScreenScale;

@end

@implementation FBSimulatorHID

#pragma mark Initializers

static const char *SimulatorHIDClientClassName = "SimulatorKit.SimDeviceLegacyHIDClient";

+ (dispatch_queue_t)workQueue
{
  return dispatch_queue_create("com.facebook.fbsimulatorcontrol.hid", DISPATCH_QUEUE_SERIAL);
}

+ (FBFuture<FBSimulatorHID *> *)hidForSimulator:(FBSimulator *)simulator
{
  return [self reimplementedHidPortForSimulator:simulator];
}

+ (FBFuture<FBSimulatorHID *> *)reimplementedHidPortForSimulator:(FBSimulator *)simulator
{
  // We have to create this before boot, return early if this isn't true.
//  if (simulator.state != FBiOSTargetStateShutdown) {
//    NSLog(@"Simulator must be shut down to create a HID port is %@", simulator.stateString);
//    abort();
//  }
  CGSize mainScreenSize;
  IOMobileFramebufferRef fbConn;
  IOMobileFramebufferGetMainDisplay(&fbConn);
  IOMobileFramebufferGetDisplaySize(fbConn, &mainScreenSize);
  float scale = 3; //mainScreen.scale;
  dispatch_queue_t queue = self.workQueue;

  return [[self
    onQueue:queue registrationPortForSimulator:simulator]
    onQueue:queue map:^(NSNumber *registrationPortNumber) {
      mach_port_t registrationPort = registrationPortNumber.unsignedIntValue;
      return [[FBSimulatorHID_Reimplemented alloc] initWithIndigo:FBSimulatorIndigoHID.reimplemented mainScreenSize:mainScreenSize mainScreenScale:scale queue:queue registrationPort:registrationPort];
    }];
}

+ (FBFuture<NSNumber *> *)onQueue:(dispatch_queue_t)queue registrationPortForSimulator:(FBSimulator *)simulator
{
  return [FBFuture onQueue:queue resolve:^{
    // As with the 'PurpleFBServer', a 'IndigoHIDRegistrationPort' is needed in order for the synthesis of touch events to work appropriately.
    // If this is not set you will see the following logger message in the System log upon booting the simulator
    // 'backboardd[10667]: BKHID: Unable to open Indigo HID system'
    // The dissasembly for backboardd shows that this will happen when the call to 'IndigoHIDSystemSpawnLoopback' fails.
    // Simulator.app creates a Mach Port for the 'IndigoHIDRegistrationPort' and therefore succeeds in the above call.
    // As with 'PurpleFBServer' this can be registered with 'register-head-services'
    // The first step is to create the mach port
    NSError *innerError = nil;
    mach_port_t registrationPort = 0;
    mach_port_t machTask = mach_task_self();
    kern_return_t result = mach_port_allocate(machTask, MACH_PORT_RIGHT_RECEIVE, &registrationPort);
    if (result != KERN_SUCCESS) {
        NSLog(@"Failed to create a Mach Port for IndigoHIDRegistrationPort with code %d", result);
        abort();
    }
    result = mach_port_insert_right(machTask, registrationPort, registrationPort, MACH_MSG_TYPE_MAKE_SEND);
    if (result != KERN_SUCCESS) {
        NSLog(@"Failed to 'insert_right' the mach port with code %d", result);
        abort();
    }
    // Then register it as the 'IndigoHIDRegistrationPort'
      // this will be done later
//    if (![simulator.device registerPort:registrationPort service:@"IndigoHIDRegistrationPort" error:&innerError]) {
//        NSLog(@"Failed to register %d as the IndigoHIDRegistrationPort", registrationPort);
//        abort();
//    }
    return [FBFuture futureWithResult:@(registrationPort)];
  }];
}

- (instancetype)initWithIndigo:(FBSimulatorIndigoHID *)indigo mainScreenSize:(CGSize)mainScreenSize queue:(dispatch_queue_t)queue
{
  return [self initWithIndigo:indigo mainScreenSize:mainScreenSize mainScreenScale:1.0 queue:queue];
}

- (instancetype)initWithIndigo:(FBSimulatorIndigoHID *)indigo mainScreenSize:(CGSize)mainScreenSize mainScreenScale:(float)mainScreenScale queue:(dispatch_queue_t)queue
{
  self = [super init];
  if (!self) {
    return nil;
  }

  _indigo = indigo;
  _mainScreenSize = mainScreenSize;
  _queue = queue;
  _mainScreenScale = mainScreenScale;

  return self;
}

#pragma mark Lifecycle

- (FBFuture<NSNull *> *)connect
{
  NSAssert(NO, @"-[%@ %@] is abstract and should be overridden", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
  return nil;
}

- (void)disconnect
{
  NSAssert(NO, @"-[%@ %@] is abstract and should be overridden", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)dealloc
{
  [self disconnect];
}

#pragma mark NSObject

- (NSString *)description
{
  NSAssert(NO, @"-[%@ %@] is abstract and should be overridden", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
  return nil;
}

#pragma mark HID Manipulation

- (FBFuture<NSNull *> *)sendKeyboardEventWithDirection:(FBSimulatorHIDDirection)direction keyCode:(unsigned int)keycode
{
  return [self sendIndigoMessageDataOnWorkQueue:[self.indigo keyboardWithDirection:direction keyCode:keycode]];
}

- (FBFuture<NSNull *> *)sendButtonEventWithDirection:(FBSimulatorHIDDirection)direction button:(FBSimulatorHIDButton)button
{
  return [self sendIndigoMessageDataOnWorkQueue:[self.indigo buttonWithDirection:direction button:button]];
}

- (FBFuture<NSNull *> *)sendTouchWithType:(FBSimulatorHIDDirection)type x:(double)x y:(double)y
{
  return [self sendIndigoMessageDataOnWorkQueue:[self.indigo touchScreenSize:self.mainScreenSize screenScale:self.mainScreenScale direction:type x:x y:y]];
}

#pragma mark Private

- (FBFuture<NSNull *> *)sendIndigoMessageDataOnWorkQueue:(NSData *)data
{
  return [FBFuture onQueue:self.queue resolve:^{
    return [self sendIndigoMessageData:data];
  }];
}

- (FBFuture<NSNull *> *)sendIndigoMessageData:(NSData *)data
{
  NSAssert(NO, @"-[%@ %@] is abstract and should be overridden", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
  return nil;
}

@end

@implementation FBSimulatorHID_Reimplemented

#pragma mark Initializers

- (instancetype)initWithIndigo:(FBSimulatorIndigoHID *)indigo mainScreenSize:(CGSize)mainScreenSize queue:(dispatch_queue_t)queue registrationPort:(mach_port_t)registrationPort
{
  return [self initWithIndigo:indigo mainScreenSize:mainScreenSize mainScreenScale:1.0 queue:queue registrationPort:registrationPort];
}

- (instancetype)initWithIndigo:(FBSimulatorIndigoHID *)indigo mainScreenSize:(CGSize)mainScreenSize mainScreenScale:(float)mainScreenScale queue:(dispatch_queue_t)queue registrationPort:(mach_port_t)registrationPort
{
  self = [super initWithIndigo:indigo mainScreenSize:mainScreenSize mainScreenScale:mainScreenScale queue:queue];
  if (!self) {
    return nil;
  }

  _registrationPort = registrationPort;
  _replyPort = 0;

  return self;
}

#pragma mark NSObject

- (NSString *)description
{
  if (self.registrationPort == 0) {
    return @"Indigo HID Port: Unregistered";
  }
  if (self.replyPort == 0) {
    return [NSString stringWithFormat:@"Indigo HID Port: Registered %d but no reply port", self.registrationPort];
  }
  return [NSString stringWithFormat:@"Indigo HID Port: Registration Port %u, reply port %d", self.registrationPort, self.replyPort];
}

#pragma mark Lifecycle

- (FBFuture<NSNull *> *)connect
{
  if (self.registrationPort == 0) {
      NSLog(@"Cannot connect when there is no registration port");
    abort();
  }
  if (self.replyPort != 0) {
      NSLog(@"Called connect when already connected, will disconnect and reconnect");
      self.replyPort = 0;
    //return FBFuture.empty;
  }

  return [FBFuture onQueue:self.queue resolve:^ FBFuture<NSNull *> * {
    // Attempt to perform the handshake.
    mach_msg_size_t size = 0x400;
    // FBControlCoreGlobalConfiguration.regularTimeout = 30
    mach_msg_timeout_t timeout = ((unsigned int) 1) * 1000;
    mach_msg_header_t *handshakeHeader = calloc(1, sizeof(mach_msg_header_t));
    handshakeHeader->msgh_bits = 0;
    handshakeHeader->msgh_size = size;
    handshakeHeader->msgh_remote_port = 0;
    handshakeHeader->msgh_local_port = self.registrationPort;

    kern_return_t result = mach_msg(handshakeHeader, MACH_RCV_LARGE | MACH_RCV_MSG | MACH_RCV_TIMEOUT, 0x0, size, self.registrationPort, timeout, 0x0);
    if (result != KERN_SUCCESS) {
      free(handshakeHeader);
        NSLog(@"Failed to get the Indigo Reply Port %d", result);
        return FBFuture.empty;
    } else {
        NSLog(@"Successfully received the Indigo Reply Port: %d", handshakeHeader->msgh_remote_port);
    }
    // We have the registration port, so we can now set it.
    self.replyPort = handshakeHeader->msgh_remote_port;
    free(handshakeHeader);
    return FBFuture.empty;
  }];
}

- (void)disconnect
{
  if (self.registrationPort == 0) {
    return;
  }
  mach_port_destroy(mach_task_self(), self.registrationPort);
  self.registrationPort = 0;
  self.replyPort = 0;
}

- (void)dealloc
{
  [self disconnect];
}

#pragma mark Private

- (FBFuture<NSNull *> *)sendIndigoMessageData:(NSData *)data
{
  if (self.replyPort == 0) {
      NSLog(@"The Reply Port has not been obtained yet. Call -connect: first");
      abort();
  }

  // Extract the message
  IndigoMessage *message = (IndigoMessage *) data.bytes;
  mach_msg_size_t size = (mach_msg_size_t) data.length;

  // Set the header of the message
  message->header.msgh_bits = 0x13;
  message->header.msgh_size = size;
  message->header.msgh_remote_port = self.replyPort;
  message->header.msgh_local_port = 0;
  message->header.msgh_voucher_port = 0;
  message->header.msgh_id = 0;

  mach_msg_return_t result = mach_msg_send((mach_msg_header_t *) message);
  if (result != ERR_SUCCESS) {
    NSLog(@"The mach_msg_send failed with error %d", result);
    abort();
  }
  return FBFuture.empty;
}

@end
