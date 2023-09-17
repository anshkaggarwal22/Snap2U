//
//  AgreementViewController.h
//  Snaglet
//
//  Created by anshaggarwal on 4/30/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <WebKit/WebKit.h>

@interface AgreementViewController : UIViewController<WKNavigationDelegate>

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil title:(NSString*)title agreementFile:(NSString*)agreementFile;

@property (weak, nonatomic) IBOutlet WKWebView *webView;

@end
