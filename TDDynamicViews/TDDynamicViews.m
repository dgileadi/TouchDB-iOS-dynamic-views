//
//  TD_DynamicViewCompiler.m
//  TouchDB-iOS-Views
//
//  Created by David Gileadi on 11/22/12.
//  Copyright (c) 2012 David Gileadi. All rights reserved.
//

#import "TDDynamicViews.h"
#import "TDRouter+EmitHandler.h"
#import "Expression.h"
#import <Foundation/NSJSONSerialization.h>


NSString *kJQueryViewObjectString =
@"(function(doc) {"
"  var emit = function(key, value) {"
"    $.ajax({type: 'POST', url: 'http://.touchdb./_emit?uuid=%@', data: JSON.stringify({key: key, value: value})})"
"  };"
"  var v = %@;"
"  v(doc);"
"})(%@)";

NSString *kXHRViewObjectString =
@"(function(doc) {"
"  var emit = function(key, value) {"
"    var xhr = new XMLHttpRequest();"
"    xhr.open('POST', 'http://.touchdb./_emit?uuid=%@');"
"    xhr.send(JSON.stringify({key: key, value: value}));"
"  };"
"  var v = %@;"
"  v(doc);"
"})(%@)";


@interface NSMutableDictionary (SharedInstance)
+ (NSMutableDictionary *) sharedInstance;
@end

@implementation NSMutableDictionary (SharedInstance)
+ (NSMutableDictionary *)sharedInstance {
    static NSMutableDictionary *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[NSMutableDictionary alloc] init];
    });
    return sharedInstance;
}
@end


@implementation TDDynamicViews

@synthesize webView;
@synthesize useJQuery;

- (id) initWithWebView:(UIWebView *)view {
    
    self = [super init];
    if (self)
        self.webView = view;
    return self;
}

+ (TDStatus) emitKey:(id)key andValue:(id)value forUUID:(NSString *)uuid {
    
    NSMutableDictionary *dict = [NSMutableDictionary sharedInstance];
    TDMapEmitBlock emit = [dict objectForKey:uuid];
    if (!emit)
        return kTDStatusCallbackError;
    
    emit(key, value);
    
    NSString *semaphoreKey = [uuid stringByAppendingString:@"semaphore"];
    dispatch_semaphore_t semaphore = [dict objectForKey:semaphoreKey];
    dispatch_semaphore_signal(semaphore);
    
    // remove the emit block and semaphore
    [dict removeObjectForKey:uuid];
    [dict removeObjectForKey:semaphoreKey];
    
    return kTDStatusOK;
}

- (TDMapBlock) compileJavascriptMapFunction:(NSString*)mapSource {
    
    if (webView != nil) {
        return ^(NSDictionary* doc, TDMapEmitBlock emit) {
            // register the emit block under a new UUID
            CFUUIDRef uuidRef = CFUUIDCreate(NULL);
            NSString *uuid = (NSString *) CFBridgingRelease(CFUUIDCreateString(NULL, uuidRef));
            CFRelease(uuidRef);
            [[NSMutableDictionary sharedInstance] setValue:emit forKey:uuid];
            
            NSData *data = [NSJSONSerialization dataWithJSONObject:doc options:0 error:nil];
            NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            // create the javascript string with a custom emit function
            NSString *javascript;
            if (useJQuery)
                javascript = [NSString stringWithFormat:kJQueryViewObjectString, uuid, mapSource, json];
            else
                javascript = [NSString stringWithFormat:kXHRViewObjectString, uuid, mapSource, json];
            
            // prepare to wait
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            [[NSMutableDictionary sharedInstance] setValue:semaphore forKey:[uuid stringByAppendingString:@"semaphore"]];
            
            // have our web view run the javascript for us
            [webView performSelectorOnMainThread:@selector(stringByEvaluatingJavaScriptFromString:) withObject:javascript waitUntilDone:YES];
            
            // wait for the emit block to be called
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);//dispatch_time(DISPATCH_TIME_NOW, 1000 * 1000));
//            dispatch_release(semaphore);
            NSLog(@"After semaphore");
        };
    }
    return nil;
}

- (TDMapBlock) compilePropertyMapFunction:(NSString *)mapSource {
    
    Expression *test = nil;
    NSMutableArray *emits = [NSMutableArray array];
    
    NSScanner *scanner = [NSScanner scannerWithString:mapSource];
    NSMutableCharacterSet *skip = [NSMutableCharacterSet characterSetWithCharactersInString:@";"];
    [skip formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    scanner.charactersToBeSkipped = skip;
    scanner.caseSensitive = YES;
    
    while (![scanner isAtEnd]) {
        if ([scanner scanString:@"if" intoString:NULL]) {
            NSString *expressionString;
            [scanner scanUpToString:@"emit" intoString:&expressionString];
            test = [Expression parse:expressionString];
        } else if ([scanner scanString:@"emit" intoString:NULL]) {
            [scanner scanString:@"(" intoString:NULL];
            NSString *keyString, *valueString;
            [scanner scanUpToString:@"," intoString:&keyString];
            [scanner scanUpToString:@"emit" intoString:&valueString];
            
            // remove the last paren
            NSRange range = [valueString rangeOfString:@")" options:NSBackwardsSearch];
            valueString = [valueString substringToIndex:range.location];
            
            [emits addObject:[Expression parse:keyString]];
            [emits addObject:[Expression parse:valueString]];
        } else {
            NSLog(@"Expected 'if' or 'emit' but found something else in %@", [scanner string]);
            return nil;
        }
    }
    
    if ((emits.count % 2) != 0) {
        NSLog(@"Emits should be in pairs (key, value) but there were %d", emits.count);
        return nil;
    }
    
    return ^(NSDictionary *doc, TDMapEmitBlock emit) {
        if ([test evaluateAgainst:doc])
            for (int i = 0; i < emits.count; i += 2)
                emit([[emits objectAtIndex:i] evaluateAgainst:doc], [[emits objectAtIndex:i + 1] evaluateAgainst:doc]);
    };
    /*
     if(doc.that == true && (doc.something || doc.other))
     emit([doc.tags[0], doc.something, 'hello'], null)
     emit: null: doc.name
     */
}

- (TDMapBlock) compileMapFunction:(NSString*)mapSource language:(NSString*)language {
    
    TDMapBlock mapBlock = nil;
    
    if ([@"javascript" isEqualToString:[language lowercaseString]])
        mapBlock = [self compileJavascriptMapFunction:mapSource];
    else if ([@"properties" isEqualToString:[language lowercaseString]])
        mapBlock = [self compilePropertyMapFunction:mapSource];

    return [mapBlock copy];
}

- (TDReduceBlock) compileReduceFunction: (NSString*)reduceSource language: (NSString*)language {
    
    TDReduceBlock reduceBlock = nil;
    // TODO: create it
    
    return [reduceBlock copy];
}

@end
