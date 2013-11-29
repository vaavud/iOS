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

@property (weak, nonatomic) IBOutlet UINavigationItem *aboutItem;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;

- (IBAction) backButtonPushed;

@end

@implementation TermsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.screenName = @"About Screen";

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        UIImage *selectedTabImage = [[UIImage imageNamed:@"about_selected.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        self.tabBarItem.selectedImage = selectedTabImage;
    }

    self.navigationBar.delegate = self;
    
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

    if ([self.webView.request.URL.path compare:@"/"] != NSOrderedSame) {
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(backButtonPushed)];
        self.aboutItem.leftBarButtonItem = backButton;
    }
    else {
        self.aboutItem.leftBarButtonItem = nil;
    }
}

- (IBAction) backButtonPushed {
    if ([self.webView.request.URL.path compare:@"/"] != NSOrderedSame) {
        NSString *html = [Terms getTermsOfService];
        [self.webView loadHTMLString:html baseURL:[NSURL URLWithString:@"http://vaavud.com"]];
    }
}

-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (UIBarPosition) positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

@end
