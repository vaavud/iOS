//
//  vaavudDynamicsController.h
//  VaavudCore
//
//  Created by Andreas Okholm on 5/19/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol vaavudDynamicsControllerDelegate

- (void) DynamicsIsValid: (BOOL) validity;

@end

@interface vaavudDynamicsController : NSObject

- (void) start;
- (void) stop;

@property (nonatomic) BOOL isValid;

@property (nonatomic, weak) id <vaavudDynamicsControllerDelegate> delegate;

@end
