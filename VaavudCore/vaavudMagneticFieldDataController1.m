//
//  vaavudMagneticFieldDataController.m
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "vaavudMagneticFieldDataController1.h"

@implementation vaavudMagneticFieldDataController1


+ (MyGizmoClass*)sharedManager
{
    if (sharedGizmoManager == nil) {
        sharedGizmoManager = [[super allocWithZone:NULL] init];
    }
    return sharedGizmoManager;
}

@end
