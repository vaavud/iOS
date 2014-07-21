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

@property (nonatomic) int stagingFacebookImage;
@property (nonatomic) BOOL shouldInitiateShare;

@end

@implementation ShareDialog

- (id) initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.stagingFacebookImage = 0;
        self.shouldInitiateShare = NO;
    }
    return self;
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

        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo", @"Choose Existing", nil];
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
    
    NSLog(@"[ShareDialog] Original size: %f x %f", image.size.width, image.size.height);
    
    if (image.size.width > 1024.0F || image.size.height > 1024.0F) {
        CGSize size;
        if (image.size.width >= image.size.height) {
            size = CGSizeMake(1024.0F, (image.size.height / image.size.width) * 1024.0F);
        }
        else {
            size = CGSizeMake((image.size.width / image.size.height) * 1024.0F, 1024.0F);
        }
        image = [ImageUtil resizeImage:image toSize:size];

        NSLog(@"[ShareDialog] Resized to: %f x %f", image.size.width, image.size.height);
    }

    AccountManager *accountManager = [AccountManager sharedInstance];
    [accountManager ensureSharingPermissions:^{
        NSLog(@"[VaavudViewController] Has sharing permissions for staging image");
        
        self.stagingFacebookImage++;
        
        // Stage the image
        [FBRequestConnection startForUploadStagingResourceWithImage:image completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            
            self.stagingFacebookImage--;

            if (!error) {
                NSLog(@"[ShareDialog] Successfully staged image with staged URI: %@", [result objectForKey:@"uri"]);
                
                if (!self.imageUrls) {
                    self.imageUrls = [NSMutableArray array];
                }
                [self.imageUrls addObject:[result objectForKey:@"uri"]];
                
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

- (void) shareToFacebook {
    
    FBOpenGraphActionParams *params = [self createActionParams];
    id<FBOpenGraphAction> action = params.action;
    
    if (self.textView.text && self.textView.text.length > 0) {
        [action setObject:self.textView.text forKey:@"message"];
    }
    
    if (self.imageUrls && self.imageUrls.count > 0) {
        
        int i = 0;
        for (NSString *imageUrl in self.imageUrls) {
            action[[NSString stringWithFormat:@"image[%u][url]", i]] = imageUrl;
            action[[NSString stringWithFormat:@"image[%u][user_generated]", i]] = @"true";
            i++;
        }
    }
    
    AccountManager *accountManager = [AccountManager sharedInstance];
    [accountManager ensureSharingPermissions:^{
        NSLog(@"[VaavudViewController] Has sharing permissions");
        
        [FBRequestConnection startForPostWithGraphPath:@"me/vaavudapp:measure"
                                           graphObject:action
                                     completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                         
                                         if (!error) {
                                             // Success, the restaurant has been liked
                                             NSLog(@"[VaavudViewController] Posted OG action, id: %@", [result objectForKey:@"id"]);
                                         } else {
                                             NSLog(@"[VaavudViewController] Failure posting to Facebook: %@", error);
                                         }
                                         
                                         [self.delegate shareSuccessful];
                                     }];
        
    } failure:^{
        NSLog(@"[VaavudViewController] Couldn't get sharing permissions");
        [self.delegate shareSuccessful];
    }];
}

- (FBOpenGraphActionParams*) createActionParams {
    
    NSString *objectName = @"wind_speed";
    
    id<FBGraphObject> object =
    [FBGraphObject openGraphObjectForPostWithType:[@"vaavudapp:" stringByAppendingString:objectName]
                                            title:[NSString stringWithFormat:@"%.2f m/s", [[self.delegate shareAvgSpeed] floatValue]]
                                            image:nil
                                              url:@"http://www.vaavud.com"
                                      description:[NSString stringWithFormat:@"Maximum wind speed %.2f m/s", [[self.delegate shareMaxSpeed] floatValue]]];
    
    [object setObject:@"en_US" forKey:@"locale"];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject:[[self.delegate shareAvgSpeed] stringValue] forKey:@"speed"];
    [data setObject:[[self.delegate shareMaxSpeed] stringValue] forKey:@"max_speed"];
    
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

@end
