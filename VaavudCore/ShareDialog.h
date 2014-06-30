//
//  ShareDialog.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 30/06/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol ShareDialogDelegate <NSObject>

- (void) share:(NSString*)message;
- (void) cancelShare;

@end

@interface ShareDialog : UIView

@property (nonatomic, weak) id<ShareDialogDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *okButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@end
