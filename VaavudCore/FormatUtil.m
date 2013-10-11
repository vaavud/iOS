//
//  FormatUtil.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 03/10/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "FormatUtil.h"

@implementation FormatUtil

+ (NSString*) formatRelativeDate:(NSDate*) date {
    double timeAgoSeconds = [date timeIntervalSinceNow];
    if (timeAgoSeconds > 0) {
        return @"future";
    }
    timeAgoSeconds = abs(timeAgoSeconds);
    int minsAgo = round(timeAgoSeconds / 60.0);
    int hoursAgo = round(timeAgoSeconds / 3600.0);
    int daysAgo = round(timeAgoSeconds / (3600.0*24.0));
    if (minsAgo < 1) {
        return @"just now";
    }
    else if (minsAgo == 1) {
        return [NSString stringWithFormat:@"%d min ago", minsAgo];
    }
    else if (minsAgo < 60) {
        return [NSString stringWithFormat:@"%d mins ago", minsAgo];
    }
    else if (hoursAgo == 1) {
        return [NSString stringWithFormat:@"%d hour ago", hoursAgo];
    }
    else if (hoursAgo < 48) {
        return [NSString stringWithFormat:@"%d hours ago", hoursAgo];
    }
    else if (daysAgo == 1) {
        return [NSString stringWithFormat:@"%d day ago", daysAgo];
    }
    else {
        return [NSString stringWithFormat:@"%d days ago", daysAgo];
    }
}

+ (NSString*) formatValueWithTwoDigits:(float) value {
    if (round(value) >= 10) {
        return [NSString stringWithFormat: @"%.0f", value];
    }
    else {
        return [NSString stringWithFormat: @"%.1f", value];
    }
}

+ (NSString*) formatValueWithThreeDigits:(double) value {
    if (round(value) >= 100.0) {
        return [NSString stringWithFormat: @"%.0f", value];
    }
    else {
        return [NSString stringWithFormat: @"%.1f", value];
    }
}

@end
