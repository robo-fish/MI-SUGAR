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
#import "MI_AnalysisButton.h"
#include <math.h>


@implementation MI_AnalysisButton

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        userStartsClick = NO;
        animationStopped = YES;
        rotation = 0.0f;
        enabled = NO;
    }
    return self;
}


- (void)drawRect:(NSRect)rect
{
    float rot = rotation;
    float dimension = fmin(rect.size.width, rect.size.height);
    float centerX, centerY;
    float outerRadius = dimension * 0.29f;
    float innerRadius = dimension * 0.21f;
    float holeRadius = dimension * 0.115f;
    NSBezierPath* bp;
    float step = 45.0f;
    int i,j;
    
    // For each of the two cog wheel do...
    for (i = -1; i < 2; i+=2)
    {
        if (enabled)
        {
            if (animationStopped)
                [[NSColor colorWithDeviceRed:0.4f green:0.4f blue:0.55f alpha:1.0f] set];
            else
                [[NSColor colorWithDeviceRed:0.6f green:0.1f blue:0.1f alpha:1.0f] set];
        }
        else
            [[NSColor colorWithDeviceRed:0.8f green:0.8f blue:0.8f alpha:1.0f] set];
        centerX = rect.size.width * 0.5f + i * 0.24f * dimension;
        centerY = rect.size.height * 0.5f + i * 0.10f * dimension;
        bp = [NSBezierPath bezierPath];
        for (j = 0; j < (int)(360.0f / step); j++)
        {
            rot = i * rotation + (i + 1) * 3.3f + j * step; // cogs rotate in opposite directions
            [bp appendBezierPathWithArcWithCenter:NSMakePoint(centerX, centerY)
                                           radius:innerRadius
                                       startAngle:rot
                                         endAngle:rot + step * 0.4f];
            // move outwards, creating a cog projection
            [bp lineToPoint:NSMakePoint(centerX + outerRadius * cos((rot + step * 0.5f) * M_PI / 180.0),
                                        centerY + outerRadius * sin((rot + step * 0.5f) * M_PI / 180.0))];
            [bp appendBezierPathWithArcWithCenter:NSMakePoint(centerX, centerY)
                                           radius:outerRadius
                                       startAngle:rot + step * 0.5f
                                         endAngle:rot + step * 0.9f];
            // move toward center, finishing the projection
            [bp lineToPoint:NSMakePoint(centerX + innerRadius * cos((rot + step) * M_PI / 180.0),
                                        centerY + innerRadius * sin((rot + step) * M_PI / 180.0))];
        }
        // move towards center to give the cog a thickness but leave a hole at the center
        [bp moveToPoint:NSMakePoint(centerX + innerRadius * 0.5f, centerY)];
        [bp appendBezierPathWithOvalInRect:NSMakeRect(centerX - holeRadius,
                                                      centerY - holeRadius,
                                                      2.0f * holeRadius,
                                                      2.0f * holeRadius)];
        [bp setWindingRule:NSEvenOddWindingRule];
        [bp fill];
    }
}


- (void) startAnimation
{
    if (!animationStopped)
        return;
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    // Start animation
    animationStopped = NO;
    while (!animationStopped)
    {
        rotation += 4.0f;
        if (rotation > 360.0f)
            rotation -= 360.0f;
        [self display];
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    }
    [pool release];
}


- (void) stopAnimation
{
    animationStopped = YES;
    [self setNeedsDisplay:YES];
}


- (BOOL) isAnimating
{
    return !animationStopped;
}


- (void) setAction:(SEL)newAction
{
    action = newAction;
}


- (void) setTarget:(NSObject*)newTarget
{
    target = newTarget;
}


- (NSObject*) target
{
    return target;
}


- (BOOL) isOpaque
{
    return NO;
}


- (BOOL) isEnabled
{
    return enabled;
}


- (void) setEnabled:(BOOL)state
{
    enabled = state;
    [self setNeedsDisplay:YES];
}


/************************** Mouse Actions **************************/

- (void) mouseDown:(NSEvent*)theEvent
{
    userStartsClick = enabled;
}

- (void) mouseUp:(NSEvent*)theEvent
{
    if (userStartsClick && enabled)
    {
        [target performSelector:action
                     withObject:self
                     afterDelay:0.0];
    }
    userStartsClick = NO;
}

- (BOOL) acceptsFirstMouse:(NSEvent*)theEvent
{
    return YES; // for click-through behavior
}

/*******************************************************************/

- (void) dealloc
{
    [super dealloc];
}

@end
