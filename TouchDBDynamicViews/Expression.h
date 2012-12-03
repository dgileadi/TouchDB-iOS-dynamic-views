//
//  Expression.h
//  TouchDB-iOS-Views
//
//  Created by David Gileadi on 11/24/12.
//  Copyright (c) 2012 David Gileadi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Expression : NSObject

+ (Expression *) parse:(NSString *)source;
+ (Expression *) parseWithScanner:(NSScanner *)scanner;
@property(readonly) BOOL acceptsChildren;
- (id) evaluateAgainst:(NSDictionary *)doc;
- (void) addChild:(Expression *)child;

@end
