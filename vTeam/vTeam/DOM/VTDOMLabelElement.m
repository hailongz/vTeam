//
//  VTDOMLabelElement.m
//  vTeam
//
//  Created by zhang hailong on 13-8-14.
//  Copyright (c) 2013年 hailong.org. All rights reserved.
//

#import "VTDOMLabelElement.h"

#import "VTDOMElement+Render.h"
#import "VTDOMElement+Style.h"
#import "VTDOMElement+Layout.h"
#import "VTDOMDocument.h"

@interface VTDOMLabelElement(){
    CGFloat _actualFontSize;
}

@end

@implementation VTDOMLabelElement

-(UIFont *) font{
    UIFont * font = [self fontValueForKey:@"font"];
    
    if(font == nil){
        CGFloat fontSize = [self floatValueForKey:@"font-size"];
        if(fontSize == 0){
            fontSize = 14;
        }
        font = [UIFont systemFontOfSize:14];
    }
    
    return font;
}

-(CGFloat) minFontSize{
    return [self floatValueForKey:@"min-font-size"];
}

-(UIColor *) textColor{
    
    UIColor * color = [self colorValueForKey:@"color"];
    
    if(color == nil){
        color = [UIColor blackColor];
    }
    
    return color;
}

-(NSLineBreakMode) lineBreakMode{
    
    NSLineBreakMode breakMode = NSLineBreakByCharWrapping;
    
    NSString * mode = [self stringValueForKey:@"break-mode"];
    
    if([mode isEqualToString:@"wrap"]){
        breakMode = NSLineBreakByWordWrapping;
    }
    else if([mode isEqualToString:@"clip"]){
        breakMode = NSLineBreakByClipping;
    }
    else if([mode isEqualToString:@"head"]){
        breakMode = NSLineBreakByTruncatingHead;
    }
    else if([mode isEqualToString:@"tail"]){
        breakMode = NSLineBreakByTruncatingTail;
    }
    else if([mode isEqualToString:@"middle"]){
        breakMode = NSLineBreakByTruncatingMiddle;
    }
    else{
        breakMode = NSLineBreakByCharWrapping;
    }

    return breakMode;
}

-(NSTextAlignment) alignment{
    
    NSTextAlignment alignment = NSTextAlignmentLeft;
    
    NSString * align = [self stringValueForKey:@"align"];
    
    if([align isEqualToString:@"center"]){
        alignment = NSTextAlignmentCenter;
    }
    else if([align isEqualToString:@"right"]){
        alignment = NSTextAlignmentRight;
    }

    return alignment;
}

-(CGSize) layoutChildren:(UIEdgeInsets)padding{
    CGRect r = [self frame];
    
    if(r.size.width == MAXFLOAT || r.size.height == MAXFLOAT){

        NSString * text = [self text];
        
        if(text){
            
            UIFont * font = [self font];
            CGFloat minFontSize = [self minFontSize];
            
            if(minFontSize == 0){
                minFontSize = font.pointSize;
            }
            
            CGFloat width = r.size.width;
            
            if(width == MAXFLOAT){
                NSString * max = [self stringValueForKey:@"max-width"];
                if(max){
                    width = [max floatValue];
                }
            }
            
            CGSize s = [text sizeWithFont:font minFontSize:minFontSize actualFontSize:&_actualFontSize forWidth:width lineBreakMode:self.lineBreakMode];
 
            if(r.size.width == MAXFLOAT){
                r.size.width = s.width;
            }
            
            if(r.size.height == MAXFLOAT){
                r.size.height = s.height;
            }
        }
        else{
            if(r.size.width == MAXFLOAT){
                r.size.width = 0;
            }
            
            if(r.size.height == MAXFLOAT){
                r.size.height = 0;
            }
        }
        
        [self setFrame:r];

    }
    return r.size;
}

-(void) draw:(CGRect) rect context:(CGContextRef) context{
    [super draw:rect context:context];

    NSString * text = [self text];
    
    if(text){
        
        UIFont * font = [self font];
        
        CGFloat minFontSize = [self minFontSize];
        
        if(minFontSize && _actualFontSize){
            font = [UIFont fontWithName:font.fontName size:_actualFontSize];
        }
        
        UIColor * color = [self textColor];
    
        NSLineBreakMode breakMode = [self lineBreakMode];
        
        NSTextAlignment alignment = [self alignment];
        
        CGContextSetFillColorWithColor(context, [color CGColor]);
    
        CGContextSetStrokeColorWithColor(context, [color CGColor]);

        UIGraphicsPushContext(context);

        CGSize size = self.frame.size;
        
        [text drawInRect:CGRectMake(0, 0, size.width, size.height) withFont:font lineBreakMode:breakMode alignment:alignment];
        
        UIGraphicsPopContext();
    }

}


@end
