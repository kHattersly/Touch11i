//
//  epx11cViewController.m
//  epx11c
//
//  Created by Elvis Pfützenreuter on 8/29/11.
//  Copyright 2011 Elvis Pfützenreuter. All rights reserved.
//

#import "epx11cViewController.h"

@implementation epx11cViewController

@synthesize view_p, view_l;

// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void) playClick
{
    AudioServicesPlaySystemSound(audio_id);
}

- (void) playClickOff
{
    AudioServicesPlaySystemSound(audio2_id);
}

- (BOOL) getSB: (BOOL) is_vertical {
	BOOL hide_bar = is_vertical;
	if (iphone5) {
		// iPhone5 proportions ask the opposite logic
		hide_bar = !hide_bar;
	}
    return hide_bar;
};

- (void)loadView { 
    [super loadView];
    {
    NSURL *aurl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"click" ofType:@"wav"] isDirectory:NO];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef) aurl, &audio_id);
    }
    {
    NSURL *aurl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"clickoff" ofType:@"wav"] isDirectory:NO];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef) aurl, &audio2_id);
    }
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs registerDefaults:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [NSNumber numberWithInt: 1], @"click", nil]];
    [prefs registerDefaults:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [NSNumber numberWithInt: 0], @"comma", nil]];
    click = [prefs integerForKey: @"click"];
    comma = [prefs integerForKey: @"comma"];
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
       lock = [prefs integerForKey: @"lock"];
    }
}

- (void)defaultsChanged:(NSNotification *)notification {
    // Get the user defaults
    NSLog(@"Defaults changed");
    NSUserDefaults *prefs = (NSUserDefaults *)[notification object];
    click = [prefs integerForKey: @"click"];
    comma = [prefs integerForKey: @"comma"];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self performSelectorOnMainThread: @selector(setComma) withObject: nil waitUntilDone: NO];
        return;
    }

    int new_lock = [prefs integerForKey: @"lock"];
    if (lock != new_lock) {
        lock = new_lock;
        NSLog(@"Forcing rotation");
        if (lock == 1 || lock == 2) {
            [[UIApplication sharedApplication] setStatusBarHidden: [self getSB: (lock == 2)]];
        } else if UIDeviceOrientationIsPortrait(self.interfaceOrientation) {
            [[UIApplication sharedApplication] setStatusBarHidden: [self getSB: YES]];
        } else if UIDeviceOrientationIsLandscape(self.interfaceOrientation) {
            [[UIApplication sharedApplication] setStatusBarHidden: [self getSB: NO]];
        }
        old_layout = layout;
        layout = 0; // force loadPage
        UIViewController *c = [[UIViewController alloc]init];
        [self presentModalViewController:c animated:NO];
        [self dismissModalViewControllerAnimated:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:UIDeviceOrientationDidChangeNotification object:nil];
        NSLog(@"Forcing rotation done");
    } else {
        [self performSelectorOnMainThread: @selector(setComma) withObject: nil waitUntilDone: NO];
    }
}

- (void) setComma {
    if (comma) {
        [html stringByEvaluatingJavaScriptFromString:@"ios_comma_on();"];
    } else {
        [html stringByEvaluatingJavaScriptFromString:@"ios_comma_off();"];        
    }
}

- (void) loadPage
{
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        [[UIApplication sharedApplication] setStatusBarHidden: [self getSB: (layout == 2)]];
    }
    NSString *name = @"index_ipad";
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        name = (layout == 2) ? @"indexv" : @"index";
	if (iphone5) {
        	name = (layout == 2) ? @"index5v" : @"index5";
	}
    }
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle]
                       pathForResource:name ofType:@"html"] isDirectory:NO];
    [html loadRequest:[NSURLRequest requestWithURL:url]];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [html setBackgroundColor: [UIColor colorWithRed:55.0/255.0 green:52.0/255.0 blue:53.0/255.0 alpha:1.0]];
    self.view.backgroundColor = [UIColor colorWithRed:96.0/255.0 green:144.0/255.0 blue:96.0/255.0 alpha:1.0];
    splash_fadedout = NO;

    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        layout = UIDeviceOrientationIsPortrait(self.interfaceOrientation) ? 2 : 1;
        if (lock == 1) {
            layout = 1;
        } else if (lock == 2) {
            layout = 2;
        }
    } else {
        layout = 1;
        [self orientationChangediPad: self.interfaceOrientation];
    }
    old_layout = layout;

    NSLog(@"Screen size: %f", [UIScreen mainScreen].bounds.size.height);
    iphone5 = [UIScreen mainScreen].bounds.size.height == 568;

    [self loadPage];

    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver: self
                    selector: @selector(orientationChanged:)
                    name: @"UIDeviceOrientationDidChangeNotification"
                    object: nil];
}

- (void) orientationChanged: (NSNotification *) object
{
    // orientation event generation
    
    UIDeviceOrientation o = [[object object] orientation];

    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        [self orientationChangedPhone: o];
        return;
    }
    
    [self orientationChangediPad: o];
}

- (void) orientationChangediPad: (UIDeviceOrientation) o
{
    if (o == UIDeviceOrientationPortrait ||
        o == UIDeviceOrientationPortraitUpsideDown) {
        
        if (self.view != view_p) {
            self.view = view_p;
            [html removeFromSuperview];
            [self.view addSubview: html];
            [html setBounds: CGRectMake(0, 0, 768, 1004)];
        }
    } else if (o == UIDeviceOrientationLandscapeLeft ||
               o == UIDeviceOrientationLandscapeRight) {
        if (self.view != view_l) {
            self.view = view_l;
            [html removeFromSuperview];
            [self.view addSubview: html];
            [html setBounds: CGRectMake(0, 0, 1024, 748)];
        }
    } else {
    }
}

- (void) orientationChangedPhone: (UIDeviceOrientation) o
{
    int new_layout = 1;

    if (lock == 1) {
        new_layout = 1;
    } else if (lock == 2) {
        new_layout = 2;
    } else if (o == UIDeviceOrientationLandscapeLeft || o == UIDeviceOrientationLandscapeRight) {
        new_layout = 1;
    } else if (o == UIDeviceOrientationPortrait || o == UIDeviceOrientationPortraitUpsideDown) {
        new_layout = 2;
    } else {
        // unlocked, orientation could be "unknown" or "face down", leave the way it was
        new_layout = layout;
    }
    
    // FIXME layout and new_layout == 0
     
    /* [html release]; */
    NSLog(@"Orientation: %d, layout %d -> %d", o, layout, new_layout);
    if (layout != new_layout) {
        layout = new_layout;
        NSLog(@"    reloading");
        [self loadPage];
    }
}
 
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self setComma];

    if (splash_fadedout)
        return;

    splash_fadedout = YES;

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [UIView animateWithDuration:0.5
                              delay:0.1
                            options: 0
                         animations:^{
                             [html setAlpha: 1.00];
                         } 
                         completion:^(BOOL finished){
                             // [splash2_l removeFromSuperview];
                             // [splash2_p removeFromSuperview];
                         }];
    } else {
        [UIView animateWithDuration:0.7
                              delay:0.7
                            options: 0
                         animations:^{
                             [html setAlpha: 1.00];
                         } 
                         completion:^(BOOL finished){
                             // [splash2_l removeFromSuperview];
                         }];
    }
        
    if (click)
        [self playClick];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(defaultsChanged:)  
                   name:NSUserDefaultsDidChangeNotification
                 object:nil];
}

- (BOOL) webView:(UIWebView *)view 
shouldStartLoadWithRequest:(NSURLRequest *)request 
  navigationType:(UIWebViewNavigationType)navigationType {
    
	NSString *requestString = [[request URL] absoluteString];
	NSArray *components = [requestString componentsSeparatedByString:@":"];
    
	if ([(NSString *)[components objectAtIndex:0] isEqualToString:@"epx11c"] &&
                    [components count] > 1) {
		if ([(NSString *)[components objectAtIndex:1] isEqualToString:@"click"]) {
            if (click)
                [self playClick];
		} else if ([(NSString *)[components objectAtIndex:1] isEqualToString:@"tclick"]) {
            click = (click ? 0 : 1);
            NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
            [prefs setInteger: click forKey: @"click"];
            if (click)
                [self playClick];
            else 
                [self playClickOff];
		} else if ([(NSString *)[components objectAtIndex:1] isEqualToString:@"commaon"]) {
            comma = 1;
            NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
            [prefs setInteger: comma forKey: @"comma"];
            if (click)
                [self playClick];
		} else if ([(NSString *)[components objectAtIndex:1] isEqualToString:@"commaoff"]) {
            comma = 0;
            NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
            [prefs setInteger: comma forKey: @"comma"];
            if (click)
                [self playClick];
        }
		return NO;
	}

	return YES;
}


// Override to allow orientations other than the default portrait orientation.
// IOS5
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        if (lock == 1) {
            return ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft) ||
                    (interfaceOrientation == UIInterfaceOrientationLandscapeRight));
        } else if (lock == 2) {
            return ((interfaceOrientation == UIInterfaceOrientationPortrait) ||
                    (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown));
        }
        return YES;
    }

}

- (BOOL)shouldAutorotate
{
    return YES;
}


-(NSUInteger)supportedInterfaceOrientations
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    }
    if (lock == 1) {
        return UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskLandscapeLeft;
    } else if (lock == 2) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    return UIInterfaceOrientationMaskAll;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
}

@end
