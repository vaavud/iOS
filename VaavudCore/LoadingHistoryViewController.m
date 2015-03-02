//
//  LoadingHistoryViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 03/06/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "LoadingHistoryViewController.h"
#import "ServerUploadManager.h"
#import "HistoryRootViewController.h"

@interface LoadingHistoryViewController ()

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation LoadingHistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"HISTORY_TITLE", nil);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkIfDone) userInfo:nil repeats:YES];
}

- (void)checkIfDone {
    if (![ServerUploadManager sharedInstance].isHistorySyncBusy) {
        [self.timer invalidate];
        self.timer = nil;
        HistoryRootViewController *historyRootViewController = (HistoryRootViewController *)[self.navigationController parentViewController];
        [historyRootViewController chooseContentControllerWithNoHistorySync];
    }
}

@end
