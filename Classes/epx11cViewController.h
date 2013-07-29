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

@interface epx11cViewController : UIViewController <UIWebViewDelegate> {
    SystemSoundID audio_id;
    SystemSoundID audio2_id;
    IBOutlet UIView *view_p;
    IBOutlet UIView *view_l;
    IBOutlet UIWebView *html;
    int click;
    int comma;
    int layout;
    int old_layout;
    BOOL splash_fadedout;
    BOOL iphone5;
    int lock;
}

@property (nonatomic, retain) IBOutlet UIView *view_p;
@property (nonatomic, retain) IBOutlet UIView *view_l;

- (void) playClick;
- (BOOL) webView:(UIWebView *)view shouldStartLoadWithRequest:(NSURLRequest *)request 
  navigationType:(UIWebViewNavigationType)navigationType;

@end

