#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "TMCache.h"

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
#import "UIImageView+TMCache.h"

@interface TMImageCache : NSObject
- (UIImage *)cachedImageForRequest:(NSURLRequest *)request;
- (void)cacheImage:(UIImage *)image forRequest:(NSURLRequest *)request;
@end

#pragma mark -

static char kTMImageRequestOperationObjectKey;

@interface UIImageView (_TMNetworking)
@property (readwrite, nonatomic, strong, setter = tm_setImageRequestOperation:) AFImageRequestOperation *tm_imageRequestOperation;
@end

@implementation UIImageView (_TMNetworking)
@dynamic tm_imageRequestOperation;
@end

#pragma mark -

@implementation UIImageView (TMCache)

- (AFHTTPRequestOperation *)tm_imageRequestOperation {
    return (AFHTTPRequestOperation *)objc_getAssociatedObject(self, &kTMImageRequestOperationObjectKey);
}

- (void)tm_setImageRequestOperation:(AFImageRequestOperation *)imageRequestOperation {
    objc_setAssociatedObject(self, &kTMImageRequestOperationObjectKey, imageRequestOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSOperationQueue *)tm_sharedImageRequestOperationQueue {
    static NSOperationQueue *_tm_imageRequestOperationQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _tm_imageRequestOperationQueue = [[NSOperationQueue alloc] init];
        [_tm_imageRequestOperationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
    });
    
    return _tm_imageRequestOperationQueue;
}

+ (TMImageCache *)tm_sharedImageCache {
    static TMImageCache *_tm_imageCache = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _tm_imageCache = [[TMImageCache alloc] init];
    });
    
    return _tm_imageCache;
}

#pragma mark -

- (void)setCachedImageWithURL:(NSURL *)url
             placeholderImage:(UIImage *)placeholderImage
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    
    [self setCachedImageWithURLRequest:request placeholderImage:placeholderImage success:nil failure:nil];
}

- (void)setCachedImageWithURLRequest:(NSURLRequest *)urlRequest
                    placeholderImage:(UIImage *)placeholderImage
                             success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                             failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    [self cancelCachedImageRequestOperation];
    
    UIImage *cachedImage = [[[self class] tm_sharedImageCache] cachedImageForRequest:urlRequest];
    if (cachedImage) {
        if (success) {
            success(nil, nil, cachedImage);
        } else {
            self.image = cachedImage;
        }
        
        self.tm_imageRequestOperation = nil;
    } else {
        self.image = placeholderImage;
        
        AFImageRequestOperation *requestOperation = [[AFImageRequestOperation alloc] initWithRequest:urlRequest];
        [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([urlRequest isEqual:[self.tm_imageRequestOperation request]]) {
                if (success) {
                    success(operation.request, operation.response, responseObject);
                } else if (responseObject) {
                    self.image = responseObject;
                }
                
                if (self.tm_imageRequestOperation == operation) {
                    self.tm_imageRequestOperation = nil;
                }
            }
            
            [[[self class] tm_sharedImageCache] cacheImage:responseObject forRequest:urlRequest];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if ([urlRequest isEqual:[self.tm_imageRequestOperation request]]) {
                if (failure) {
                    failure(operation.request, operation.response, error);
                }
                
                if (self.tm_imageRequestOperation == operation) {
                    self.tm_imageRequestOperation = nil;
                }
            }
        }];
        
        self.tm_imageRequestOperation = requestOperation;
        
        [[[self class] tm_sharedImageRequestOperationQueue] addOperation:self.tm_imageRequestOperation];
    }
}

- (void)cancelCachedImageRequestOperation {
    [self.tm_imageRequestOperation cancel];
    self.tm_imageRequestOperation = nil;
}

@end

#pragma mark -

static inline NSString * TMImageCacheKeyFromURLRequest(NSURLRequest *request) {
    return [[request URL] absoluteString];
}

@implementation TMImageCache

- (UIImage *)cachedImageForRequest:(NSURLRequest *)request {
    switch ([request cachePolicy]) {
        case NSURLRequestReloadIgnoringCacheData:
        case NSURLRequestReloadIgnoringLocalAndRemoteCacheData:
            return nil;
        default:
            break;
    }
    TMCache *cache = [TMCache sharedCache];
    return [cache objectForKey:TMImageCacheKeyFromURLRequest(request)];
}

- (void)cacheImage:(UIImage *)image forRequest:(NSURLRequest *)request {
    if (image && request) {
        TMCache *cache = [TMCache sharedCache];
        [cache setObject:image forKey:TMImageCacheKeyFromURLRequest(request)];
    }
}

@end

#endif
