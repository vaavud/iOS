#import <Foundation/Foundation.h>
#import "AFImageRequestOperation.h"
#import <Availability.h>
#import <UIKit/UIKit.h>

@interface UIImageView (TMCache)

- (void)setCachedImageWithURL:(NSURL *)url
             placeholderImage:(UIImage *)placeholderImage;

- (void)setCachedImageWithURLRequest:(NSURLRequest *)urlRequest
                   placeholderImage:(UIImage *)placeholderImage
                            success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                            failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure;

- (void)cancelCachedImageRequestOperation;

@end
