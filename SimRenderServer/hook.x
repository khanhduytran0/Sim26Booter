@import IOSurface;
#import "IOMobileFramebuffer.h"

typedef CFTypeRef IOSurfaceClientRef;
int IOSurfaceClientGetID(IOSurfaceClientRef client);
void IOSurfaceClientSetValue(IOSurfaceClientRef client, NSString *key, id value);

IOMobileFramebufferRef fbConn;
%hookf(void, IOSurfaceClientSetValue, IOSurfaceClientRef client, NSString *key, id value) {
    if([key isEqual:@"SwapCmd"]) {
        uint64_t val = (uint64_t)[value unsignedLongLongValue];
        if(val == 0) { // SFBSwapchainSwapSubmit
            static int surfaceID = 0;
            static IOSurfaceRef surface;
            static CGRect frame;
            int surfaceIDCurr = IOSurfaceClientGetID(client);
            if(surfaceID != surfaceIDCurr) {
                surfaceID = surfaceIDCurr;
                surface = IOSurfaceLookup(surfaceIDCurr);
                frame = CGRectMake(0, 0, IOSurfaceGetWidth(surface), IOSurfaceGetHeight(surface));
            }
            int token;
            IOMobileFramebufferSwapBegin(fbConn, &token);
            IOMobileFramebufferSwapSetLayer(fbConn, 0, surface, frame, frame, 0);
            IOMobileFramebufferSwapEnd(fbConn);
            
            // FIXME: cannot swap small region since subsequent swaps will clear the previous ones
//            int token;
//            IOMobileFramebufferSwapEnd(fbConn);
//            IOMobileFramebufferSwapBegin(fbConn, &token);
//        } else {
//            static int surfaceID = 0;
//            static IOSurfaceRef surface;
//            int surfaceIDCurr = IOSurfaceClientGetID(client);
//            if(surfaceID != surfaceIDCurr) {
//                surfaceID = surfaceIDCurr;
//                surface = IOSurfaceLookup(surfaceIDCurr);
//            }
//            CGRect frame = CGRectMake(val >> 36, (val >> 24) & 0xFFF, (val >> 12) & 0xFFF, val & 0xFFF);
//            IOMobileFramebufferSwapSetLayer(fbConn, 0, surface, frame, frame, 0);
        }
        return;
    }
    %orig(client, key, value);
}

%ctor {
    IOMobileFramebufferGetMainDisplay(&fbConn);
    assert(fbConn);
}
