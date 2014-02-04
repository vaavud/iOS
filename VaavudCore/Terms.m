//
//  Terms.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 15/07/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "Terms.h"

@implementation Terms

+ (NSString*)getTermsOfService {
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];

    NSString *aboutVaavud = [NSString stringWithFormat:NSLocalizedString(@"ABOUT_VAAVUD_TEXT", nil), appVersion];
    aboutVaavud = [aboutVaavud stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/><br/>"];
    
    NSString* html = [NSString stringWithFormat:
    @"<html><head><style type='text/css'>"
    "a {color:#00aeef;text-decoration:none}\n"
    "body {background-color:#ffffff;}"
    "</style></head><body>"
    "<center style='padding-top:20px;font-family:helvetica,arial'>"
    "%@<br/><br/><br/>"
    "<a href='http://vaavud.com/legal/terms?source=app'>%@</a>&nbsp; &nbsp; <a href='http://vaavud.com/legal/privacy?source=app'>%@</a>"
    "</center></body></html>",
    aboutVaavud, NSLocalizedString(@"LINK_TERMS_OF_SERVICE", nil), NSLocalizedString(@"LINK_PRIVACY_POLICY", nil)];
    
    return html;
}

@end
