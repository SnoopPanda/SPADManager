//
//  SPADLaunchController.m
//  SPADManager
//
//  Created by WangJie on 2017/12/10.
//  Copyright © 2017年 SnoopPanda. All rights reserved.
//

#import "SPADLaunchController.h"
#import <WebKit/WebKit.h>

@interface SPADLaunchController ()
@property (nonatomic, strong) WKWebView *webView;
@end

@implementation SPADLaunchController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    NSURL *url = [NSURL URLWithString:self.adUrlString];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    [self.view addSubview:self.webView];
}

@end
