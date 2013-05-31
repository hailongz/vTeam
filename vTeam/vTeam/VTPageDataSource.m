//
//  VTPageDataSource.m
//  vTeam
//
//  Created by zhang hailong on 13-5-2.
//  Copyright (c) 2013年 hailong.org. All rights reserved.
//

#import "VTPageDataSource.h"

@implementation VTPageDataSource

@synthesize pageIndex = _pageIndex;
@synthesize pageSize = _pageSize;


-(id) init{
    if((self = [super init])){
        _pageIndex = 1;
        _pageSize = 20;
    }
    return self;
}

-(NSInteger) vtDownlinkPageTaskPageIndex{
    return _pageIndex;
}

-(NSInteger) vtDownlinkPageTaskPageSize{
    return _pageSize;
}

-(void) loadMoreData{
    _pageIndex ++;
    self.loading = YES;
    if([self.delegate respondsToSelector:@selector(vtDataSourceWillLoading:)]){
        [self.delegate vtDataSourceWillLoading:self];
    }
}

-(BOOL) hasMoreData{
    return YES;
}

-(void) vtDownlinkTaskDidLoaded:(id) data forTaskType:(Protocol *) taskType{
    
    self.loading = NO;
    
    if(_pageIndex == 1){
        [[self dataObjects] removeAllObjects];
    }
    
    [self loadResultsData:data];
    
    if([self.delegate respondsToSelector:@selector(vtDataSourceDidLoaded:)]){
        [self.delegate vtDataSourceDidLoaded:self];
    }
    
    self.loaded = YES;
}


@end
