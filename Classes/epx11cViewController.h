//
//  epx11cViewController.h
//  epx11c
//
//  Created by Elvis Pfützenreuter on 8/29/11.
//  Copyright 2011 Elvis Pfützenreuter. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface epx11cViewController : UIViewController <UIWebViewDelegate,UIPickerViewDataSource, UIPickerViewDelegate> {
    SystemSoundID audio_id;
    SystemSoundID audio2_id;
    IBOutlet UIWebView *html;
    NSInteger click;
    NSInteger separator;
    NSInteger fb;
    NSInteger rapid;
    NSInteger layout;
    NSInteger old_layout;
    BOOL splash_fadedout;
    NSInteger lock;
    BOOL iphone5;
    NSMutableDictionary *memories;
}

- (void) playClick;
- (BOOL) webView:(UIWebView *)view shouldStartLoadWithRequest:(NSURLRequest *)request 
  navigationType:(UIWebViewNavigationType)navigationType;

@end

