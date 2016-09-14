//
//  epx11cViewController.m
//  epx11c
//
//  Created by Elvis Pfützenreuter on 8/29/11.
//  Copyright 2011 Elvis Pfützenreuter. All rights reserved.
//


#include <SDCAlertView/SDCAlertView.h>
#import "epx11cViewController.h"

@implementation epx11cViewController {
    NSString *savemem_mem;
    UIPickerView *loadmem_picker;
    NSArray* loadmem_list;
}
  
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
        [prefs registerDefaults:
         [NSDictionary dictionaryWithObjectsAndKeys:
          [NSNumber numberWithInt: 1], @"click", nil]];
        [prefs registerDefaults:
         [NSDictionary dictionaryWithObjectsAndKeys:
          [NSNumber numberWithInt: -1], @"separator", nil]];
        [prefs registerDefaults:
         [NSDictionary dictionaryWithObjectsAndKeys:
          [NSNumber numberWithInt: 1], @"fb", nil]];
        [prefs registerDefaults:
         [NSDictionary dictionaryWithObjectsAndKeys:
          [NSNumber numberWithInt: 0], @"rapid", nil]];
        [prefs registerDefaults:
         [NSDictionary dictionaryWithObjectsAndKeys:
          [NSNumber numberWithInt: 0], @"comma", nil]];
        if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
            [prefs registerDefaults:
             [NSDictionary dictionaryWithObjectsAndKeys:
              [NSNumber numberWithInt: 0], @"lock", nil]];
        }
        [prefs registerDefaults:
          [NSDictionary dictionaryWithObjectsAndKeys:
           [[NSDictionary alloc] init], @"memories", nil]];
        click = [prefs integerForKey: @"click"];
        long old_comma = [prefs integerForKey: @"comma"];
        separator = [prefs integerForKey: @"separator"];
        if (separator < 0) {
            // upgrade or first run
            separator = old_comma ? 1 : 0;
            [prefs setInteger: separator forKey: @"separator"];
        }
        fb = [prefs integerForKey: @"fb"];
        rapid = [prefs integerForKey: @"rapid"];
        if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
            lock = [prefs integerForKey: @"lock"];
        } else {
            lock = 1;
        }
        memories = [[prefs dictionaryForKey: @"memories"] mutableCopy];
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
}

- (void)defaultsChanged:(NSNotification *)notification {
    // Get the user defaults
    NSLog(@"Defaults changed");
    NSUserDefaults *prefs = (NSUserDefaults *)[notification object];
    click = [prefs integerForKey: @"click"];
    separator = [prefs integerForKey: @"separator"];
    fb = [prefs integerForKey: @"fb"];
    rapid = [prefs integerForKey: @"rapid"];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self performSelectorOnMainThread: @selector(setPrefsJS) withObject: nil waitUntilDone: NO];
        return;
    }

    NSInteger new_lock = [prefs integerForKey: @"lock"];
    if (lock != new_lock) {
        lock = new_lock;
        NSLog(@"Forcing rotation");
        if (lock == 1 || lock == 2) {
            [[UIApplication sharedApplication] setStatusBarHidden: [self getSB: (lock == 2)]];
        } else if (UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
            [[UIApplication sharedApplication] setStatusBarHidden: [self getSB: YES]];
        } else if (UIDeviceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
            [[UIApplication sharedApplication] setStatusBarHidden: [self getSB: NO]];
        }
        if (lock == 1) {
            // only case that needs forced rotation in iOS 8
            [[UIDevice currentDevice] setValue:
             [NSNumber numberWithInteger: UIInterfaceOrientationLandscapeRight]
                                        forKey:@"orientation"];
        }
        old_layout = layout;
        layout = 0; // force loadPage
        [[NSNotificationCenter defaultCenter]
            postNotificationName:UIDeviceOrientationDidChangeNotification
            object:nil];
        NSLog(@"Forcing rotation done");
    } else {
        [self performSelectorOnMainThread: @selector(setPrefsJS) withObject: nil waitUntilDone: NO];
    }
}

- (void) setPrefsJS {
    NSString *sep_cmd = [NSString stringWithFormat: @"ios_separator(%ld);", (long) separator];
    NSString *fb_cmd = @"ios_fb_on();";
    NSString *rapid_cmd = [NSString stringWithFormat: @"ios_set_rapid(%ld);", (long) rapid];

    if (! fb) {
        fb_cmd = @"ios_fb_off();";
    }

    NSString *cmd = [NSString stringWithFormat: @"%@ %@ %@", fb_cmd, sep_cmd, rapid_cmd];
    [html stringByEvaluatingJavaScriptFromString: cmd];
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
    
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        html.scrollView.scrollEnabled = NO;
    }
    html.scrollView.bounces = NO;
    
    [html setBackgroundColor: [UIColor colorWithRed:41.0/255.0 green:39.0/255.0 blue:40.0/255.0 alpha:1.0]];
    self.view.backgroundColor = [UIColor colorWithRed:39.0/255.0 green:39.0/255.0 blue:40.0/255.0 alpha:1.0];
    splash_fadedout = NO;

    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        layout = UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? 2 : 1;
        if (lock == 1) {
            layout = 1;
        } else if (lock == 2) {
            layout = 2;
        }
    } else {
        layout = 1;
        [self orientationChangediPad: [[UIApplication sharedApplication] statusBarOrientation]];
    }
    old_layout = layout;

    NSLog(@"Screen size: %f", [UIScreen mainScreen].bounds.size.height);

    double pheight = [UIScreen mainScreen].bounds.size.height;
    if ([UIScreen mainScreen].bounds.size.width > pheight) {
        // make sure we get the portrait-wise height
        pheight = [UIScreen mainScreen].bounds.size.width;
    }

    NSLog(@"Screen size: %f", pheight);
    iphone5 = pheight >= 568;

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
    
    UIDeviceOrientation o = [UIDevice currentDevice].orientation;

    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        [self orientationChangedPhone: o];
        return;
    }
    
    [self orientationChangediPad: o];
}

- (void) orientationChangediPad: (UIDeviceOrientation) o
{
}

- (void) orientationChangedPhone: (UIDeviceOrientation) o
{
    NSInteger new_layout = 1;

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
    
    // TODO layout and new_layout == 0
     
    /* [html release]; */
    NSLog(@"Orientation: %ld, layout %ld -> %ld", ((long) o), ((long) layout), ((long) new_layout));
    if (layout != new_layout) {
        [html setAlpha:0.00];
        NSLog(@"    alpha = 0");
        [self performSelector:@selector(fade_in) withObject:nil afterDelay:0.0];
        layout = new_layout;
        NSLog(@"    reloading");
        [self loadPage];
    }
}
 
- (void) fade_in {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelay:0.0];
    [html setAlpha:1.00];
    [UIView commitAnimations];
    NSLog(@"    alpha animated (fade_in)");
}
 
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self setPrefsJS];

    if (splash_fadedout)
        return;

    splash_fadedout = YES;

    NSLog(@"    alpha animated (load)");
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options: 0
                         animations:^{
                             [html setAlpha: 1.00];
                         } 
                         completion:^(BOOL finished){
                             // [splash2_l removeFromSuperview];
                             // [splash2_p removeFromSuperview];
                         }];
    } else {
        [UIView animateWithDuration:0.5
                              delay:0.0
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
                   name: NSUserDefaultsDidChangeNotification
                 object:nil];
    
    [center addObserver: self
               selector: @selector (storeDidChange:)
                   name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                 object: [NSUbiquitousKeyValueStore defaultStore]];
    
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
}

- (BOOL) webView:(UIWebView *)view 
shouldStartLoadWithRequest:(NSURLRequest *)request 
  navigationType:(UIWebViewNavigationType)navigationType {
    
	NSString *req = [[request URL] absoluteString];
    req = [req stringByReplacingOccurrencesOfString:@"%20" withString: @" "];
	NSArray *components = [req componentsSeparatedByString:@":"];
    NSLog(@"Request %@", req);

    
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
        } else if ([(NSString *)[components objectAtIndex:1] isEqualToString:@"settings"]) {
            NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            [[UIApplication sharedApplication] openURL:url];
        } else if ([(NSString *)[components objectAtIndex:1] isEqualToString:@"fbon"]) {
            fb = 1;
            NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
            [prefs setInteger: fb forKey: @"fb"];
        } else if ([(NSString *)[components objectAtIndex:1] isEqualToString:@"fboff"]) {
            fb = 0;
            NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
            [prefs setInteger: fb forKey: @"fb"];
        } else if ([(NSString *)[components objectAtIndex:1]
                    isEqualToString:@"savemem"]) {
            NSString *mem = [req substringFromIndex: 15];
            [self savemem: mem];
        } else if ([(NSString *)[components objectAtIndex:1]
                    isEqualToString:@"loadmem"]) {
            [self loadmem];
        } else if ([(NSString *)[components objectAtIndex:1]
                    isEqualToString:@"delmem"]) {
            [self delmem];
        }
		return NO;
	}

	return YES;
}

- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    // NSLog(@"loadmem rows %ld", (long) [loadmem_list count]);
    return [loadmem_list count];
}

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    // NSLog(@"loadmem row %@", [loadmem_list objectAtIndex: row]);
    return [loadmem_list objectAtIndex: row];
}

- (void) loadmem
{
    [self showPicker: 4321 title: @"Load memory"];
}

- (void) delmem
{
    [self showPicker: 1111 title: @"Delete Memory"];
}

- (void) showPicker: (int) tag title: (NSString*) title
{
    SDCAlertView *alertView = [[SDCAlertView alloc] initWithTitle:title message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
    
    UIPickerView *picker = [[UIPickerView alloc] initWithFrame: CGRectMake(0, 0, 250, 200)];
    picker.dataSource = self;
    picker.delegate = self;
    loadmem_picker = picker;
    
    NSMutableArray *keys = [NSMutableArray array];
    
    for (NSString *key in [memories allKeys]) {
        NSString *mem = [memories objectForKey: key];
        if (! [mem isEqualToString: @"DEL"]) {
            [keys addObject: key];
        }
    }
    
    loadmem_list = [keys sortedArrayUsingComparator:
                    ^(id obj1, id obj2) {
                        NSString* s1 = obj1;
                        NSString* s2 = obj2;
                        return [s1 caseInsensitiveCompare: s2];
                    }];
    
    [alertView.contentView addSubview: picker];
    alertView.tag = tag;
    [alertView show];
}

- (void) savemem: (NSString *) mem
{
    // NSLog(@"Memory dump %@", mem);
    SDCAlertView *alertView = [[SDCAlertView alloc] initWithTitle:@"Save memory" message:@"Type memory name:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
    alertView.alertViewStyle = SDCAlertViewStylePlainTextInput;
    alertView.tag = 1234;
    savemem_mem = mem;
    [alertView show];
}

- (void)alertView:(SDCAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
    if (alertView.tag == 1234) {
        UITextField *name = [alertView textFieldAtIndex: 0];
        NSString *key = [name.text substringWithRange: NSMakeRange(0, MIN([name.text length], 50))];
        NSLog(@"memory name: %@ length %ld", key, ((long) [key length]));
        if ([key length] <= 0) {
            return;
        }
        NSString *mem = savemem_mem;
        [memories addEntriesFromDictionary:
            [NSDictionary dictionaryWithObjectsAndKeys: mem, key, nil]];
        NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
        [prefs setObject: memories forKey: @"memories"];
        NSLog(@"iCloud being added memory item");
        [[NSUbiquitousKeyValueStore defaultStore] setDictionary: memories forKey: @"memories"];
    } else if (alertView.tag == 4321) {
        NSInteger selection = [loadmem_picker selectedRowInComponent: 0];
        if (selection < 0 ||
                selection >= [loadmem_list count]) {
            return;
        }
        NSString *key = [loadmem_list objectAtIndex: selection];
        NSLog(@"load memory name: %@", key);
        if ([key length] <= 0) {
            return;
        }
        NSString *mem = [memories valueForKey: key];
        // NSLog(@"%@", [NSString stringWithFormat: @"loadmem(\"%@\");", mem]);
        [html stringByEvaluatingJavaScriptFromString:
            [NSString stringWithFormat: @"loadmem(\"%@\");", mem]];
    } else if (alertView.tag == 1111) {
        NSInteger selection = [loadmem_picker selectedRowInComponent: 0];
        if (selection < 0 ||
            selection >= [loadmem_list count]) {
            return;
        }
        NSString *key = [loadmem_list objectAtIndex: selection];
        NSLog(@"del memory name: %@", key);
        if ([key length] <= 0) {
            return;
        }

        // replace memory contents by "DEL" to signal other devices via iCloud
        [memories addEntriesFromDictionary:
         [NSDictionary dictionaryWithObjectsAndKeys: @"DEL", key, nil]];
        NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
        [prefs setObject: memories forKey: @"memories"];

        NSLog(@"iCloud being removed memory item");
        [[NSUbiquitousKeyValueStore defaultStore] setDictionary: memories forKey: @"memories"];
    }
    }
    
    loadmem_picker = nil;
    loadmem_list = nil;
    savemem_mem = nil;
}


- (void)storeDidChange :(NSNotification*) notification {
    NSLog(@"iCloud kv storage changed");
    NSDictionary* userInfo = [notification userInfo];
    NSNumber* reasonForChange = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangeReasonKey];
    NSInteger reason = -1;
    
    if (!reasonForChange) {
        NSLog(@"No reason for change");
        return;
    }
    
    reason = [reasonForChange integerValue];
    if ((reason == NSUbiquitousKeyValueStoreServerChange) ||
        (reason == NSUbiquitousKeyValueStoreInitialSyncChange)) {

        NSLog(@"iCloud sync");
        [self mergeWithCloud];
    }
}

- (void) mergeWithCloud
{
    NSLog(@"Getting iCloud memories");
    BOOL dirty = NO;
    
    NSUbiquitousKeyValueStore* store = [NSUbiquitousKeyValueStore defaultStore];
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    NSDictionary *icloud_memories = [store dictionaryForKey: @"memories"];

    if (icloud_memories) {
        NSLog(@"iCloud has memory already - merging");

        NSDictionary *old = [memories copy];
        [memories addEntriesFromDictionary: icloud_memories];
        if (! [memories isEqualToDictionary: old]) {
            NSLog(@"iCloud merge changed memories");
            [prefs setObject: memories forKey: @"memories"];
            dirty = YES;
        } else {
            NSLog(@"Merge did not change anything");
        }
    } else {
        NSLog(@"iCloud virgin");
        dirty = YES;
    }

    if (dirty) {
        NSLog(@"iCloud being updated");
        [store setDictionary: memories forKey: @"memories"];
    }
}


// Override to allow orientations other than the default portrait orientation.
// IOS5
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
        return ((interfaceOrientation == UIInterfaceOrientationPortrait) ||
                (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown));
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

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
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

- (void)dealloc {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
}

@end
