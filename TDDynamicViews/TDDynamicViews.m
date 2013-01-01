//
//  TD_DynamicViewCompiler.m
//  TouchDB-iOS-Views
//
//  Created by David Gileadi on 11/22/12.
//  Copyright (c) 2012 David Gileadi. All rights reserved.
//

#import "TDDynamicViews.h"
#import "Expression.h"
#import <Foundation/NSJSONSerialization.h>
#import <TouchDB/TD_Body.h>


NSString *kMapJavascript =
@"(function(doc) {"
"  var result = '';"
"  var emit = function(key, value) {"
"    if (result.length > 0) result += ',';"
"    result += JSON.stringify({key: key, value: value});"
"  };"
"  var v = %@;"
"  v(doc);"
"  return '[' + result + ']'"
"})(%@)";

NSString *kReduceJavascript =
@"(function(keys, values, rereduce) {"
"  var result = '';"
"  var emit = function(key, value) {"
"    if (result.length > 0) result += ',';"
"    result += JSON.stringify({key: key, value: value});"
"  };"
"  var v = %@;"
"  v(doc);"
"  return '[' + result + ']'"
"})(%@)";


@implementation TDDynamicViews

@synthesize webView;

- (id) initWithWebView:(UIWebView *)view {
    
    self = [super init];
    if (self) {
        self.webView = view;
        context = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSString *) newUUID {
    
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    NSString *uuid = (NSString *) CFBridgingRelease(CFUUIDCreateString(NULL, uuidRef));
    CFRelease(uuidRef);
    return uuid;
}

- (void) callJavascriptFunctionForKey:(NSString *)key {
    
    // have our web view run the javascript for us
    NSString *javascript = [context valueForKey:key];
    NSString *result = [webView stringByEvaluatingJavaScriptFromString:javascript];
    [context setValue:result forKey:key];
}

- (TDMapBlock) compileJavascriptMapFunction:(NSString*)mapSource {
    
    if (webView != nil) {
        return ^(NSDictionary* doc, TDMapEmitBlock emit) {
            NSString *uuid = [self newUUID];
            
            // create the javascript string
            TD_Body *docJson = [TD_Body bodyWithProperties:doc];
            NSString *javascript = [NSString stringWithFormat:kMapJavascript, mapSource, docJson.asJSONString];
            [context setValue:javascript forKey:uuid];
            
            // call the map function
            [self performSelectorOnMainThread:@selector(callJavascriptFunctionForKey:) withObject:uuid waitUntilDone:YES];
            
            // parse the result and emit it
            NSString *result = [context valueForKey:uuid];
            [context removeObjectForKey:uuid];
            TD_Body *resultJson = [TD_Body bodyWithJSON:[result dataUsingEncoding:NSUTF8StringEncoding]];
            NSArray *array = resultJson.asObject;
            for (NSDictionary *dict in array) {
                id key = [dict objectForKey:@"key"];
                id value = [dict objectForKey:@"value"];
                emit(key, value);
            }
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

- (TDReduceBlock) compileJavascriptReduceFunction:(NSString*)reduceSource {
    
    if (webView != nil) {
        return (id) ^(NSArray* keys, NSArray* values, BOOL rereduce) {
            NSString *uuid = [self newUUID];
            
            // create the javascript string
            TD_Body *keysJson = [[TD_Body alloc] initWithArray:keys];
            TD_Body *valuesJson = [[TD_Body alloc] initWithArray:values];
            NSString *javascript = [NSString stringWithFormat:kReduceJavascript, reduceSource, keysJson.asJSONString, valuesJson.asJSONString, rereduce ? @"true" : @"false"];
            [context setValue:javascript forKey:uuid];
            
            // call the reduce function
            [self performSelectorOnMainThread:@selector(callJavascriptFunctionForKey:) withObject:uuid waitUntilDone:YES];
            
            // parse the result and return it
            NSString *result = [context valueForKey:uuid];
            [context removeObjectForKey:uuid];
            TD_Body *resultJson = [TD_Body bodyWithJSON:[result dataUsingEncoding:NSUTF8StringEncoding]];
            return resultJson.asObject;
        };
    }
    return nil;
}

- (TDReduceBlock) compilePropertyReduceFunction:(NSString*)reduceSource {
    
    // TODO: something
    return nil;
}

- (TDReduceBlock) compileReduceFunction: (NSString*)reduceSource language: (NSString*)language {
    
    TDReduceBlock reduceBlock = nil;
    
    if ([@"javascript" isEqualToString:[language lowercaseString]])
        reduceBlock = [self compileJavascriptReduceFunction:reduceSource];
    else if ([@"properties" isEqualToString:[language lowercaseString]])
        reduceBlock = [self compilePropertyReduceFunction:reduceSource];
    
    return [reduceBlock copy];
}

@end
