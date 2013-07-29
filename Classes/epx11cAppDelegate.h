//
//  epx11cAppDelegate.h
//  epx11c
//
//  Created by Elvis Pfützenreuter on 8/29/11.
//  Copyright 2011 Elvis Pfützenreuter. All rights reserved.
//

#import <UIKit/UIKit.h>

@class epx11cViewController;

@interface epx11cAppDelegate : NSObject <UIApplicationDelegate>;

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) epx11cViewController *viewController;

@end

