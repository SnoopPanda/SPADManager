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
#define kAdImageName @"kAdImageName"
#define kAdUrlString @"kAdUrlString"

@interface SPADLaunchManager ()
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UIButton *skipButton;
@property (nonatomic, assign) NSUInteger countDownIndex;
@property (nonatomic, assign) CFAbsoluteTime currentTime;

@property (nonatomic, strong) UIImage *adImage;
@property (nonatomic, strong) NSString *adUrlString;

@property (nonatomic, strong) NSArray *dataArray; // 假数据

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
    adLaunchController.adUrlString = self.adUrlString;
    [[rootVC currentNavigationController] pushViewController:adLaunchController animated:YES];
}

#pragma mark - Private

- (void)checkAD {
    
    NSString *imageName = [kUserDefaults valueForKey:kAdImageName];
    NSString *filePath = [self getFilePathWithImageName:imageName];
    BOOL isExist = [self isFileExistWithFilePath:filePath];
    if (isExist) {
        self.adImage = [UIImage imageWithContentsOfFile:filePath];
        self.adUrlString = [kUserDefaults valueForKey:kAdUrlString];
        [self showAD];
    }
    
    [self fetchAD];
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

- (void)fetchAD {
    // 发起请求，返回：图片名称，图片url以及跳转url
    // 判断本地有没有该图片一样的key，如果没有下载图片并缓存，如果有什么都不做
    // 假装这里有一个请求
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 该请求返回如下参数
        BOOL success = YES;
        NSDictionary *dict = self.dataArray[arc4random()%3];
        NSString *adImageName = dict[@"adImageName"];
        NSString *adImageUrl = dict[@"adImageUrl"];
        NSString *adUrlString = dict[@"adUrlString"];
        if (success) {
            NSString *filePath = [self getFilePathWithImageName:adImageName];
            BOOL isExist = [self isFileExistWithFilePath:filePath];
            if (!isExist) {
                [self downloadAdImageWithName:adImageName imageUrl:adImageUrl adUrlString:(NSString *)adUrlString];
            }
        }
    });
}

- (void)downloadAdImageWithName:(NSString *)adImageName imageUrl:(NSString *)adImageUrl adUrlString:(NSString *)adUrlString {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:adImageUrl]];
        UIImage *image = [UIImage imageWithData:data];
        NSString *filePath = [self getFilePathWithImageName:adImageName];
        if ([UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES]) {
            [self deleteOldImage];
            [kUserDefaults setValue:adImageName forKey:kAdImageName];
            [kUserDefaults setValue:adUrlString forKey:kAdUrlString];
            [kUserDefaults synchronize];
        }
    });
}

- (void)deleteOldImage
{
    NSString *imageName = [kUserDefaults valueForKey:kAdImageName];
    if (imageName) {
        NSString *filePath = [self getFilePathWithImageName:imageName];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:filePath error:nil];
    }
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

#pragma mark -

- (NSArray *)dataArray {
    if (!_dataArray) {
        _dataArray = @[
                           @{
                               @"adImageName" : @"Panda1",
                               @"adImageUrl" : @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1513013980008&di=95ed32bfe235191f4d93c75dd506d66d&imgtype=0&src=http%3A%2F%2Fimg3.duitang.com%2Fuploads%2Fitem%2F201603%2F14%2F20160314151222_Pnm8V.jpeg",
                               @"adUrlString" : @"http://www.jianshu.com/u/986bac88c8c8"
                               },
                           @{
                               @"adImageName" : @"Panda2",
                               @"adImageUrl" : @"https://ss2.bdstatic.com/70cFvnSh_Q1YnxGkpoWK1HF6hhy/it/u=2718520504,514501898&fm=27&gp=0.jpg",
                               @"adUrlString" : @"http://www.jianshu.com/u/986bac88c8c8"
                               },
                           @{
                               @"adImageName" : @"Panda3",
                               @"adImageUrl" : @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1513610807&di=c38f560a53414eea52a0721ee45699bc&imgtype=jpg&er=1&src=http%3A%2F%2Fimg3.duitang.com%2Fuploads%2Fitem%2F201504%2F29%2F20150429095211_tsvBf.thumb.224_0.jpeg",
                               @"adUrlString" : @"http://www.jianshu.com/u/986bac88c8c8"
                               }
                           ];
    }
    return _dataArray;
}

@end
