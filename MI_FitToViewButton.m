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
#include <math.h>
#import "MI_FitToViewButton.h"


@implementation MI_FitToViewButton
{
  IBOutlet NSObject* target;
  SEL action;
  BOOL enabled; // if the button is enabled
  BOOL highlighted; // if mouse enters drawing area
  BOOL userStartsClick; // used to give a button press feel to the view
  NSColor* normalColor;
  NSColor* highlightColor;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        enabled = NO;
        highlighted = NO;
        userStartsClick = NO;
        normalColor = [[NSColor colorWithDeviceRed:0.4f green:0.4f blue:0.55f alpha:1.0f] retain];
        highlightColor = [[NSColor colorWithDeviceRed:0.6f green:0.1f blue:0.1f alpha:1.0f] retain];
    }
    return self;
}


- (void)drawRect:(NSRect)rect
{
    float width = rect.size.width;
    float height = rect.size.height;
    float dimension = fmin(width, height);
    
    if (enabled)
        [normalColor set];
    else
        [[NSColor colorWithDeviceRed:0.8f green:0.8f blue:0.8f alpha:1.0f] set];
    
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [bp setLineWidth:2.0f];
    [bp appendBezierPathWithRect:NSMakeRect((width - dimension)/2.0f, (height - dimension)/2.0f, dimension, dimension)];
    [bp stroke];
    
    // draw arrows
    if (enabled && highlighted)
    {
        [highlightColor set];
    }

    // arrow shafts
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(width/2.0f + dimension * 0.15f, height/2.0f + dimension * 0.15f)];
    [bp lineToPoint:NSMakePoint(width/2.0f + dimension * 0.50f, height/2.0f + dimension * 0.50f)];
    [bp moveToPoint:NSMakePoint(width/2.0f + dimension * 0.15f, height/2.0f - dimension * 0.15f)];
    [bp lineToPoint:NSMakePoint(width/2.0f + dimension * 0.50f, height/2.0f - dimension * 0.50f)];
    [bp moveToPoint:NSMakePoint(width/2.0f - dimension * 0.15f, height/2.0f + dimension * 0.15f)];
    [bp lineToPoint:NSMakePoint(width/2.0f - dimension * 0.50f, height/2.0f + dimension * 0.50f)];
    [bp moveToPoint:NSMakePoint(width/2.0f - dimension * 0.15f, height/2.0f - dimension * 0.15f)];
    [bp lineToPoint:NSMakePoint(width/2.0f - dimension * 0.50f, height/2.0f - dimension * 0.50f)];
    [bp stroke];
    // arrow heads
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(width/2.0f + dimension * 0.50f, height/2.0f + dimension * 0.50f)];
    [bp lineToPoint:NSMakePoint(width/2.0f + dimension * 0.40f, height/2.0f + dimension * 0.25f)];
    [bp lineToPoint:NSMakePoint(width/2.0f + dimension * 0.25f, height/2.0f + dimension * 0.40f)];
    [bp closePath];
    [bp fill];
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(width/2.0f + dimension * 0.50f, height/2.0f - dimension * 0.50f)];
    [bp lineToPoint:NSMakePoint(width/2.0f + dimension * 0.40f, height/2.0f - dimension * 0.25f)];
    [bp lineToPoint:NSMakePoint(width/2.0f + dimension * 0.25f, height/2.0f - dimension * 0.40f)];
    [bp closePath];
    [bp fill];
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(width/2.0f - dimension * 0.50f, height/2.0f + dimension * 0.50f)];
    [bp lineToPoint:NSMakePoint(width/2.0f - dimension * 0.40f, height/2.0f + dimension * 0.25f)];
    [bp lineToPoint:NSMakePoint(width/2.0f - dimension * 0.25f, height/2.0f + dimension * 0.40f)];
    [bp closePath];
    [bp fill];
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(width/2.0f - dimension * 0.50f, height/2.0f - dimension * 0.50f)];
    [bp lineToPoint:NSMakePoint(width/2.0f - dimension * 0.40f, height/2.0f - dimension * 0.25f)];
    [bp lineToPoint:NSMakePoint(width/2.0f - dimension * 0.25f, height/2.0f - dimension * 0.40f)];
    [bp closePath];
    [bp fill];
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


- (BOOL) isHighlighted
{
    return highlighted;
}


- (void) setHighlighted:(BOOL)highlight
{
    highlighted = highlight;
    [self setNeedsDisplay:YES];
}


/************************** Mouse Actions **************************/

- (void) mouseDown:(NSEvent*)theEvent
{
    userStartsClick = enabled;
    [self setHighlighted:YES];
}

- (void) mouseUp:(NSEvent*)theEvent
{
    [self setHighlighted:NO];
    if (userStartsClick && enabled)
    {
        [target performSelector:action
                     withObject:self
                     afterDelay:0.0];
    }
    userStartsClick = NO;
}

- (void) mouseEntered:(NSEvent *)theEvent
{
    [self setHighlighted:YES];
    NSLog(@"entered");
}


- (void) mouseExited:(NSEvent *)theEvent
{
    [self setHighlighted:NO];
    NSLog(@"exited");
}


- (BOOL) acceptsFirstMouse:(NSEvent*)theEvent
{
    return YES; // for click-through behavior
}

/*******************************************************************/

- (void) dealloc
{
    [normalColor release];
    [highlightColor release];
    [super dealloc];
}

@end
