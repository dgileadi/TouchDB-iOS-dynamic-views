//
//  TouchDB_iOS_Dynamic_Views.h
//  TouchDB.iOS.Dynamic.Views
//
//  Created by David Gileadi on 12/3/12.
//  Copyright (c) 2012 David Gileadi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TouchDB/TD_View.h>

@interface TDDynamicViews : NSObject <TDViewCompiler> {
    UIWebView * __weak webView;
    BOOL useJQuery;
}

@property(nonatomic, weak) UIWebView *webView;
@property(nonatomic) BOOL useJQuery;

- (id) initWithWebView:(UIWebView *)webView;
+ (TDStatus) emitKey:(id)key andValue:(id)value forUUID:(NSString *)uuid;

@end
