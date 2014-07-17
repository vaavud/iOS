//
//  ShareDialog.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 30/06/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "ShareDialog.h"
#import <FacebookSDK/FacebookSDK.h>

@implementation ShareDialog

- (IBAction)okButtonTapped:(id)sender {
    [self.delegate share:self.textView.text];
}

- (IBAction)cancelButtonTapped:(id)sender {
    [self.delegate cancelShare];
}

- (IBAction)pictureButtonTapped:(id)sender {
    
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
    UIImagePickerController *imagePickController = [[UIImagePickerController alloc]init];
    imagePickController.sourceType = type;
    imagePickController.delegate = self;
    imagePickController.allowsEditing = NO;
    [self.delegate presentViewControllerFromShareDialog:imagePickController];
}

//Tells the delegate that the user picked a still image or movie.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self.delegate dismissViewControllerFromShareDialog];
    
    // Get the UIImage from the image picker controller
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    //UIImage *image = [UIImage imageNamed:@"history_selected.png"];
    
    // Stage the image
    [FBRequestConnection startForUploadStagingResourceWithImage:image completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if(!error) {
            NSLog(@"[ShareDialog] Successfully staged image with staged URI: %@", [result objectForKey:@"uri"]);
            
            if (!self.imageUrls) {
                self.imageUrls = [NSMutableArray array];
            }
            [self.imageUrls addObject:[result objectForKey:@"uri"]];

        } else {
            NSLog(@"[ShareDialog] Error staging Facebook image: %@", error);
        }
    }];
}

//Tells the delegate that the user cancelled the pick operation.
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self.delegate dismissViewControllerFromShareDialog];
}

@end
