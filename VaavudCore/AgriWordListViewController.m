//
//  AgriWordListViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 05/11/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "AgriWordListViewController.h"

@interface AgriWordListViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation AgriWordListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"ABOUT_TITLE", nil);
    
    self.webView.delegate = self;
    
    NSString *html =
    @"<html>"
    "<head>"
    "<title>Glossary</title>"
    "<meta http-equiv='content-type' content='text/html; charset=utf-8'/>"
    "<style type='text/css'>"
    "div.heading {background-color:#008000;color:#ffffff;} "
    "div.heading p {padding:5px 5px 5px 5px;}"
    "</style>"
    "</head>"
    "<body>"
    "<div class='heading'>"
    "<p><span>Reducerande utrustning</span></p>"
    "</div>"
    "<div>"
    "<p><span>Dette är spridere eller utrustning som efter provning placerats i någon af klasserna 50%, 75% eller 90% avdriftsreduktion, hvilket medför betydeligt kortere skyddavstand.</span></p>"
    "</div>"
    "<div class='heading'>"
    "<p><span>Dosis</span></p>"
    "</div>"
    "<div>"
    "<p><span>Läs på etiketten för de preparat du ska använda. Den högsta dos som anges där räknas som hel dos. Din använda dos bedömer du i förhållande till denna.</span></p><p><span>Exempel: För preparat X rekommenderas en dos på 0,4-0,8 l/ha för användning i stråsäd och 0,2-0,4 l/ha för användning i oljeväxter. Hel dos av preparat X är därmed alltid lika med 0,8 l/ha. Halv och kvarts dos for preparat X är då alltid lika med 0,4 respektive 0,2 l/ha.</span></p>"
    "</div>"
    "<div class='heading'>"
    "<p><span>Bomhöjd</span></p>"
    "</div>"
    "<div>"
    "<p><span>Välj bomhöjd 25, 40 eller 60 cm över grödan.</span></p><p><span>Normalt rekommenderad höjd är 40-50 cm. Vid stora bombredder eller instabil bom bör du välja&nbsp; 60 cm p.g.a. bomrörelser.</span></p><p><span>Vissa tekniker, t.ex. bandspruta, släpduk eller Hardi Twin får avläsas på 25 cm bomhöjd.</span></p>"
    "</div>"
    "<div class='heading'>"
    "<p><span>Duschkvalitet</span></p>"
    "</div>"
    "<div>"
    "<p><span>Duschkvalitet (droppstorleksfördelningen) delas in i klasserna fin, medium och grov. På den konventionella sprutan är det valet av munstycke och tryck som påverkar duschkvaliteten. </span></p>"
    "</div>"
    "<div class='heading'>"
    "<p><span>Allmän/särskild hänsyn</span></p>"
    "</div>"
    "<div>"
    "<p><span>Man bör aldrig sprida närmare den fältkant i vindriktningen än vad om vid rådande förutsätningar anges som riktvärde for skyddsavstand vid Allmän hänsyn. Om det finns områden eller objekt i närheten som fordrar särskild hänsyn blir dessa som avgör hur nära fältkanten man kan sprida.</span></p>"
    "</div>"
    "</body>"
    "</html>";

    [self.webView loadHTMLString:html baseURL:[NSURL URLWithString:@"http://vaavud.com"]];
    
    self.view.autoresizesSubviews = YES;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end
