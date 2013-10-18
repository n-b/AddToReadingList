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
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidOpen)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void) appDidOpen
{
    [self findAndAddURLs];
}

- (void) findAndAddURLs
{
    // Find Urls
    NSMutableOrderedSet * foundUrls = [NSMutableOrderedSet new];
    NSMutableDictionary * urlTitles = [NSMutableDictionary new];
    
    for (NSDictionary * item in UIPasteboard.generalPasteboard.items) {
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
    
    if([addedURLs count]>1) {
        _explanationLabel.text = [NSString stringWithFormat:NSLocalizedString(@"SEVERAL_URL_ADDED_TO_READING_LIST_%@", nil),
                                  [[addedURLs valueForKey:@"absoluteString"] componentsSeparatedByString:@"\n"]];
        _iconLabel.text = @"😀";
    } else if([addedURLs count]==1){
        _explanationLabel.text = [NSString stringWithFormat:NSLocalizedString(@"ONE_URL_ADDED_TO_READING_LIST_%@", nil),
                                  [[addedURLs firstObject] absoluteString]];
        _iconLabel.text = @"😃";
    } else {
        _explanationLabel.text = NSLocalizedString(@"NO_URL_FOUND_HOW_TO_USE", nil);
        _iconLabel.text = @"😟";
    }
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
