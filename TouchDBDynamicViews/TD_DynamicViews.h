//
//  TouchDB_iOS_Dynamic_Views.h
//  TouchDB.iOS.Dynamic.Views
//
//  Created by David Gileadi on 12/3/12.
//  Copyright (c) 2012 David Gileadi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TouchDB/TouchDB.h>

@interface TD_DynamicViews : NSObject <TDViewCompiler> {
    UIWebView * __weak webView;
    BOOL useJQuery;
}

@property(nonatomic, weak) UIWebView *webView;
@property(nonatomic) BOOL useJQuery;

+ (TDStatus) emitKey:(id)key andValue:(id)value forUUID:(NSString *)uuid;

@end
