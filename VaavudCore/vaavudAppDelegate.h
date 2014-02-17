//
//  vaavudAppDelegate.h
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@protocol FacebookAuthenticationDelegate <NSObject>
- (void) facebookAuthenticationSuccess:(NSString*)status;
- (void) facebookAuthenticationFailure:(NSString*)status message:(NSString*)message displayFeedback:(BOOL)displayFeedback;
@end

@interface vaavudAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) NSString* xCallbackSuccess;
@property (nonatomic, weak) id<FacebookAuthenticationDelegate> facebookAuthenticationDelegate;

- (void) openFacebookSession:(NSString*)action;

@end
