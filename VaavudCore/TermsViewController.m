//
//  TermsViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 15/07/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "TermsViewController.h"
#import "Terms.h"
#import "AccountManager.h"
#import "TabBarController.h"

@interface TermsViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation TermsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"ABOUT_TITLE", nil);
    self.navigationItem.backBarButtonItem.title = NSLocalizedString(@"NAVIGATION_BACK", nil);
    
    self.webView.delegate = self;

    NSString *html = [Terms getTermsOfService];
    [self.webView loadHTMLString:html baseURL:[NSURL URLWithString:@"http://vaavud.com"]];
    
    self.view.autoresizesSubviews = YES;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
}

- (IBAction)backButtonPushed {
    if ([self.webView.request.URL.path compare:@"/"] != NSOrderedSame) {
        NSString *html = [Terms getTermsOfService];
        [self.webView loadHTMLString:html baseURL:[NSURL URLWithString:@"http://vaavud.com"]];
    }
}

-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end
