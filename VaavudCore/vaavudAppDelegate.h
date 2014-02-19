//
//  vaavudAppDelegate.h
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "AccountUtil.h"

@protocol FacebookAuthenticationDelegate <NSObject>
- (void) facebookAuthenticationSuccess:(enum AuthenticationResponseType)response;
- (void) facebookAuthenticationFailure:(enum AuthenticationResponseType)response message:(NSString*)message displayFeedback:(BOOL)displayFeedback;
@end

@interface vaavudAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) NSString* xCallbackSuccess;
@property (nonatomic, weak) id<FacebookAuthenticationDelegate> facebookAuthenticationDelegate;

- (void) openFacebookSession:(enum AuthenticationActionType)action;

@end
