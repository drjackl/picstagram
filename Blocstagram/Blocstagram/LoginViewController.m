//
//  LoginViewController.m
//  Blocstagram
//
//  Created by Jack Li on 3/1/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import "LoginViewController.h"
#import "DataSource.h" // for getting client ID

@interface LoginViewController () <UIWebViewDelegate> // for user login

@property (nonatomic, weak) UIWebView* webView; // why weak?

@property (nonatomic) UIButton* backButton;

@end

@implementation LoginViewController

NSString* const LoginViewControllerDidGetAccessTokenNotification = @"LoginViewControllerDidGetAccessTokenNotification"; // weird didn't autocomplete for NSString or recognize till after var typed in

- (NSString*) redirectURI {
    return @"https://github.com/drjackl"; // same one when signed up client on IG
}

// create and setup web page
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self clearInstagramCookies]; // clear cookies in case
    
    // webView: 1. create 2. set self as delegate 3. add to subview 4. set property 5. set frame (in viewWillLayoutSubviews)
    UIWebView* webView = [[UIWebView alloc] init];
    webView.delegate = self;
    
    [self.view addSubview:webView];
    self.webView = webView;
    
    // add back and home button
    UIButton* backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.backButton = backButton;
    [backButton setTitle:NSLocalizedString(@"Back", @"Navigate back") forState:UIControlStateNormal];
    [backButton setEnabled:NO];
    [backButton addTarget:self.webView action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backButton];
    
    // set title for View
    self.title = NSLocalizedString(@"Login", @"Login");
    
    // webView: to get correct login, need to provide IG Client ID (in DataSource)
    NSString* urlString = [NSString stringWithFormat:@"https://instagram.com/oauth/authorize/?client_id=%@&redirect_uri=%@&response_type=token",
                           [DataSource instagramClientID],
                           [self redirectURI]];
    NSURL* url = [NSURL URLWithString:urlString];
    
    if (url) {
        NSURLRequest* request = [NSURLRequest requestWithURL:url];
        [self.webView loadRequest:request];
    }
}

- (void) viewWillLayoutSubviews {
    self.webView.frame = self.view.bounds; // takes up entire page?
    
    static const CGFloat buttonHeight = 50;
    self.webView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds),
                                    CGRectGetHeight(self.view.bounds) - buttonHeight);
    
    // put back button at bottom
    self.backButton.frame = CGRectMake(0, CGRectGetMaxY(self.webView.frame),// - buttonHeight,
                                       CGRectGetWidth(self.webView.bounds), buttonHeight);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// override NSObject
- (void) dealloc {
    // if don't clear, can have flickering effect from fast web page display and automatic cookie authentication
    [self clearInstagramCookies];
    
    self.webView.delegate = nil; // UIWebView quirk that most objects don't require
}

// prevents caching credentials in cookie jar (NSHTTPCookieStorage)
- (void) clearInstagramCookies {
    // look for and delete all IG cookies
    for (NSHTTPCookie* cookie in [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies) {
        NSRange domainRange = [cookie.domain rangeOfString:@"instagram.com"];
        if (domainRange.location != NSNotFound) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
        }
    }
}

// get access token using delegate
- (BOOL) webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString* urlString = request.URL.absoluteString;
    if ([urlString hasPrefix:[self redirectURI]]) {
        NSRange rangeOfAccessTokenParameter = [urlString rangeOfString:@"access_token="];
        NSUInteger indexOfTokenStarting = rangeOfAccessTokenParameter.location + rangeOfAccessTokenParameter.length;
        NSString* accessToken = [urlString substringFromIndex:indexOfTokenStarting];
        
        // a new, less formal way of communication
        [[NSNotificationCenter defaultCenter] postNotificationName:LoginViewControllerDidGetAccessTokenNotification object:accessToken];
        
        return NO; // stop loading once token gotten
    }
    
    return YES; // else load page
}

// listen to update back or home button enablement
- (void) webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error {
    [self updateButtonState];
}

- (void) webViewDidStartLoad:(UIWebView*)webView {
    [self updateButtonState];
}

- (void) webViewDidFinishLoad:(UIWebView*)webView {
    [self updateButtonState];
}

- (void) updateButtonState {
    self.backButton.enabled = self.webView.canGoBack;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
