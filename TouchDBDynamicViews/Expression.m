//
//  Expression.m
//  TouchDB-iOS-Views
//
//  Created by David Gileadi on 11/24/12.
//  Copyright (c) 2012 David Gileadi. All rights reserved.
//

#import "Expression.h"

@interface LiteralExpression : Expression {
    id value;
}
@property id value;
- (LiteralExpression *) initWith:(id)value;
@end


@implementation Expression

+ (Expression *) addExpression:(Expression *)expression to:(Expression *)existing {
    
    if (!existing || !existing.acceptsChildren)
        return expression;
    else {
        [existing addChild:expression];
        return existing;
    }
}

+ (Expression *) parse:(NSString *)source {
    
    return [self parseWithScanner:[NSScanner scannerWithString:source]];
}

+ (Expression *) parseWithScanner:(NSScanner *)scanner {
    
    Expression *expression = nil;
    NSCharacterSet *quotesCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"\"'"];
    
    NSDecimal number;
    NSString *string;
    
    if ([scanner scanString:@"null" intoString:nil]) {
        [self addExpression:[[LiteralExpression alloc] initWith:nil] to:expression];
    } else if ([scanner scanString:@"true" intoString:nil]) {
        [self addExpression:[[LiteralExpression alloc] initWith:[NSNumber numberWithBool:YES]] to:expression];
    } else if ([scanner scanString:@"false" intoString:nil]) {
        [self addExpression:[[LiteralExpression alloc] initWith:[NSNumber numberWithBool:NO]] to:expression];
    } else if ([scanner scanDecimal:&number]) {
        // number literal
        [self addExpression:[[LiteralExpression alloc] initWith:[NSDecimalNumber decimalNumberWithDecimal:number]] to:expression];
    } else if ([scanner scanCharactersFromSet:quotesCharacterSet intoString:&string]) {
        // string literal
        if (string.length == 1) {
            unichar quote = [string characterAtIndex:0];
            NSString *value = @"";
            BOOL done = NO;
            do {
                done = YES;
                if ([scanner scanUpToString:[NSString stringWithCharacters:&quote length:1] intoString:&string]) {
                    if ([string characterAtIndex:string.length - 1] == '\\') {
                        value = [value stringByAppendingString:[string substringToIndex:string.length - 1]];
                        done = NO;
                    }
                    value = [value stringByAppendingString:string];
                } else {
                    NSLog(@"Invalid string literal: %@", scanner.string);
                }
            } while (!done);
            [scanner scanString:[NSString stringWithCharacters:&quote length:1] intoString:nil];
        } else if (string.length == 2) {
            [self addExpression:[[LiteralExpression alloc] initWith:@""] to:expression];
        } else {
            NSLog(@"Invalid string literal: %@", string);
        }
    } else if ([scanner scanString:@"{" intoString:nil]) {
        // object literal
// TODO
    } else if ([scanner scanString:@"[" intoString:nil]) {
        // array literal
// TODO
    } else if ([scanner scanString:@"&&" intoString:nil]) {
        // logical AND
        if (!expression)
            NSLog(@"Logical operators can't start an expression: %@", scanner.string);
// TODO
    } else if ([scanner scanString:@"||" intoString:nil]) {
        // logical OR
        if (!expression)
            NSLog(@"Logical operators can't start an expression: %@", scanner.string);
// TODO
    } else if ([scanner scanString:@"==" intoString:nil]) {
// TODO
    } else if ([scanner scanString:@"!=" intoString:nil]) {
// TODO
    } else if ([scanner scanString:@"<=" intoString:nil]) {
// TODO
    } else if ([scanner scanString:@">=" intoString:nil]) {
// TODO
    } else if ([scanner scanString:@"<" intoString:nil]) {
// TODO
    } else if ([scanner scanString:@">" intoString:nil]) {
// TODO
    } else if ([scanner scanString:@"!" intoString:nil]) {
        // negation
// TODO
    } else if ([scanner scanString:@"(" intoString:nil]) {
        // group
// TODO
    } else if ([scanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&string]) {
        // identifier(s)
// TODO
    }
    
    return expression;
}

- (BOOL) acceptsChildren {
    
    return NO;
}

- (id) evaluateAgainst:(NSDictionary *)doc {
    
    return nil;
}

- (void) addChild:(Expression *)child {
    
}

@end


@implementation LiteralExpression

@synthesize value;

- (LiteralExpression *) initWith:(id)initialValue {
    self = [super init];
    if (self)
        self.value = initialValue;
    return self;
}

- (id) evaluateAgainst:(NSDictionary *)doc {
    
    return value;
}

@end