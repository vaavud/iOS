//
//  ShareDialog.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 30/06/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "ShareDialog.h"

@implementation ShareDialog

- (IBAction)okButtonTapped:(id)sender {
    [self.delegate share:self.textView.text];
}

- (IBAction)cancelButtonTapped:(id)sender {
    [self.delegate cancelShare];
}

@end
