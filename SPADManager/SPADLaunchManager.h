//
//  SPADLaunchManager.h
//  SPADManager
//
//  Created by WangJie on 2017/12/10.
//  Copyright © 2017年 SnoopPanda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SPADLaunchManager : NSObject

// 倒计时最大值，默认3s
@property (nonatomic, assign) NSUInteger maxCount;
// 从后台回到前台，显示广告的间隔，默认60s
@property (nonatomic, assign) CFTimeInterval showAdInterval;

+ (instancetype)sharedInstance;


@end
