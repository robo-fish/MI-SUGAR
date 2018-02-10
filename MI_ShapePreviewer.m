/***************************************************************************
*
*   Copyright Kai Özer, 2003-2018
*
*   This file is part of MI-SUGAR.
*
*   MI-SUGAR is free software; you can redistribute it and/or modify
*   it under the terms of the GNU General Public License as published by
*   the Free Software Foundation; either version 2 of the License, or
*   (at your option) any later version.
*
*   MI-SUGAR is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License
*   along with MI-SUGAR; if not, write to the Free Software Foundation, Inc.,
*   51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*
****************************************************************************/
#import "MI_ShapePreviewer.h"


@implementation MI_ShapePreviewer

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        shape = nil;
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{
    // Draw background
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:rect];
    
    // Draw shape
    [[NSColor blackColor] set];
    if (shape != nil)
    {
        NSAffineTransform* positionTransform = [NSAffineTransform transform];
        NSGraphicsContext* currentContext = [NSGraphicsContext currentContext];
        [positionTransform translateXBy:rect.size.width/2.0f
                                    yBy:rect.size.height/2.0f];
        [currentContext saveGraphicsState];
        [positionTransform concat];
        [shape drawAtPoint:NSMakePoint(0,0)];
        [currentContext restoreGraphicsState];
    }
    
    // Draw frame
    // Draw border - in Mac OS X the desktop light shines from the top
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(0, rect.size.height)];
    [bp relativeLineToPoint:NSMakePoint(rect.size.width, 0)];
    [bp stroke];
    [[NSColor grayColor] set];
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(rect.size.width, rect.size.height)];
    [bp lineToPoint:NSMakePoint(rect.size.width, 0)];
    [bp lineToPoint:NSMakePoint(0, 0)];
    [bp lineToPoint:NSMakePoint(0, rect.size.height)];
    [bp stroke];
}


- (void) setShape:(MI_Shape*)theShape
{
    [theShape retain];
    [shape release];
    shape = theShape;
}


- (MI_Shape*) shape
{
    return shape;
}


- (BOOL) isOpaque
{
    return YES;
}


- (void) dealloc
{
    [shape release];
    [super dealloc];
}

@end
