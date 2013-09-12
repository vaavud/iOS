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

@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (weak, nonatomic) IBOutlet UIWebView *webView;

- (IBAction) backButtonPushed;

@end

@implementation TermsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.delegate = self;
    
    NSString *html = [Terms getTermsOfService];
    [self.webView loadHTMLString:html baseURL:[NSURL URLWithString:@"http://vaavud.com"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) backButtonPushed {
    if ([self.webView.request.URL.path compare:@"/"] != NSOrderedSame) {
        NSString *html = [Terms getTermsOfService];
        [self.webView loadHTMLString:html baseURL:[NSURL URLWithString:@"http://vaavud.com"]];
    }
    else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (UIBarPosition) positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

@end
