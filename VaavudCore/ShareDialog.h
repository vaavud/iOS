//
//  ShareDialog.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 30/06/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>

#define SHARE_DIALOG_WIDTH 300.0
#define SHARE_DIALOG_HEIGHT_NO_PICTURES 238.0
#define SHARE_DIALOG_HEIGHT_WITH_PICTURES 280.0

@protocol ShareDialogDelegate <NSObject>

- (void) shareSuccessful:(BOOL)hasMessage numberOfPhotos:(NSInteger)numberOfPhotos;
- (void) shareFailure;
- (void) shareCancelled;
- (void) presentViewControllerFromShareDialog:(UIViewController*)viewController;
- (void) dismissViewControllerFromShareDialog;
- (void) startShareActivityIndicator;
- (NSNumber*) shareAvgSpeed;
- (NSNumber*) shareMaxSpeed;
- (NSNumber*) shareLatitude;
- (NSNumber*) shareLongitude;

@end

@interface ShareDialog : UIView<UINavigationControllerDelegate,UIImagePickerControllerDelegate,UIActionSheetDelegate,UICollectionViewDataSource,UITextViewDelegate>

@property (nonatomic, weak) id<ShareDialogDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *okButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic,strong) NSMutableArray *imageUrls;
@property (weak, nonatomic) IBOutlet UIButton *pictureButton;
@property (weak, nonatomic) IBOutlet UILabel *guideLabel;

@end
