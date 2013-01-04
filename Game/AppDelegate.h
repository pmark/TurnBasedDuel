//
//  AppDelegate.h
//  Game
//
//  Created by P. Mark Anderson on 1/1/13.
//  Copyright (c) 2013 Bordertown Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlayerCache.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) PlayerCache *playerCache;

@end


#define APP_DELEGATE ((AppDelegate*)[UIApplication sharedApplication].delegate)