//
//  SimIndigoHIDServer.m
//  SimulatorShimFrameworks
//
//  Created by Duy Tran on 30/9/25.
//

@import Darwin;
@import Foundation;
#include <IOKit/IOKitLib.h>
#include <IOKit/IOTypes.h>
#include <IOKit/hid/IOHIDEventSystem.h>
#import "FBSimulatorControl/HID/FBSimulatorHID.h"
#import "FBSimulatorControl/HID/FBSimulatorHID+Struct26.h"
#import "Indigo26.h"

FBSimulatorHID_Reimplemented *instance;

void handle_touch_event(IOHIDEventRef parentEvent) {
    NSArray *childrens = (__bridge NSArray *)IOHIDEventGetChildren(parentEvent);
    for (id child in childrens) {
        IOHIDEventRef event = (__bridge IOHIDEventRef)child;
#pragma pack(push, 4)
        struct {
            IndigoMessage msg;
            IndigoPayload fingerPayload;
        } msg = {
            .msg = {
                .innerSize = sizeof(IndigoPayload),
                .eventType = 2, // IndigoEventTypeTouch
                .payload = {
                    .type = INDIGO_EVENT_DIGITIZER_FINGER,
                    .timestamp = mach_absolute_time(),
                    .flags = 0,
                    .event.digitizerFinger = {
                        .index = 0x00400002, //IOHIDEventGetIntegerValue(parentEvent, (IOHIDEventField)kIOHIDEventFieldDigitizerIndex),
                        .identity = IOHIDEventGetIntegerValue(parentEvent, (IOHIDEventField)kIOHIDEventFieldDigitizerIdentity),
                        .eventMask = IOHIDEventGetIntegerValue(parentEvent, (IOHIDEventField)kIOHIDEventFieldDigitizerEventMask),
                        .options = 0x32,
                        .field12 = 1,
                        .field13 = 2
                    }
                }
            },
            //    .padding = 0x1ff,
            .fingerPayload = {
                .type = INDIGO_EVENT_DIGITIZER_FINGER,
                .timestamp = msg.msg.payload.timestamp,
                .flags = 0,
                .event.digitizerFinger = {
                    .index = IOHIDEventGetIntegerValue(event, (IOHIDEventField)kIOHIDEventFieldDigitizerIndex),
                    .identity = IOHIDEventGetIntegerValue(event, (IOHIDEventField)kIOHIDEventFieldDigitizerIdentity),
                    .eventMask = IOHIDEventGetIntegerValue(event, (IOHIDEventField)kIOHIDEventFieldDigitizerEventMask),
                    //.buttonMask = IOHIDEventGetIntegerValue(event, (IOHIDEventField)kIOHIDEventFieldDigitizerButtonMask),
                    .x = IOHIDEventGetFloatValue(event, (IOHIDEventField)kIOHIDEventFieldDigitizerX),
                    .y = IOHIDEventGetFloatValue(event, (IOHIDEventField)kIOHIDEventFieldDigitizerY),
                    .z = IOHIDEventGetFloatValue(event, (IOHIDEventField)kIOHIDEventFieldDigitizerZ),
                    // FIXME: is this right?
                    .tipPressure = IOHIDEventGetFloatValue(event, (IOHIDEventField)kIOHIDEventFieldDigitizerPressure),
                    .twist = IOHIDEventGetFloatValue(event, (IOHIDEventField)kIOHIDEventFieldDigitizerTwist),
                    .minorRadius = IOHIDEventGetFloatValue(event, (IOHIDEventField)kIOHIDEventFieldDigitizerMinorRadius),
                    .majorRadius = IOHIDEventGetFloatValue(event, (IOHIDEventField)kIOHIDEventFieldDigitizerMajorRadius),
                    .quality = IOHIDEventGetFloatValue(event, (IOHIDEventField)kIOHIDEventFieldDigitizerQuality),
                    .density = IOHIDEventGetFloatValue(event, (IOHIDEventField)kIOHIDEventFieldDigitizerDensity),
                    .irregularity = IOHIDEventGetFloatValue(event, (IOHIDEventField)kIOHIDEventFieldDigitizerIrregularity),
                    // FIXME: is this right?
                    .inRange = IOHIDEventGetIntegerValue(event, (IOHIDEventField)kIOHIDEventFieldDigitizerRange),
                    .touch = IOHIDEventGetIntegerValue(event, (IOHIDEventField)kIOHIDEventFieldDigitizerTouch),
                    .options = 0x32,
                    .field12 = 1,
                    .field13 = 2
                }
            }
        };
#pragma pack(pop)
        //memcpy(&msg.fingerPayload, &msg.msg.payload, sizeof(IndigoPayload));
        BOOL sent = [instance sendIndigoMessageDirect:&msg size:sizeof(msg)];
        if(!sent) {
            // Attempt to reconnect
            [instance connect];
        }
    }
}

void handle_event(void* target, void* refcon, IOHIDServiceRef service, IOHIDEventRef event) {
    int type = IOHIDEventGetType(event);
    switch(type) {
        case kIOHIDEventTypeDigitizer:
            handle_touch_event(event);
            break;
        // TODO: implement these events
//        case kIOHIDEventTypeVendorDefined:
//        case kIOHIDEventTypeOrientation:
//        case kIOHIDEventTypeAmbientLightSensor:
//        case kIOHIDEventTypeAccelerometer:
//        case kIOHIDEventTypeProximity:
//        case kIOHIDEventTypeTemperature:
//        case 20://kIOHIDEventTypeGyro:
//        case 21://kIOHIDEventTypeCompass:
//        case 31://kIOHIDEventTypeAtmosphericPressure:
//            return;
        default:
            //printf("Received event of type %2d from service %p.\n", type, event);
            break;
    }
}

mach_port_t SimulatorHIDServerInit() {
    // Create and open an event system
    IOHIDEventSystemRef systemRef = IOHIDEventSystemCreate(NULL);
    IOHIDEventSystemOpen(systemRef, handle_event, NULL, NULL, NULL);
    
    // Setup our Mach listener
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    [[FBSimulatorHID
        hidForSimulator:(id)[NSObject class]]
     onQueue:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0) doOnResolved:^(FBSimulatorHID *hid) {
        instance = hid;
        NSLog(@"HID server: %@", hid);
        dispatch_semaphore_signal(sema);
    }];
    
    // wait until we have a valid port
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    assert(instance != nil);
    [instance connect];
    
    return instance.registrationPort;
    
}
