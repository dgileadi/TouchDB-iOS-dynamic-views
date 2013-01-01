//
//  TDRouter+EmitHandler.m
//  TouchDB-iOS-Views
//
//  Created by David Gileadi on 11/28/12.
//  Copyright (c) 2012 David Gileadi. All rights reserved.
//

#import "TDRouter+EmitHandler.h"
#import "TDDynamicViews.h"
#import <TouchDB/TD_Body.h>

@implementation TDRouter (EmitHandler)

- (TDStatus) do_POST_emit {
    
    NSString *uuid = [self query:@"uuid"];
    NSDictionary *properties = [self bodyAsDictionary];
    id key = [properties objectForKey:@"key"];
    id value = [properties objectForKey:@"value"];
    return [TDDynamicViews emitKey:key andValue:value forUUID:uuid];
}

@end
