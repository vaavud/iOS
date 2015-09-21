//
//  TermsPrivacyViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 25/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "TermsPrivacyViewController.h"

@interface TermsPrivacyViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation TermsPrivacyViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = self.termsPrivacyTitle;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_DONE", nil) style:UIBarButtonItemStylePlain target:self action:@selector(doneButtonPushed)];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.termsPrivacyURL]]];

    self.view.autoresizesSubviews = YES;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];    
}

- (void)doneButtonPushed {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end
