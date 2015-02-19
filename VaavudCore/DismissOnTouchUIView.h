//
//  DismissOnTouchUIView.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 04/08/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DismissOnTouchUIViewDelegate <NSObject>
- (void)dismissOverlayView;
@end

@interface DismissOnTouchUIView : UIView
@property (nonatomic, weak) id<DismissOnTouchUIViewDelegate> delegate;
@end
