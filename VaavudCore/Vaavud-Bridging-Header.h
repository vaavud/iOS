//
//  Vaavud-Bridging-Header.h
//  Vaavud
//
//  Created by Gustaf Kugelberg on 22/01/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

#ifndef Vaavud_Vaavud_Bridging_Header_h
#define Vaavud_Vaavud_Bridging_Header_h

#import "AppDelegate.h"
#import "UIColor+VaavudColors.h"
#import "LocationManager.h"
#import "MeasurementSession.h"
#import "MeasurementPoint.h"
#import "UnitUtil.h"
#import "Property+Util.h"
#import "MeasurementAnnotation.h"
#import "TabBarController.h"
#import "AccountManager.h"
#import "ServerUploadManager.h"
#import "Mixpanel.h"
#import "RegisterViewController.h"

#import <VaavudElectronicSDK/VEVaavudElectronicSDK.h>
#import "MjolnirMeasurementController.h"

#import "SavingWindMeasurementController.h" // tabort

#import <DropboxSDK/DropboxSDK.h>

#import "MagicalRecord.h"
#import "MagicalRecord+Actions.h"
#import "NSManagedObject+MagicalRecord.h"
#import "NSManagedObject+MagicalFinders.h"
#import "NSManagedObjectContext+MagicalRecord.h"
#import "NSManagedObjectContext+MagicalSaves.h"
#import "UUIDUtil.h"

#import "FirstTimeFlowController.h" // FIXME: This class needs to be refactored

#endif
