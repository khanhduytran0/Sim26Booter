//
//  FBSimulatorHID+Struct26.h
//
//
//  Created by Duy Tran on 3/10/25.
//

#import "FBSimulatorHID.h"
#import "Indigo26.h"

@interface FBSimulatorHID (Struct26)
- (BOOL)sendIndigoMessageDirect:(IndigoMessage *)message size:(NSUInteger)size;
@end
