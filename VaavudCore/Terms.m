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
    
    NSString* html = @"<h3>TERMS AND CONDITIONS OF USE OF THE SERVICES</h3>"
    "<h3>HIGHLIGHTS OF THE TERMS</h3>"
    "<ul>"
    "<li>Vaavud offers services that help you measure wind speed; however:</li>"
    "<li>When using our Services you are still responsible for any risks associated with your athletic or recreational activities</li>"
    "<li>Vaavud makes no warranties and is not liable for your use of the Services</li>"
    "<li>We take care of the personal information you upload and share per default on Vaavud. Please see our privacy policy</li>"
    "<li>We may terminate your accounts if the terms are violated</li>"
    "<li>The service is not intended for children under 13</li>"
    "<li>Contact our support team for help or questions</li>"
    "</ul>"
    "<a href='http://vaavud.com/terms'>Terms of Service</a><br/>"
    "<a href='http://vaavud.com/privacy'>Privacy Policy</a><br/>"
    ;
    
    return html;
}

@end
