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
#import "NyquistView.h"
#import "MI_ComplexNumber.h"

#define DEFAULT_MARGIN 10

@implementation NyquistView

- (id) init
{
    if (self = [super init])
    {
        var = nil;
        marginsAreCalculated = NO;
        labelRealMax = labelRealMin = labelImaginaryMax = labelImaginaryMin = nil;
    }
    return self;
}


- (void) awakeFromNib
{
    leftMargin = rightMargin = bottomMargin = topMargin = DEFAULT_MARGIN;
    realMin = realMax = imaginaryMin = imaginaryMax = 0.0;
    labelFontAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
        [NSFont systemFontOfSize:12], NSFontAttributeName,
        [NSColor blackColor], NSForegroundColorAttributeName,
        NULL] retain];
    label_Re = [@"Re" retain];
    label_Im = [@"Im" retain];
}


- (void) drawRect:(NSRect)rect
{
    /* Draw background */
    [[NSColor whiteColor] set];
    NSRectFill(rect);

    if (var)
    {
        NSBezierPath* myPath = [NSBezierPath bezierPath];
        MI_ComplexNumber* val = [var complexValueAtIndex:0 forSet:0];
        NSUInteger numPoints = [var numberOfValuesPerSet];
        [[NSColor blackColor] set];
        
        // Important: the margins have to be calculated before any call of 'valueToView' is made
        if (!marginsAreCalculated)
        {
          [self calculateMargins:rect];
        }

        NSPoint const startPoint = [self valueToView:NSMakePoint([val real], [val imaginary])];
        [myPath appendBezierPathWithOvalInRect:NSMakeRect(startPoint.x - 3, startPoint.y - 3, 6, 6)];
        [myPath fill];
        [myPath moveToPoint:startPoint];
        for (int k = 1; k < numPoints; k++)
        {
            val = [var complexValueAtIndex:k forSet:0];
            [myPath lineToPoint:[self valueToView:NSMakePoint([val real], [val imaginary])]];
        }
        [myPath stroke];

        // Draw frame
        [[NSColor grayColor] set];
        [NSBezierPath strokeRect:NSMakeRect(leftMargin - 1, bottomMargin - 1,
            rect.size.width - rightMargin - leftMargin + 2,
            rect.size.height - topMargin - bottomMargin + 2)];

        [self drawLabels];
    }
}


- (NSPoint) valueToView:(NSPoint)point
{
    return NSMakePoint(leftMargin + (((point.x - realMin) / (realMax - realMin)) *
        ([self bounds].size.width - leftMargin - rightMargin)), bottomMargin +
        (((point.y - imaginaryMin) / (imaginaryMax - imaginaryMin)) *
        ([self bounds].size.height - topMargin - bottomMargin)));
}


- (void) drawLabels
{
    NSSize s = [self bounds].size;
    [labelRealMin drawAtPoint:NSMakePoint(leftMargin - 2, 1)
               withAttributes:labelFontAttributes];
    [labelRealMax drawAtPoint:NSMakePoint(s.width - rightMargin - [labelRealMax sizeWithAttributes:labelFontAttributes].width + 4, 1)
               withAttributes:labelFontAttributes];
    [labelImaginaryMin drawAtPoint:NSMakePoint(leftMargin - [labelImaginaryMin sizeWithAttributes:labelFontAttributes].width - 3, bottomMargin - 4)
                    withAttributes:labelFontAttributes];
    [labelImaginaryMax drawAtPoint:NSMakePoint(leftMargin - [labelImaginaryMax sizeWithAttributes:labelFontAttributes].width - 3,
        s.height - topMargin - [labelImaginaryMax sizeWithAttributes:labelFontAttributes].height + 4)
                    withAttributes:labelFontAttributes];

    [label_Im drawAtPoint:NSMakePoint(leftMargin - 3 - [label_Im sizeWithAttributes:labelFontAttributes].width,
        ((s.height - bottomMargin - topMargin) / 2) + bottomMargin)
           withAttributes:labelFontAttributes];
    [label_Re drawAtPoint:NSMakePoint(((s.width - leftMargin - rightMargin) / 2 ) + leftMargin,
        bottomMargin - 1 - [label_Re sizeWithAttributes:labelFontAttributes].height)
           withAttributes:labelFontAttributes];
}


- (void) calculateMargins:(NSRect)rect
{
    realMin = [var realMinimum];
    realMax = [var realMaximum];
    imaginaryMin = [var imaginaryMinimum];
    imaginaryMax = [var imaginaryMaximum];

    // Calculate the label metrics
    [labelRealMax release];
    [labelRealMin release];
    [labelImaginaryMax release];
    [labelImaginaryMin release];
    labelRealMax = [[NSString stringWithFormat:@"%4.2g", realMax] retain];
    labelRealMin = [[NSString stringWithFormat:@"%4.2g", realMin] retain];
    labelImaginaryMax = [[NSString stringWithFormat:@"%4.2g", imaginaryMax] retain];
    labelImaginaryMin = [[NSString stringWithFormat:@"%4.2g", imaginaryMin] retain];
        
    bottomMargin = (int) fmaxf(
        [labelRealMin sizeWithAttributes:labelFontAttributes].height,
        [labelRealMax sizeWithAttributes:labelFontAttributes].height) + 4;
    leftMargin = (int)fmaxf(
        [labelImaginaryMax sizeWithAttributes:labelFontAttributes].width,
        [labelImaginaryMin sizeWithAttributes:labelFontAttributes].width) + 6;

    marginsAreCalculated = YES;
}


- (void) setVariable:(AnalysisVariable*)aVar;
{
    if ([aVar isComplex])
    {
        [aVar retain];
        [var release];
        var = aVar;
        [var findMinMax];
    }
    else
    {
        [var release];
        var = nil;
    }
    marginsAreCalculated = NO;
    [self setNeedsDisplay:YES];
}

/*
- (void) resizeGraph:(NSNotification*)notif
{
    marginsAreCalculated = NO;
    [self setNeedsDisplay:YES];
}
*/

- (void) dealloc
{
    [var release];
    [labelRealMax release];
    [labelRealMin release];
    [labelImaginaryMax release];
    [labelImaginaryMin release];
    [label_Re release];
    [label_Im release];
    [labelFontAttributes release];
    [super dealloc];
}

@end
