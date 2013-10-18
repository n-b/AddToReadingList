//
//  AddToReadingList.m
//  AddToReadingList
//
//  Created by Nicolas on 18/10/2013.
//  Copyright (c) 2013 Nicolas Bouilleaud. All rights reserved.
//

@import UIKit;
@import Foundation;
@import SafariServices;

#pragma mark - 

@interface ARLVC : UIViewController
@end

@implementation ARLVC
{
    IBOutlet UILabel *_explanationLabel;
    IBOutlet UILabel *_iconLabel;
    
    NSInteger _lastChangeCount;
    NSTimer * _pasteboardCheckTimer;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidOpen)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    _pasteboardCheckTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(checkPasteboard) userInfo:nil repeats:YES];
    _pasteboardCheckTimer.tolerance = 10;
    [[NSRunLoop mainRunLoop] addTimer:_pasteboardCheckTimer forMode:NSRunLoopCommonModes];
    [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        UILocalNotification * localNotif = [UILocalNotification new];
        localNotif.alertBody = NSLocalizedString(@"ADD_TO_LIST_SESSION_ENDED", nil);
        localNotif.hasAction = NO;
        [[UIApplication sharedApplication] presentLocalNotificationNow:localNotif];
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [[UIApplication sharedApplication] cancelLocalNotification:localNotif];
            exit(0);
        });
    }];
}

- (void) appDidOpen
{
    [self findAndAddURLs];
}

- (void) checkPasteboard
{
    if([UIPasteboard generalPasteboard].changeCount != _lastChangeCount) {
        [self findAndAddURLs];
    }
}

- (void) findAndAddURLs
{
    // Find Urls
    NSMutableOrderedSet * foundUrls = [NSMutableOrderedSet new];
    NSMutableDictionary * urlTitles = [NSMutableDictionary new];
    
    if (([UIPasteboard generalPasteboard].changeCount != _lastChangeCount)) {
        for (NSDictionary * item in [UIPasteboard generalPasteboard].items) {
            NSURL* url;
            for (NSString * urlType in UIPasteboardTypeListURL) {
                url = item[urlType];
                if (url) {
                    break;
                }
            }
            NSString * string;
            for (NSString * stringType in UIPasteboardTypeListString) {
                string = item[stringType];
                if (string) {
                    break;
                }
            }
            if(url) {
                [foundUrls addObject:url];
                if(string && ![string isEqualToString:[url absoluteString]]) {
                    urlTitles[url] = string;
                }
            } else if(string) {
                NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
                NSArray *matches = [linkDetector matchesInString:string options:0 range:NSMakeRange(0, string.length)];
                for (NSTextCheckingResult *match in matches) {
                    if (match.resultType == NSTextCheckingTypeLink) {
                        [foundUrls addObject:match.URL];
                    }
                }
            }
        }
    }
    
    // Add Urls to reading ling
    NSMutableOrderedSet * addedURLs = [NSMutableOrderedSet new];
    for (NSURL * url in foundUrls) {
        if([SSReadingList supportsURL:url]) {
            NSString * title = urlTitles[url];
            NSError * error;
            [SSReadingList.defaultReadingList addReadingListItemWithURL:url title:title previewText:nil error:&error];
            if (error) {
                [[[UIAlertView alloc] initWithTitle:title?title:[url absoluteString]
                                            message:[NSString stringWithFormat:@"%@%@%@\n%@",
                                                     title?[url absoluteString]:@"",
                                                     title?@"\n":@"",
                                                     [error localizedDescription],
                                                     [error localizedFailureReason]]
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            } else {
                [addedURLs addObject:url];
            }
        } else {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UNSUPPORTED_URL", nil)
                                        message:[url absoluteString]
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }
    }
    
    // Display result
    if ([addedURLs count]) {
        if([addedURLs count]>1) {
            _explanationLabel.text = [NSString stringWithFormat:NSLocalizedString(@"SEVERAL_URL_ADDED_TO_READING_LIST_%@", nil),
                                      [[addedURLs valueForKey:@"absoluteString"] componentsSeparatedByString:@"\n"]];
        } else if([addedURLs count]==1){
            _explanationLabel.text = [NSString stringWithFormat:NSLocalizedString(@"ONE_URL_ADDED_TO_READING_LIST_%@", nil),
                                      [[addedURLs firstObject] absoluteString]];
        }

        if([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
            UILocalNotification * localNotif = [UILocalNotification new];
            localNotif.alertBody = NSLocalizedString(@"ADDED_TO_READING_LIST", nil);
            localNotif.hasAction = NO;
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotif];
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [[UIApplication sharedApplication] cancelLocalNotification:localNotif];
            });
        }
        _iconLabel.text = @"😃";
    } else {
        _explanationLabel.text = NSLocalizedString(@"NO_URL_FOUND_HOW_TO_USE", nil);
        _iconLabel.text = @"😟";
    }
    
    _lastChangeCount = [UIPasteboard generalPasteboard].changeCount;
}

@end


#pragma mark -

@interface ARLAppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end
@implementation ARLAppDelegate @end
int main(int argc, char * argv[]){
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([ARLAppDelegate class]));
    }
}
