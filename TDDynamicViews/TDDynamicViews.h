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
    NSMutableDictionary *context;
}

@property(nonatomic, weak) UIWebView *webView;

- (id) initWithWebView:(UIWebView *)webView;

@end
