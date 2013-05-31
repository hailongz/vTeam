//
//  VTLayoutContainer.m
//  vTeam
//
//  Created by Zhang Hailong on 13-5-11.
//  Copyright (c) 2013年 hailong.org. All rights reserved.
//

#import "VTLayoutContainer.h"

@implementation VTLayoutContainer

@synthesize layouts = _layouts;

-(void) dealloc{
    [_layouts release];
    [super dealloc];
}

-(void) layout{
    for(id layout in _layouts){
        [layout layout];
    }
}

@end
