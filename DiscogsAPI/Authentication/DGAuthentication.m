// DGAuthentication.m
//
// Copyright (c) 2017 Maxime Epain
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

#import "DGEndpoint+Private.h"
#import "DGAuthentication.h"
#import "DGHTTPClient.h"

#import "DGAuthView.h"

#import "DGTokenStore.h"
#import "DGIdentity+Private.h"
#import "DGIdentity+Keychain.h"
#import "DGIdentity+Mapping.h"

#import <SafariServices/SafariServices.h>

NSString * const DGCallback = @"discogsapi://success";

static NSString * const kDGOAuth1CredentialDiscogsAccount = @"DGOAuthCredentialDiscogsAccount";

/** we are declaring two private interfaces. one is to conform to the delegate protocol. */
@interface DGAuthentication () <DGAuthViewNavigationDelegate>
@end

/** the other is to allow for ios 11 specific functionality */
API_AVAILABLE(ios(11.0))
@interface DGAuthentication ()
@property (nonatomic, strong, nullable) SFAuthenticationSession *authSession;
@end

@implementation DGAuthentication {
    NSString *_callback;
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

- (void)configureManager:(DGObjectManager *)manager {
    
    if (DGIdentity.current) {
        manager.HTTPClient.accessToken = DGIdentity.current.accessToken;
    }

    //User Identity
    [manager.router.routeSet addRoute:[RKRoute routeWithClass:[DGIdentity class] pathPattern:@"oauth/identity" method:RKRequestMethodGET]];
}

#pragma GCC diagnostic pop

- (void)identityWithSuccess:(void (^)(DGIdentity *identity))success failure:(void (^)(NSError *error))failure {
    DGIdentity *identity = [DGIdentity new];
    
    DGOperation<DGIdentity *> *operation = [self.manager operationWithRequest:identity method:RKRequestMethodGET responseClass:[DGIdentity class]];
    [operation setCompletionBlockWithSuccess:^(DGIdentity * _Nonnull response) {
        
        response.accessToken = self.manager.HTTPClient.accessToken;
        [DGIdentity storeIdentity:response withIdentifier:kDGIdentityCurrentIdentifier];
        success(response);
        
    } failure:^(NSError * _Nullable error) {
        
        if (error.code == DGErrorCodeUnauthorized) {
            DGIdentity.current = nil;
        }
        
        if (DGIdentity.current) {
            success(DGIdentity.current);
        } else if (failure) {
            failure(error);
        }
    }];
    
    [self.manager enqueueOperation:operation];
}

- (void)authenticateWithCallback:(NSURL *)callback success:(DGAuthenticationSuccessBlock)success failure:(void (^)(NSError *error))failure {
    
    [self identityWithSuccess:success failure:^(NSError *error) {
        
        if (error.code == DGErrorCodeUnauthorized) {
            _callback = callback.absoluteString;
            
            [self.manager.HTTPClient authorizeUsingOAuthWithCallbackURL:callback success:^(AFOAuth1Token *accessToken, id responseObject) {
                [self identityWithSuccess:success failure:failure];
            } failure:failure];
            
        } else if (failure) {
            failure(error);
        }
    }];
}

- (BOOL)openURL:(NSURL *)url {

    if (_callback && [url.absoluteString hasPrefix:_callback]) {
        NSNotification *notification = [NSNotification notificationWithName:kAFApplicationLaunchedWithURLNotification object:nil userInfo:@{kAFApplicationLaunchOptionsURLKey: url}];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
        
        _callback = nil;
        return YES;
    }
    return NO;
}

- (void)logout {
    DGIdentity.current = nil;
    self.manager.HTTPClient.accessToken = nil;
}

/**
 this is used by the SFAuthenticationSession handler in cases where there was an error. There's no way to bubble this up any other way, but
 AFOAuth1Client will look for a valid key in the query params, which it won't find, and then invoke the chain of failure blocks.
 */
- (void)invokeOpenURLWithErrorConditions {
    // just invoke this with an empty "success" URL but missing the oauth_verifier, etc.
    [self openURL:[NSURL URLWithString:DGCallback]];
}

- (void)authenticateWithPreparedAuthorizationViewHandler:(void (^)(UIView *authView))authView success:(DGAuthenticationSuccessBlock)success failure:(void (^)(NSError *error))failure {
    
    [self.manager.HTTPClient setServiceProviderRequestHandler:^(NSURLRequest *request) {
        DGAuthView *view = [DGAuthView viewWithRequest:request];
        authView(view);
    } completion:nil];
    
    NSURL *callback = [NSURL URLWithString:DGCallback];
    [self authenticateWithCallback:callback success:success failure:failure];
}

- (void)authenticateWithInitiallyPreparedView:(void (^)(UIView * _Nonnull))authView success:(DGAuthenticationSuccessBlock)success failure:(DGFailureBlock)failure {
    [self.manager.HTTPClient setServiceProviderRequestHandler:^(NSURLRequest *request) {
        DGAuthView *view = [DGAuthView viewWithRequest:request];
        view.navigationDelegate = self;
        authView(view);
    } completion:nil];
    
    NSURL *callback = [NSURL URLWithString:DGCallback];
    [self authenticateWithCallback:callback success:success failure:failure];
}

- (WKNavigationActionPolicy)authView:(DGAuthView *)authView policyForGoogleLoginRequest:(NSURLRequest *)request {
    if (@available(iOS 11.0, *)) {
        __weak __typeof(self) weakSelf = self;

        self.authSession = [[SFAuthenticationSession alloc] initWithURL:request.URL callbackURLScheme:[NSURL URLWithString:DGCallback].scheme completionHandler:^(NSURL * _Nullable callbackURL, NSError * _Nullable error) {
            if (callbackURL && !error) {
                [weakSelf openURL:callbackURL];
            } else if ([error code] != SFAuthenticationErrorCanceledLogin) {
                self.lastAuthenticationError = error;
                [weakSelf invokeOpenURLWithErrorConditions];
            }
            weakSelf.authSession = nil;
        }];

        [self.authSession start];
    } else {
        [[UIApplication sharedApplication] openURL:request.URL];
    }

    // we always cancel bc we are handling this ourselves regardless
    return WKNavigationActionPolicyCancel;
}

- (void)authView:(DGAuthView *)authView didFailToLoadWithError:(NSError *)error {
    self.lastAuthenticationError = error;
    [self invokeOpenURLWithErrorConditions];
}

@end
