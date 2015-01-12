//
//  MixpanelUtil.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 04/09/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "MixpanelUtil.h"
#import "Mixpanel.h"
#import "Property+Util.h"
#import "AccountManager.h"
#import "MeasurementSession+Util.h"

@implementation MixpanelUtil

+ (void)registerUserAsMixpanelProfile {
    if ([Property isMixpanelPeopleEnabled] && [[AccountManager sharedInstance] isLoggedIn] && [Property getAsString:KEY_USER_ID]) {
        
        NSString *email = [Property getAsString:KEY_EMAIL];
        NSDate *creationTime = [Property getAsDate:KEY_CREATION_TIME];

        if (email && creationTime) {
            NSString *firstName = [Property getAsString:KEY_FIRST_NAME];
            NSString *lastName = [Property getAsString:KEY_LAST_NAME];
            NSString *mixpanelId = [Mixpanel sharedInstance].distinctId;
            
            NSLog(@"[MixpanelUtil] Register Mixpanel People profile: email=%@, created=%@, first_name=%@, last_name=%@", email, creationTime, firstName, lastName);

#ifdef AGRI
            [[Mixpanel sharedInstance].people set:@{
                                                    @"$email": email,
                                                    @"$created": [MixpanelUtil toUTFDateString:creationTime],
                                                    @"$first_name": (firstName) ? firstName : [NSNull null],
                                                    @"$last_name": (lastName) ? lastName : [NSNull null],
                                                    @"Distinct Id": mixpanelId,
                                                    @"Uses Agriculture": @"true"
                                                    }];
            
#elif CORE
            [[Mixpanel sharedInstance].people set:@{
                                   @"$email": email,
                                   @"$created": [MixpanelUtil toUTFDateString:creationTime],
                                   @"$first_name": (firstName) ? firstName : [NSNull null],
                                   @"$last_name": (lastName) ? lastName : [NSNull null],
                                   @"Distinct Id": mixpanelId
                                   }];
#endif

            [MixpanelUtil updateMeasurementProperties:NO];
        }
    }
}

+ (void)updateMeasurementProperties:(BOOL)onlySuperProperties {
    NSDate *firstMeasurement = [MixpanelUtil dateOfFirstMeasurement];
    NSDate *lastMeasurement = [MixpanelUtil dateOfLastMeasurement];
    NSInteger measurementCount = [MeasurementSession MR_countOfEntities];
    NSInteger realMeasurementCount = [MeasurementSession MR_countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"windSpeedAvg > 0"]];

    [[Mixpanel sharedInstance] registerSuperProperties:@{
                                                         @"Measurements":[NSNumber numberWithInteger:measurementCount],
                                                         @"Real Measurements":[NSNumber numberWithInteger:realMeasurementCount]
                                                         }];

    if (!onlySuperProperties && [Property isMixpanelPeopleEnabled] && [[AccountManager sharedInstance] isLoggedIn] && [Property getAsString:KEY_USER_ID]) {
        [[Mixpanel sharedInstance].people set:@{
                                                @"Measurements":[NSNumber numberWithInteger:measurementCount],
                                                @"Real Measurements":[NSNumber numberWithInteger:realMeasurementCount],
                                                @"First Measurement": (firstMeasurement) ? [MixpanelUtil toUTFDateString:firstMeasurement] : [NSNull null],
                                                @"Last Measurement": (lastMeasurement) ? [MixpanelUtil toUTFDateString:lastMeasurement] : [NSNull null]
                                                }];
    }
}

+ (void)addMapInteractionToProfile {
    if ([Property isMixpanelPeopleEnabled] && [[AccountManager sharedInstance] isLoggedIn] && [Property getAsString:KEY_USER_ID]) {
        [[Mixpanel sharedInstance].people increment:@{@"Map Interactions": @1}];
        [[Mixpanel sharedInstance].people set:@{@"Last Map Interaction": [MixpanelUtil toUTFDateString:[NSDate date]]}];
    }
}

+ (NSDate *)dateOfFirstMeasurement {
    MeasurementSession *measurementSession = [MeasurementSession MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"windSpeedAvg > 0"] sortedBy:@"startTime" ascending:YES];
    if (measurementSession && measurementSession.startTime) {
        return measurementSession.startTime;
    }
    return nil;
}

+ (NSDate *)dateOfLastMeasurement {
    MeasurementSession *measurementSession = [MeasurementSession MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"windSpeedAvg > 0"] sortedBy:@"startTime" ascending:NO];
    if (measurementSession && measurementSession.startTime) {
        return measurementSession.startTime;
    }
    return nil;
}

+ (NSString *)toUTFDateString:(NSDate *)date {
    if (!date) {
        return nil;
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    return [formatter stringFromDate:date];
}

@end
