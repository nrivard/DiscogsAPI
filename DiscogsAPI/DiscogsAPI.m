// DiscogsAPI.m
//
// Copyright (c) 2015 Maxime Epain
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "DiscogsAPI.h"
#import "DGEndpoint+Configuration.h"

@interface DiscogsAPI ()
@property (nonatomic, strong) DGAuthentication  *authentication;
@property (nonatomic, strong) RKObjectManager   *objectManager;
@property (nonatomic, assign) BOOL isReachable;
@end

@implementation DiscogsAPI

@synthesize database    = _database;
@synthesize user        = _user;
@synthesize resource    = _resource;

+ (DiscogsAPI *) client {
    static DiscogsAPI *client = nil;
    
    if (!client) {
        client = [[DiscogsAPI alloc] init];
    }
    return client;
}

#pragma mark Public Methods

- (void) cancelAllOperations {
    [self.objectManager.operationQueue cancelAllOperations];
}

- (void) isAuthenticated:(void (^)(BOOL success))success {
    
    [self identifyUserWithSuccess:^{
        success(YES);
    } failure:^(NSError *error) {
        
        success(    error.code == NSURLErrorNotConnectedToInternet/* &&
                    self.authentication.oAuth1Client.accessToken*/);
    }];
}

#pragma mark Private Methods

- (void) setReachability:(AFNetworkReachabilityStatus) status {
    self.isReachable = status != AFNetworkReachabilityStatusNotReachable;
}

- (void) startOperation:(RKObjectRequestOperation*) requestOperation {
    //   [requestOperation start];
    [self.objectManager enqueueObjectRequestOperation:requestOperation];
}

#pragma mark Properties

- (RKObjectManager *)objectManager {
    RKObjectManager *objectManager = [RKObjectManager sharedManager];
    
    if (!objectManager) {
        
        RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);
        
        //Setup Object Manager
        objectManager = [[RKObjectManager alloc] initWithHTTPClient:self.authentication.HTTPClient];
        objectManager.requestSerializationMIMEType = RKMIMETypeJSON;
        [objectManager addResponseDescriptor:[RKErrorMessage responseDescriptor]];
        
        //Init reachability
        [objectManager.HTTPClient setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            [self setReachability:status];
        }];
        [self setReachability:objectManager.HTTPClient.networkReachabilityStatus];
        
        //Share Object Manager
        [RKObjectManager setSharedManager:objectManager];
        
        AFNetworkActivityIndicatorManager.sharedManager.enabled = YES;
    }
    return objectManager;
}

- (void)setObjectManager:(RKObjectManager *)objectManager {
    [RKObjectManager setSharedManager:objectManager];
}

- (DGAuthentication *)authentication {
    if (!_authentication) {
        _authentication = [DGAuthentication authentication];
        _authentication.delegate = self;
    }
    return _authentication;
}

- (DGDatabase *)database {
    if (!_database) {
        _database           = [DGDatabase database];
        _database.delegate  = self;
        [_database configureManager:self.objectManager];
    }
    return _database;
}

- (DGUser *)user {
    if (!_user) {
        _user           = [DGUser user];
        _user.delegate  = self;
        [_user configureManager:self.objectManager];
    }
    return _user;
}

- (DGResource *)resource {
    if (!_resource) {
        _resource           = [DGResource resource];
        _resource.delegate  = self;
    }
    return _resource;
}

#pragma <DGAuthenticationDelegate>

- (void)authentication:(DGAuthentication *)authentication didAuthorizeClient:(AFHTTPClient *)client {
    self.objectManager.HTTPClient = client;
}

#pragma mark <DGEndpointDelegate>

- (void) identifyUserWithSuccess:(void (^)())success failure:(void (^)(NSError* error))failure {
    [self.user identityWithSuccess:^(DGIdentity *identity) {
        success();
    } failure:failure];
}

- (NSOperation*)createImageRequestOperationWithUrl:(NSString*)url success:(void (^)(UIImage*image))success failure:(void (^)(NSError* error))failure {
    return [self.resource createImageRequestOperationWithUrl:url success:success failure:failure];
}

@end
