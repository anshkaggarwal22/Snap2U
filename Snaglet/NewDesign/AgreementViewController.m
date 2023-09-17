//
//  AgreementViewController.m
//  Snaglet
//
//  Created by anshaggarwal on 4/30/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "AgreementViewController.h"

@interface AgreementViewController () <WKNavigationDelegate>

@property (nonatomic, strong) NSString *agreementFile;

@end

@implementation AgreementViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil title:(NSString *)title agreementFile:(NSString *)agreementFile {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navigationItem.title = title;
        self.agreementFile = agreementFile;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSURL *targetURL = [NSURL fileURLWithPath:self.agreementFile];
    NSURLRequest *request = [NSURLRequest requestWithURL:targetURL];
    [self.webView loadRequest:request];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(agreementReviewDone:)];
    
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[SnagletAnalytics sharedSnagletAnalytics] logScreenView:NSStringFromClass(self.class)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)agreementReviewDone:(id)sender
{
    [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"Agreement Review Done"];

    [self dismissViewControllerAnimated:YES completion:nil];
};

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    if (@available(iOS 8.0, *)) {
        [self clearBackground];
    }
}

- (void)clearBackground
{
    UIView *v = self.webView;
    while (v)
    {
        v.backgroundColor = [UIColor whiteColor];
        v = [v.subviews firstObject];
        
        if ([NSStringFromClass([v class]) isEqualToString:@"WKPDFPageView"]) {
            [v setBackgroundColor:[UIColor whiteColor]];
            
            // background set to white so fade view in and exit
            [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 self.webView.alpha = 1.0;
                             }
                             completion:nil];
            return;
        }
    }
}

@end
