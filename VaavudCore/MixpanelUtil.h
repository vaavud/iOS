//
//  MixpanelUtil.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 04/09/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MixpanelUtil : NSObject

+ (void) registerUserAsMixpanelProfile;
+ (void) updateMeasurementProperties:(BOOL)onlySuperProperties;
+ (void) addMapInteractionToProfile;

@end
