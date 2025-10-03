//
//  FBSimulatorHID+Struct26.m
//
//
//  Created by Duy Tran on 3/10/25.
//

#import "FBSimulatorHID+Struct26.h"

@implementation FBSimulatorHID_Reimplemented (Struct26)
- (BOOL)sendIndigoMessageDirect:(IndigoMessage *)message size:(NSUInteger)size
{
    if (self.replyPort == 0) {
        NSLog(@"The Reply Port has not been obtained yet. Call -connect: first");
        return NO;
    }
    
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
        return NO;
    }
    return YES;
}
@end
