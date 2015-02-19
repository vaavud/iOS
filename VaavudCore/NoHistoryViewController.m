//
//  NoHistoryViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 27/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "NoHistoryViewController.h"
#import "Mixpanel.h"
#import "Property+Util.h"
#import "UIColor+VaavudColors.h"

@interface NoHistoryViewController ()

@property (nonatomic, weak) IBOutlet UILabel *noMeasurementsLabel;
@property (nonatomic, weak) IBOutlet UILabel *gotoMeasureLabel;
@property (nonatomic, weak) IBOutlet UIView *arrowView;

@end

@implementation NoHistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        self.navigationController.navigationBar.tintColor = [UIColor blackColor];
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    }

    self.navigationItem.title = NSLocalizedString(@"HISTORY_TITLE", nil);
    self.noMeasurementsLabel.text = NSLocalizedString(@"HISTORY_NO_MEASUREMENTS", nil);
    self.gotoMeasureLabel.text = NSLocalizedString(@"HISTORY_GO_TO_MEASURE", nil);
    
    self.noMeasurementsLabel.textColor = [UIColor vaavudColor];
    
    self.noMeasurementsLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.noMeasurementsLabel.numberOfLines = 0;
    self.gotoMeasureLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.gotoMeasureLabel.numberOfLines = 0;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"Empty History Screen"];
    }
}

@end
