//
//  VaavudAPIHTTPClient.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 18/06/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "VaavudAPIHTTPClient.h"
#import "AFJSONRequestOperation.h"
#import "Property+Util.h"

@implementation VaavudAPIHTTPClient

+ (VaavudAPIHTTPClient *) sharedInstance {
    static VaavudAPIHTTPClient *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[VaavudAPIHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:vaavudAPIBaseURLString]];
    });
    return _sharedInstance;
}

- (id) initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
	[self setDefaultHeader:@"Accept" value:@"application/json"];
    [self setParameterEncoding:AFJSONParameterEncoding];
    
    NSString *authToken = [Property getAsString:KEY_AUTH_TOKEN];
    if (authToken && authToken != nil) {
        [self setAuthToken:authToken];
    }
    
    return self;
}

- (void) setAuthToken:(NSString *)authToken {
    [self setDefaultHeader:@"authToken" value:authToken];
}

@end
