//
//  FormatUtil.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 03/10/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "FormatUtil.h"

@implementation FormatUtil

+ (NSString *)formatRelativeDate:(NSDate *)date {
    double timeAgoSeconds = [date timeIntervalSinceNow];
    if (timeAgoSeconds > 0) {
        return NSLocalizedString(@"REL_TIME_FUTURE", nil);
    }
    timeAgoSeconds = abs(timeAgoSeconds);
    int minsAgo = round(timeAgoSeconds / 60.0);
    int hoursAgo = round(timeAgoSeconds / 3600.0);
    int daysAgo = round(timeAgoSeconds / (3600.0*24.0));
    if (minsAgo < 1) {
        return NSLocalizedString(@"REL_TIME_NOW", nil);
    }
    else if (minsAgo == 1) {
        return NSLocalizedString(@"REL_TIME_1_MIN_AGO", nil);
    }
    else if (minsAgo < 60) {
        return [NSString stringWithFormat:NSLocalizedString(@"REL_TIME_X_MINS_AGO", nil), minsAgo];
    }
    else if (hoursAgo == 1) {
        return NSLocalizedString(@"REL_TIME_1_HOUR_AGO", nil);
    }
    else if (hoursAgo < 48) {
        return [NSString stringWithFormat:NSLocalizedString(@"REL_TIME_X_HOURS_AGO", nil), hoursAgo];
    }
    else if (daysAgo == 1) {
        return NSLocalizedString(@"REL_TIME_1_DAY_AGO", nil);
    }
    else {
        return [NSString stringWithFormat:NSLocalizedString(@"REL_TIME_X_DAYS_AGO", nil), daysAgo];
    }
}

+ (NSString *)formatValueWithTwoDigits:(float)value {
    if (round(value) >= 10) {
        return [NSString localizedStringWithFormat:@"%.0f", value];
    }
    else {
        return [NSString localizedStringWithFormat:@"%.1f", value];
    }
}

+ (NSString *)formatValueWithThreeDigits:(double) value {
    if (round(value) >= 100.0) {
        return [NSString localizedStringWithFormat:@"%.0f", value];
    }
    else {
        return [NSString localizedStringWithFormat:@"%.1f", value];
    }
}

@end
