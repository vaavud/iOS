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

    NSString* html = [NSString stringWithFormat:@"<center style='padding-top:20px;font-family:helvetica,arial'>"
    "<p>Vaavud is a Danish technology start-up.</p>"
    "<p>Our mission is to make the best wind meters on the planet in terms of usability, features, and third party integration.</p>"
    "<p>To learn more and to purchase a<br/>Vaavud wind meter visit<br/>Vaavud.com</p>"
    "<p>&copy; Vaavud ApS 2013, all rights reserved<br/>Version: %@ beta</p><br/>"
    "<a href='http://vaavud.com/legal/terms?source=app'>Terms of Service</a>&nbsp; "
    "<a href='http://vaavud.com/legal/privacy?source=app'>Privacy Policy</a>"
    "</center>",
    appVersion
    ];
    
    return html;
}

@end
