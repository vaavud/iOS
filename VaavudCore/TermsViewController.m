//
//  TermsViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 15/07/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "TermsViewController.h"
#import "Terms.h"

@interface TermsViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation TermsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.screenName = @"About Screen";

    self.navigationItem.title = NSLocalizedString(@"ABOUT_TITLE", nil);
    self.navigationItem.backBarButtonItem.title = NSLocalizedString(@"NAVIGATION_BACK", nil);
    
    //self.navigationItem.backBarButtonItem.target = self;
    //self.navigationItem.backBarButtonItem.action = @selector(backButtonPushed);

    //self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"NAVIGATION_BACK", nil) style:UIBarButtonItemStylePlain target:self action:@selector(backButtonPushed)];
    
    self.webView.delegate = self;

    NSString *html = [Terms getTermsOfService];
    [self.webView loadHTMLString:html baseURL:[NSURL URLWithString:@"http://vaavud.com"]];
    
    self.view.autoresizesSubviews = YES;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    /*
    if ([self.webView.request.URL.path compare:@"/"] != NSOrderedSame) {
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"NAVIGATION_BACK", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(backButtonPushed)];
        self.navigationItem.leftBarButtonItem = backButton;
    }
    else {
        self.navigationItem.leftBarButtonItem = nil;
    }
    */
}

- (IBAction) backButtonPushed {
    NSLog(@"backButtonPushed");
    if ([self.webView.request.URL.path compare:@"/"] != NSOrderedSame) {
        NSString *html = [Terms getTermsOfService];
        [self.webView loadHTMLString:html baseURL:[NSURL URLWithString:@"http://vaavud.com"]];
    }
}

-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

/*
- (UIBarPosition) positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}
 */

@end
