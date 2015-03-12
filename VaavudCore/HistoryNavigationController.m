//
//  HistoryNavigationController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 24/01/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "HistoryNavigationController.h"

@interface HistoryNavigationController ()

@end

@implementation HistoryNavigationController

- (void)historyLoaded {
    if ([self.topViewController conformsToProtocol:@protocol(HistoryLoadedListener)]) {
        id<HistoryLoadedListener>listener = (id<HistoryLoadedListener>)self.topViewController;
        [listener historyLoaded];
    }
}

@end
