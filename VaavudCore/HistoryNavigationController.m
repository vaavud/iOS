//
//  HistoryNavigationController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 24/01/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "HistoryNavigationController.h"
#import "HistoryTableViewController.h"
#import "RegisterViewController.h"
#import "AccountManager.h"

@interface HistoryNavigationController ()

@end

@implementation HistoryNavigationController

- (void)historyLoaded {
    if ([self.topViewController conformsToProtocol:@protocol(HistoryLoadedListener)]) {
        id<HistoryLoadedListener>listener = (id<HistoryLoadedListener>)self.topViewController;
        [listener historyLoaded];
    }
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showVc) name:@"DidLogInOut" object:nil];
        [self showVc];
    }
    
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DidLogInOut" object:nil];
}

-(void)viewDidAppear:(BOOL)animated {
    NSLog(@"history nav controller appeared");
}

-(void)showVc {
    NSLog(@"showAppropriateViewController");

    if ([AccountManager sharedInstance].isLoggedIn) {
        NSLog(@"Logged in - Showing history");

        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        HistoryTableViewController *htvc = [storyboard instantiateViewControllerWithIdentifier:@"HistoryTableViewController"];
//        [htvc update];
        self.viewControllers = @[htvc];
    }
    else {
        NSLog(@"Not logged in - Showing registration");
        [self showLogin];
    }
}

-(void)showLogin {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Register" bundle:nil];
    RegisterViewController *registration = [storyboard instantiateViewControllerWithIdentifier:@"RegisterViewController"];
    registration.teaserLabelText = NSLocalizedString(@"HISTORY_REGISTER_TEASER", nil);
    registration.completion = ^{ [self showVc]; };
    registration.navigationItem.hidesBackButton = YES;
    
    self.viewControllers = @[registration];
}


@end
