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

@property (nonatomic, strong) NSString *requestUrl;
@property (nonatomic, assign) NSUInteger maxCount;
@property (nonatomic, assign) CFTimeInterval showAdInterval;

+ (instancetype)sharedInstance;


@end
