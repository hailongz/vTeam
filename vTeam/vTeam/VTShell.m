//
//  VTShell.m
//  vTeam
//
//  Created by zhang hailong on 13-4-24.
//  Copyright (c) 2013年 hailong.org. All rights reserved.
//

#import "VTShell.h"

#import <UIKit/UIKit.h>

#import <vTeam/IVTUIViewController.h>

#import <vTeam/NSURL+QueryValue.h>

extern BOOL protocol_conformsToProtocol(Protocol *proto, Protocol *other);


@interface VTServiceContainer : NSObject<IVTServiceContainer>{
    NSMutableArray * _taskTypes;
    Class _instanceClass;
}

-(id) initWithInstanceClass:(Class) instanceClass;

@end


@implementation VTServiceContainer

@synthesize instance = _instance;
@synthesize config = _config;
@synthesize context = _context;
@synthesize inherit = _inherit;

-(void) dealloc{
    [_instance release];
    [_config release];
    [_taskTypes release];
    [super dealloc];
}

-(id) initWithInstanceClass:(Class) instanceClass{
    if((self = [super init])){
        _instanceClass = instanceClass;
    }
    return self;
}

-(BOOL) hasTaskType:(Protocol *) taskType{
    for(NSValue * v in _taskTypes){
        Protocol * protocol = (Protocol *)[v pointerValue];
        if(protocol == taskType || (_inherit && protocol_conformsToProtocol(taskType,protocol))){
            return YES;
        }
    }
    return NO;
}

-(void) addTaskType:(Protocol *) taskType{
    if(_taskTypes == nil){
        _taskTypes = [[NSMutableArray alloc] initWithCapacity:4];
    }
    [_taskTypes addObject:[NSValue valueWithPointer:taskType]];
}

-(void) didReceiveMemoryWarning{
    [_instance didReceiveMemoryWarning];
}

-(id) instance{
    if(_instance == nil){
        _instance = [[_instanceClass alloc] init];
        [_instance setContext:_context];
        [_instance setConfig:_config];
    }
    return _instance;
}

@end


@interface VTShell(){
    NSMutableArray * _viewControllers;
    NSMutableArray * _serviceContainers;
    NSMutableDictionary * _focusValues;
}

@property(nonatomic,retain) id rootViewController;

@end

@implementation VTShell

@synthesize bundle = _bundle;
@synthesize config = _config;
@synthesize rootViewController = _rootViewController;
@synthesize styleSheet = _styleSheet;

-(void) dealloc{
    [_bundle release];
    [_config release];
    [_rootViewController release];
    [_viewControllers release];
    [_serviceContainers release];
    [_styleSheet release];
    [_focusValues release];
    [super dealloc];
}

-(id) initWithConfig:(id)config bundle:(NSBundle *) bundle{
    if((self = [super init])){
        _config = [config retain];
        _bundle = [bundle retain];
        
        NSArray * items = [config valueForKey:@"services"];
        
        if([items isKindOfClass:[NSArray class]]){
            
            for(id cfg in items){
                NSString * className = [cfg valueForKey:@"class"];
                if(className){
                    Class clazz = NSClassFromString(className);
                    if(clazz){
                        if([clazz conformsToProtocol:@protocol(IVTService)]){
                            id container = [self addService:clazz];
                            [container setContext:self];
                            [container setConfig:cfg];
                            [container setInherit:[[cfg valueForKey:@"inherit"] boolValue]];
                            NSArray * taskTypes = [cfg valueForKey:@"taskTypes"];
                            if([taskTypes isKindOfClass:[NSArray class]]){
                                for(NSString * taskType in taskTypes){
                                    Protocol * p  = NSProtocolFromString(taskType);
                                    if(p){
                                        [container addTaskType:p];
                                    }
                                    else{
                                        NSLog(@"Not found taskType %@",taskType);
                                    }
                                }
                            }
                        }
                        else{
                            NSLog(@"Service Class %@ not implement IVTService",className);
                        }
                    }
                    else{
                        NSLog(@"Not found Service Class %@",className);
                    }
                }
            }
            
        }
        
 
    }
    return self;
}

-(id<IVTServiceContainer>) addService:(Class) serviceClass{
    VTServiceContainer * container = [[[VTServiceContainer alloc] initWithInstanceClass:serviceClass] autorelease];
    if(_serviceContainers == nil){
        _serviceContainers = [[NSMutableArray alloc] initWithCapacity:4];
    }
    [_serviceContainers addObject:container];
    return container;
}

-(id) getViewController:(NSURL *) url basePath:(NSString *) basePath{
    NSString * alias = [url firstPathComponent:basePath];
    id cfg = [[_config valueForKey:@"ui"] valueForKey:alias];
    if(cfg){
        BOOL cached = [[cfg valueForKey:@"cached"] boolValue];
        if(cached){
            for(id viewController in _viewControllers){
                if([[viewController alias] isEqualToString:alias] && [viewController isDisplaced]){
                    [viewController setBasePath:basePath];
                    [viewController setUrl:url];
                    [viewController reloadURL];
                    return viewController;
                }
            }
        }
        
        NSString * className = [cfg valueForKey:@"class"];
        
        if(className){
            Class clazz = NSClassFromString(className);
            if([clazz conformsToProtocol:@protocol(IVTUIViewController)]){
                id viewController = nil;
                if([clazz isSubclassOfClass:[UIViewController class]]){
                    viewController = [[[clazz alloc] initWithNibName:[cfg valueForKey:@"view"] bundle:_bundle] autorelease];
                }
                else{
                    viewController = [[[clazz alloc] init] autorelease];
                }
                if(viewController){
                    
                    [viewController setContext:self];
                    [viewController setConfig:cfg];
                    [viewController setAlias:alias];
                    [viewController setBasePath:basePath];
                    [viewController setUrl:url];
                    [viewController reloadURL];
                    
                    if(cached){
                        if(_viewControllers == nil){
                            _viewControllers = [[NSMutableArray alloc] initWithCapacity:4];
                        }
                        [_viewControllers addObject:viewController];
                    }
                }
                else{
                    NSLog(@"Not Found IVTUIViewController %@",className);
                }
                
                return viewController;
            }
        }
    }
    
    return nil;
}

-(void) didReceiveMemoryWarning{
    NSInteger c = [_viewControllers count];
    for(int i=0;i<c;i++){
        id viewController = [_viewControllers objectAtIndex:i];
        if([viewController isDisplaced]){
            [_viewControllers removeObjectAtIndex:i];
            i --;
            c --;
        }
    }
    
    for(id serviceContainer in _serviceContainers){
        [serviceContainer didReceiveMemoryWarning];
    }
}

-(BOOL) handle:(Protocol *)taskType task:(id<IVTTask>)task priority:(NSInteger)priority{
    for(id container in _serviceContainers){
        if([container hasTaskType:taskType]){
            id s = [container instance];
            if([s handle:taskType task:task priority:priority]){
                return YES;
            }
        }
    }
    return NO;
}

-(BOOL) cancelHandle:(Protocol *)taskType task:(id<IVTTask>)task{
    for(id container in _serviceContainers){
        if([container hasTaskType:taskType]){
            id s = [container instance];
            if([s cancelHandle:taskType task:task]){
                return YES;
            }
        }
    }
    return NO;
}

-(BOOL) cancelHandleForSource:(id) source{
    for(id container in _serviceContainers){
        id s = [container instance];
        if([s cancelHandleForSource:source]){
            return YES;
        }
    }
    return NO;
}

-(id) focusValueForKey:(NSString *) key{
    return [_focusValues objectForKey:key];
}

-(void) setFocusValue:(id) value forKey:(NSString *) key{
    if(_focusValues== nil){
        _focusValues = [[NSMutableDictionary alloc] initWithCapacity:4];
    }
    if(value){
        [_focusValues setObject:value forKey:key];
    }
    else{
        [_focusValues removeObjectForKey:key];
    }
}

-(id) rootViewController{
    if(_rootViewController == nil){
        NSString * url = [self.config valueForKey:@"url"];
        if(url){
            self.rootViewController = [self getViewController:[NSURL URLWithString:url] basePath:@"/"];
        }
    }
    return _rootViewController;
}
@end
