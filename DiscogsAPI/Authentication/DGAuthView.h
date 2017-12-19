// DGAuthView.h
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

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@class DGAuthView;

@protocol DGAuthViewNavigationDelegate<NSObject>

/** called when a user encounters a google login.
  * return the desired WKNavigationActionPolicy to proceed or cancel
  * if you return .cancel, the delegate is agreeing to handle the google login
  */
- (WKNavigationActionPolicy)authView:(DGAuthView *)authView policyForGoogleLoginRequest:(NSURLRequest *)request;

@end

/**
 The authentication web view.
 */
@interface DGAuthView : UIView

/** readonly access to the underlying web view */
@property (nonatomic, strong, readonly) WKWebView *webView;

/** specialized navigation delegate for this authentication view */
@property (nonatomic, weak, nullable) id<DGAuthViewNavigationDelegate> navigationDelegate;

/**
 Creates and initializes a `DGAuthView` object with the specified request URL.
 
 @param request The authorization request URL.
 
 @return The newly-initialized Authorization view object.
 */
+ (DGAuthView *)viewWithRequest:(NSURLRequest *)request;

/**
 Initializes a `DGAuthView` object with the specified request URL.
 
 @param request The authorization request URL.
 
 @return The initialized Authorization view object.
 */
- (instancetype)initWithRequest:(NSURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
