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
#import "MI_DirectionChooser.h"

@implementation MI_DirectionChooser
{
  SEL action;
  IBOutlet NSObject* target;
  MI_Direction direction;
  NSImage* backgroundImage;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        target = nil;
        direction = MI_DirectionUp;
        backgroundImage = [[NSImage alloc] initWithContentsOfFile:
            [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/palette_button_background.png"]];
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{
    /*
    [[NSColor colorWithDeviceWhite:0.8f alpha:1.0f] set];
    NSRectFill(rect);
    [[NSColor blackColor] set];
    NSBezierPath* bp = [NSBezierPath bezierPathWithRect:rect];
    [bp stroke];*/
        /*
    [backgroundImage drawInRect:rect
                       fromRect:NSMakeRect(0.0f, 0.0f, [backgroundImage size].width, [backgroundImage size].height)
                      operation:NSCompositeCopy
                       fraction:1.0f];
     */

    // draw empty circle in the middle
    [[NSBezierPath bezierPathWithOvalInRect:
        NSInsetRect(rect, rect.size.width * 0.35, rect.size.height * 0.35)] stroke];

    if (direction == MI_DirectionUp)
        [[NSBezierPath bezierPathWithOvalInRect:
            NSMakeRect(rect.origin.x + rect.size.width * 0.375f,
                       rect.origin.y + rect.size.height * 0.70f,
                       rect.size.width * 0.25f, rect.size.height * 0.25f)] fill];
    else if (direction == MI_DirectionDown)
        [[NSBezierPath bezierPathWithOvalInRect:
            NSMakeRect(rect.origin.x + rect.size.width * 0.375f,
                       rect.origin.y + rect.size.height * 0.05f,
                       rect.size.width * 0.25f, rect.size.height * 0.25f)] fill];
    else if (direction == MI_DirectionLeft)
        [[NSBezierPath bezierPathWithOvalInRect:
            NSMakeRect(rect.origin.x + rect.size.width * 0.05f,
                       rect.origin.y + rect.size.height * 0.375f,
                       rect.size.width * 0.25f, rect.size.height * 0.25f)] fill];
    else if (direction == MI_DirectionRight)
        [[NSBezierPath bezierPathWithOvalInRect:
            NSMakeRect(rect.origin.x + rect.size.width * 0.70f,
                       rect.origin.y + rect.size.height * 0.375f,
                       rect.size.width * 0.25f, rect.size.height * 0.25f)] fill];
    /* else draw nothing */
}


- (void) mouseDown:(NSEvent*)theEvent
{
  CGPoint const clickPosition = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  CGRect const rect = [self frame];
  CGFloat const x = clickPosition.x - rect.size.width/2.0f;
  CGFloat const y = clickPosition.y - rect.size.height/2.0f;

  if ( (fabs(x) < rect.size.width * 0.15) && (fabs(y) < rect.size.height * 0.15) )
  {
    direction = MI_DirectionNone;
  }
  else if (fabs(x) >= fabs(y))
  {
    direction = (x >= 0.0f) ? MI_DirectionRight : MI_DirectionLeft;
  }
  else
  {
    direction = (y >= 0.0f) ? MI_DirectionUp : MI_DirectionDown;
  }
  [self setNeedsDisplay:YES];

  [target performSelector:action withObject:self afterDelay:0.0];
}


- (void) setTarget:(NSObject*)newTarget
{
    target = newTarget;
}

- (void) setAction:(SEL)newAction
{
    action = newAction;
}

- (MI_Direction) selectedDirection
{
    return direction;
}

- (void) setDirection:(MI_Direction)newDirection
{
    direction = newDirection;
    [self setNeedsDisplay:YES];
}


- (BOOL) acceptsFirstMouse:(NSEvent*)theEvent
{
    return YES; // for click-through behavior
}


@end
