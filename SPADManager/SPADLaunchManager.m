//
//  SPADLaunchManager.m
//  SPADManager
//
//  Created by WangJie on 2017/12/10.
//  Copyright © 2017年 SnoopPanda. All rights reserved.
//

#import "SPADLaunchManager.h"
#import "SPADLaunchController.h"
#import "UIViewController+NavigationController.h"
#import "UIImageView+WebCache.h"
#import "SDImageCache.h"

#define kUserDefaults [NSUserDefaults standardUserDefaults]

@interface SPADLaunchManager ()
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UIButton *skipButton;
@property (nonatomic, assign) NSUInteger countDownIndex;
@property (nonatomic, assign) CFAbsoluteTime currentTime;
@property (nonatomic, strong) UIImage *adImage;

@end

@implementation SPADLaunchManager

+ (instancetype)sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.maxCount = 3;
        self.showAdInterval = 60;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidFinishLaunching) name:UIApplicationDidFinishLaunchingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

#pragma mark - Notification
- (void)appDidFinishLaunching {
    [self checkAD];
}

- (void)appDidEnterBackground {
    self.currentTime = CFAbsoluteTimeGetCurrent();
    [self request];
}

- (void)appWillEnterForeground {
    CFTimeInterval timeInterval = CFAbsoluteTimeGetCurrent() - self.currentTime;
    if (timeInterval <= self.showAdInterval) {
        return;
    }
    [self checkAD];
}

#pragma mark - Action
- (void)skipAD {
    [UIView animateWithDuration:0.3 animations:^{
        self.window.alpha = 0;
    } completion:^(BOOL finished) {
        [self.window.subviews.copy enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperview];
        }];
        self.window.hidden = YES;
        self.window = nil;
    }];
}

- (void)pushADController {
    [self skipAD];
    UIViewController *rootVC = [UIApplication sharedApplication].delegate.window.rootViewController;
    SPADLaunchController *adLaunchController = [[SPADLaunchController alloc] init];
    [[rootVC currentNavigationController] pushViewController:adLaunchController animated:YES];
}

#pragma mark - Private

- (void)checkAD {
    
    NSString *imageName = [kUserDefaults valueForKey:@""];
    NSString *filePath = [self getFilePathWithImageName:imageName];
    BOOL isExist = [self isFileExistWithFilePath:filePath];
    if (isExist) {
        self.adImage = [UIImage imageWithContentsOfFile:filePath];
    }
    
    
//    UIImage *image = [UIImage imageWithContentsOfFile:filePath];
    
    // 不管有没有图片都要发送请求，判断ad是否需要更新
    [self request];
    
//    UIImage *image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:self.urlString];
//    if (image) {
//        self.adImage = image;
//        [self showAD];
//    }
//
//    NSURL *imageUrl = [NSURL URLWithString:self.urlString];
//    [[SDWebImageManager sharedManager] loadImageWithURL:imageUrl options:SDWebImageLowPriority | SDWebImageRetryFailed | SDWebImageRefreshCached progress:nil completed:^(UIImage *image, NSData *data, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
//        if (image) {
//            self.adImage = image;
//        } else {
//            [[SDImageCache sharedImageCache] removeImageForKey:self.urlString withCompletion:nil];
//        }
//    }];
}

- (BOOL)isFileExistWithFilePath:(NSString *)filePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = FALSE;
    return [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
}

- (NSString *)getFilePathWithImageName:(NSString *)imageName {
    if (imageName) {
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask, YES);
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:imageName];
        
        return filePath;
    }
    
    return nil;
}

- (void)request {
    // 请求
}

- (void)showAD {
    
    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    window.rootViewController = [UIViewController new];
    window.rootViewController.view.backgroundColor = [UIColor clearColor];
    window.rootViewController.view.userInteractionEnabled = NO;
    window.windowLevel = UIWindowLevelStatusBar + 1;
    window.hidden = NO;
    window.alpha = 1;
    [self setupADView:window];
    self.window = window;
}

- (void)setupADView:(UIWindow *)window {
    
    self.countDownIndex = self.maxCount;
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:window.bounds];
    imageView.image = self.adImage;
    imageView.userInteractionEnabled = YES;
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pushADController)];
    [imageView addGestureRecognizer:tap];
    [window addSubview:imageView];
    
    UIButton *skipButton = [UIButton buttonWithType:UIButtonTypeCustom];
    skipButton.frame = CGRectMake(window.bounds.size.width - 100 - 20, 20, 80, 40);
    [skipButton addTarget:self action:@selector(skipAD) forControlEvents:UIControlEventTouchUpInside];
    [window addSubview:skipButton];
    self.skipButton = skipButton;
    [self countDown];
}

- (void)countDown {
    [self.skipButton setTitle:[NSString stringWithFormat:@"跳过：%zi", self.countDownIndex] forState:UIControlStateNormal];
    if (self.countDownIndex <= 0) {
        [self skipAD];
    }else {
        self.countDownIndex --;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self countDown];
        });
    }
}

@end
