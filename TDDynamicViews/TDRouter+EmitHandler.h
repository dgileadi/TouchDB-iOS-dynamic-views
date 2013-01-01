//
//  TDRouter+EmitHandler.h
//  TouchDB-iOS-Views
//
//  Created by David Gileadi on 11/28/12.
//  Copyright (c) 2012 David Gileadi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TouchDB/TDRouter.h>

@interface TDRouter (EmitHandler)

- (TDStatus) readDocumentBodyThen: (TDStatus(^)(TD_Body*))block;
- (TDStatus) do_POST_emit;

@end
