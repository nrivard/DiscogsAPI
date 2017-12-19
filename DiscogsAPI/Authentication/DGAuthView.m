 // DGAuthView.m
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

#import "DGAuthView.h"
#import "AFOAuth1Client.h"

@import WebKit;

extern NSString * const DGCallback;

@interface DGAuthView () <WKNavigationDelegate>
@property (nonatomic, strong) WKWebView *webView;
@end

@implementation DGAuthView

+ (DGAuthView *)viewWithRequest:(NSURLRequest *)request {
    return [[DGAuthView alloc] initWithRequest:request];
}

- (instancetype)initWithRequest:(NSURLRequest *)request {
    if (self = [super init]) {
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero];
        
        [self addSubview:_webView];
        _webView.translatesAutoresizingMaskIntoConstraints = NO;
        [_webView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
        [_webView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
        [_webView.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
        [_webView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
        
        _webView.navigationDelegate = self;
        
        [self loadRequest:request];
    }
    return self;
}

- (void)loadRequest:(NSURLRequest *)request {
    if (@available(iOS 11.0, *)) {
        WKHTTPCookieStore *cookieStorage = self.webView.configuration.websiteDataStore.httpCookieStore;
        
        // Delete previous cookies, especially important for a logout
        [cookieStorage getAllCookies:^(NSArray<NSHTTPCookie *> * _Nonnull cookies) {
            for (NSHTTPCookie *cookie in cookies) {
                [cookieStorage deleteCookie:cookie completionHandler:nil];
            }
        }];
    } else {
        NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        
        // Delete previous cookies, especially important for a logout
        NSArray<NSHTTPCookie *> *cookies = [cookieStorage cookiesForURL:[request URL]];
        for (NSHTTPCookie *cookie in cookies) {
            [cookieStorage deleteCookie:cookie];
        }
        
        cookieStorage.cookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;
    }
    
    // Enable cookies
    NSMutableURLRequest *mutableRequest = request.mutableCopy;
    mutableRequest.HTTPShouldHandleCookies = YES;
    
    [self.webView loadRequest:mutableRequest];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    WKNavigationActionPolicy policy = WKNavigationActionPolicyAllow;
    
    NSURLRequest *request = navigationAction.request;
    if ([request.URL.path isEqualToString:@"/login/google"] && self.navigationDelegate) {
        policy = [self.navigationDelegate authView:self policyForGoogleLoginRequest:request];
    } else if ([request.URL.absoluteString hasPrefix:DGCallback]) {
        NSNotification *notification = [NSNotification notificationWithName:kAFApplicationLaunchedWithURLNotification object:nil userInfo:@{kAFApplicationLaunchOptionsURLKey: request.URL}];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
        policy = WKNavigationActionPolicyCancel;
    }
    
    decisionHandler(policy);
}

@end
