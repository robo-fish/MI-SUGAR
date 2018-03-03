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
#import "MI_ColorCell.h"

@implementation MI_ColorCell

/* Based on code from John Harte <johnharte@mac.com>,
published in the cocoa-dev mailing list at Apple's
web site.
*/

- (instancetype) init
{
    if (self = [super init])
    {
        myColor = nil;
    }
    return self;
}

- (void) drawWithFrame:(NSRect)cellFrame
                inView:(NSView*)controlView
{
    // use the smallest size to square off the box & center the box
    /*
     NSRect square = NSInsetRect(cellFrame, 2.0, 2.0);
     if (square.size.height < square.size.width)
     {
         square.size.width = square.size.height;
         square.origin.x = square.origin.x + (cellFrame.size.width -
                                              square.size.width) / 2.0;
     }
     else
     {
         square.size.height = square.size.width;
         square.origin.y = square.origin.y + (cellFrame.size.height -
                                              square.size.height) / 2.0;
     }
     */
    /* BOX
    [[NSColor grayColor] set];
    [NSBezierPath strokeRect:NSInsetRect(cellFrame, 4.0, 4.0)];
    [myColor set];
    [NSBezierPath fillRect:NSInsetRect(cellFrame, 5.0, 5.0)];
    */
    /* CIRCLE */
    NSBezierPath* outerCircle = [NSBezierPath bezierPath];
    NSBezierPath* innerCircle = [NSBezierPath bezierPath];
    float radius = fmin(cellFrame.size.width, cellFrame.size.height)/2.0 - 3.0;
    NSPoint centerPoint =
        NSMakePoint(cellFrame.size.width/2.0 + cellFrame.origin.x,
                    cellFrame.size.height/2.0 + cellFrame.origin.y);
    [[NSColor grayColor] set];
    [outerCircle appendBezierPathWithArcWithCenter:centerPoint
                                            radius:radius
                                        startAngle:0.0
                                          endAngle:360.0
                                         clockwise:NO];
    [outerCircle stroke];
    [myColor set];
    [innerCircle appendBezierPathWithArcWithCenter:centerPoint
                                            radius:(radius - 1.0)
                                        startAngle:0.0
                                          endAngle:360.0
                                         clockwise:NO];
    [innerCircle fill];
}


- (void) setColor:(NSColor*)newColor
{
    myColor = newColor;
}


- (NSColor*) color
{
    return myColor;
}


@end
