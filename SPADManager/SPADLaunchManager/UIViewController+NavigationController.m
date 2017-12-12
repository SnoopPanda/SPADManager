//
//  UIViewController+NavigationController.m
//  SPADManager
//
//  Created by WangJie on 2017/12/10.
//  Copyright © 2017年 SnoopPanda. All rights reserved.
//

#import "UIViewController+NavigationController.h"

@implementation UIViewController (NavigationController)

- (UINavigationController*)currentNavigationController
{
    UINavigationController* nav = nil;
    if ([self isKindOfClass:[UINavigationController class]]) {
        nav = (id)self;
    }
    else {
        if ([self isKindOfClass:[UITabBarController class]]) {
            nav = [((UITabBarController*)self).selectedViewController currentNavigationController];
        }
        else {
            nav = self.navigationController;
        }
    }
    return nav;
}

@end
