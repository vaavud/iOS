//
//  ShareDialog.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 30/06/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "ShareDialog.h"
#import "AccountManager.h"
#import "ImageUtil.h"
#import <FacebookSDK/FacebookSDK.h>

@interface ShareDialog ()

@property (nonatomic) BOOL hasLayedOut;
@property (nonatomic) int stagingFacebookImage;
@property (nonatomic) BOOL shouldInitiateShare;
@property (nonatomic, strong) NSMutableArray *imageArray;
@property (nonatomic) int numberOfPictures;

@end

@implementation ShareDialog

- (id) initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.stagingFacebookImage = 0;
        self.numberOfPictures = 0;
        self.shouldInitiateShare = NO;
        self.hasLayedOut = NO;
    }
    return self;
}

- (void) layoutSubviews {
    
    if (!self.hasLayedOut) {
        self.hasLayedOut = YES;
        self.collectionView.dataSource = self;
        [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"ImageCell"];
        
        self.titleLabel.text = NSLocalizedString(@"SHARE_TO_FACEBOOK_TITLE", nil);
        self.guideLabel.text = NSLocalizedString(@"SHARE_GUIDE", nil);
        [self.okButton setTitle:NSLocalizedString(@"BUTTON_OK", nil) forState:UIControlStateNormal];
        [self.cancelButton setTitle:NSLocalizedString(@"BUTTON_CANCEL", nil) forState:UIControlStateNormal];
        
        self.textView.delegate = self;
    }

    [super layoutSubviews];
}

- (IBAction) okButtonTapped:(id)sender {

    self.shouldInitiateShare = YES;
    [self.delegate startShareActivityIndicator];
    
    if (self.stagingFacebookImage == 0) {
        [self shareToFacebook];
    }
}

- (IBAction) cancelButtonTapped:(id)sender {
    [self.delegate shareCancelled];
}

- (IBAction) pictureButtonTapped:(id)sender {
    
    [self.textView resignFirstResponder];

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {

        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"SHARE_TAKE_PHOTO", nil), NSLocalizedString(@"SHARE_CHOOSE_EXISTING", nil), nil];
        [actionSheet showInView:[self superview]];
    }
}

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {

    if (buttonIndex == actionSheet.firstOtherButtonIndex) {
        [self presentImagePicker:UIImagePickerControllerSourceTypeCamera];
    }
    else if (buttonIndex == actionSheet.firstOtherButtonIndex + 1) {
        [self presentImagePicker:UIImagePickerControllerSourceTypePhotoLibrary];
    }
    else {
        [self.textView becomeFirstResponder];
    }
}

- (void) presentImagePicker:(UIImagePickerControllerSourceType)type {
    UIImagePickerController *imagePickController = [[UIImagePickerController alloc] init];
    imagePickController.sourceType = type;
    imagePickController.delegate = self;
    imagePickController.allowsEditing = NO;
    [self.delegate presentViewControllerFromShareDialog:imagePickController];
}

- (void) imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info {

    [self.delegate dismissViewControllerFromShareDialog];
    
    // Get the UIImage from the image picker controller
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    //NSLog(@"[ShareDialog] Original size: %f x %f", image.size.width, image.size.height);
    
    if (image.size.width > 1024.0F || image.size.height > 1024.0F) {
        CGSize size;
        if (image.size.width >= image.size.height) {
            size = CGSizeMake(1024.0F, (image.size.height / image.size.width) * 1024.0F);
        }
        else {
            size = CGSizeMake((image.size.width / image.size.height) * 1024.0F, 1024.0F);
        }
        image = [ImageUtil resizeImage:image toSize:size];

        //NSLog(@"[ShareDialog] Resized to: %f x %f", image.size.width, image.size.height);
    }

    AccountManager *accountManager = [AccountManager sharedInstance];
    [accountManager ensureSharingPermissions:^{
        //NSLog(@"[ShareDialog] Has sharing permissions for staging image");
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        self.stagingFacebookImage++;
        self.numberOfPictures++;
        [self refreshPictureButton];
        
        // Stage the image
        [FBRequestConnection startForUploadStagingResourceWithImage:image completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            
            self.stagingFacebookImage--;
            if (self.stagingFacebookImage == 0) {
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            }

            if (!error) {
                NSLog(@"[ShareDialog] Successfully staged image with staged URI: %@", [result objectForKey:@"uri"]);
                
                if (!self.imageUrls) {
                    self.imageUrls = [NSMutableArray array];
                    self.imageArray = [NSMutableArray array];
                }
                [self.imageUrls addObject:[result objectForKey:@"uri"]];
                [self.imageArray addObject:image];
                
                if (self.collectionView.hidden) {
                    [UIView animateWithDuration:0.2 animations:^{
                        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, SHARE_DIALOG_WIDTH, SHARE_DIALOG_HEIGHT_WITH_PICTURES);
                    } completion:^(BOOL finished) {
                        self.collectionView.hidden = NO;
                        [self.collectionView reloadData];
                    }];
                }
                else {
                    [self.collectionView reloadData];
                }
            } else {
                NSLog(@"[ShareDialog] Error staging Facebook image: %@", error);
            }
            
            if (self.shouldInitiateShare && self.stagingFacebookImage <= 0) {
                [self shareToFacebook];
            }
        }];
        
    } failure:^{
        NSLog(@"[VaavudViewController] Couldn't get sharing permissions");
    }];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self.delegate dismissViewControllerFromShareDialog];
}

- (void) refreshPictureButton {
    if (self.numberOfPictures >= 3) {
        self.pictureButton.enabled = NO;
    }
    else {
        self.pictureButton.enabled = YES;
    }
}

- (void) shareToFacebook {
    
    FBOpenGraphActionParams *params = [self createActionParams];
    id<FBOpenGraphAction> action = params.action;
    
    BOOL hasMessage = NO;
    NSInteger numberOfPhotos = 0;
    
    if (self.textView.text && self.textView.text.length > 0) {
        [action setObject:self.textView.text forKey:@"message"];
        hasMessage = YES;
    }
    
    if (self.imageUrls && self.imageUrls.count > 0) {
        
        numberOfPhotos = self.imageUrls.count;
        
        int i = 0;
        for (NSString *imageUrl in self.imageUrls) {
            action[[NSString stringWithFormat:@"image[%u][url]", i]] = imageUrl;
            action[[NSString stringWithFormat:@"image[%u][user_generated]", i]] = @"true";
            i++;
        }
    }
    
    AccountManager *accountManager = [AccountManager sharedInstance];
    [accountManager ensureSharingPermissions:^{
        //NSLog(@"[ShareDialog] Has sharing permissions");
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

        [FBRequestConnection startForPostWithGraphPath:@"me/vaavudapp:measure"
                                           graphObject:action
                                     completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                         
                                         [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

                                         if (!error) {
                                             // Success, the restaurant has been liked
                                             NSLog(@"[VaavudViewController] Posted OG action, id: %@", [result objectForKey:@"id"]);
                                             [self.delegate shareSuccessful:hasMessage numberOfPhotos:numberOfPhotos];
                                         } else {
                                             NSLog(@"[VaavudViewController] Failure posting to Facebook: %@", error);
                                             [self.delegate shareFailure];
                                         }
                                     }];
        
    } failure:^{
        NSLog(@"[VaavudViewController] Couldn't get sharing permissions");
        [self.delegate shareFailure];
    }];
}

- (FBOpenGraphActionParams*) createActionParams {
    
    NSString *objectName = @"wind_speed";
    
    id<FBGraphObject> object =
    [FBGraphObject openGraphObjectForPostWithType:[@"vaavudapp:" stringByAppendingString:objectName]
                                            title:[NSString stringWithFormat:@"%.2f %@", [self.delegate shareAvgSpeed], [self.delegate shareUnit]]
                                            image:@"http://vaavud.com/FacebookOpenGraphObjectImage.png"
                                              url:@"http://www.vaavud.com"
                                      description:[NSString stringWithFormat:@"Max wind speed: %.2f %@", [self.delegate shareMaxSpeed], [self.delegate shareUnit]]];
    
    [object setObject:@"en_US" forKey:@"locale"];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject:[NSString stringWithFormat:@"%.2f", [self.delegate shareAvgSpeed]] forKey:@"speed"];
    [data setObject:[NSString stringWithFormat:@"%.2f", [self.delegate shareMaxSpeed]] forKey:@"max_speed"];
    [data setObject:[self.delegate shareUnit] forKey:@"unit"];
    
    NSNumber *currentLatitude = [self.delegate shareLatitude];
    NSNumber *currentLongitude = [self.delegate shareLongitude];
    if (currentLatitude && currentLongitude && [currentLatitude doubleValue] != 0.0 && [currentLongitude doubleValue] != 0.0) {
        [data setObject:@{@"latitude":[currentLatitude stringValue], @"longitude":[currentLongitude stringValue]} forKey:@"location"];
    }
    [object setObject:data forKey:@"data"];
    
    id<FBOpenGraphAction> action = (id<FBOpenGraphAction>)[FBGraphObject graphObject];
    [action setObject:object forKey:objectName];
    [action setObject:@"true" forKey:@"fb:explicitly_shared"];
    
    FBOpenGraphActionParams *params = [[FBOpenGraphActionParams alloc] init];
    params.action = action;
    params.actionType = @"vaavudapp:measure";
    
    return params;
}

- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView*)collectionView {
    return 1;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger count = (self.imageArray ? self.imageArray.count : 0);
    //NSLog(@"[ShareDialog] Number of items: %u", count);
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ImageCell" forIndexPath:indexPath];
    if (!cell.contentView.subviews || cell.contentView.subviews.count == 0) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, cell.contentView.frame.size.width, cell.contentView.frame.size.height)];
        [cell.contentView addSubview:imageView];
    }

    UIImage *image = self.imageArray[indexPath.item];
    UIImageView *view = cell.contentView.subviews[0];
    [view setImage:image];
    
    //NSLog(@"[ShareDialog] Cell for section %u, item %u, view size %f x %f", indexPath.section, indexPath.item, view.frame.size.width, view.frame.size.height);
    
    return cell;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)string {

    if (!textView) {
        return YES;
    }
    
    NSRange textFieldRange = NSMakeRange(0, [textView.text length]);
    if (NSEqualRanges(range, textFieldRange) && [string length] == 0) {
        if (self.guideLabel.hidden) {
            self.guideLabel.hidden = NO;
        }
    }
    else {
        if (!self.guideLabel.hidden) {
            self.guideLabel.hidden = YES;
        }
    }
    
    return YES;
}

@end
