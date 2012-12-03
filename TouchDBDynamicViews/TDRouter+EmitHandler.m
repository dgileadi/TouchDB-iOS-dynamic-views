//
//  TDRouter+EmitHandler.m
//  TouchDB-iOS-Views
//
//  Created by David Gileadi on 11/28/12.
//  Copyright (c) 2012 David Gileadi. All rights reserved.
//

#import "TDRouter+EmitHandler.h"
#import "TD_DynamicViewCompiler.h"
#import "TouchDB/TDBody.h"

@implementation TDRouter (EmitHandler)

- (TDStatus) do_POST_emit {
    
    NSString *uuid = [self query:@"uuid"];
    return [self readDocumentBodyThen: ^TDStatus(TDBody *body) {
        
        id key = [body objectForKeyedSubscript:@"key"];
        id value = [body objectForKeyedSubscript:@"value"];
        return [TD_DynamicViews emitKey:key andValue:value forUUID:uuid];
    }];
}

@end
