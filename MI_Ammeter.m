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
#import "MI_Ammeter.h"


@implementation MI_Ammeter

- (instancetype) init
{
  if (self = [super init])
  {
    originalSize = size = NSMakeSize(32.0f, 48.0f);
    [self setName:@"Ammeter"];
    [self setLabel:@""];
    [self setLabelPosition:MI_DIRECTION_UP];
    MI_ConnectionPoint* anode = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(0.0f, 24.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Anode"
     nodeNumberPlacement:MI_DIRECTION_NONE];
    MI_ConnectionPoint* cathode = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(0.0f, -24.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Cathode"
     nodeNumberPlacement:MI_DIRECTION_NONE];
    self.connectionPoints = @{@"Anode": anode, @"Cathode" : cathode};
  }
  return self;
}


- (void) draw
{
    //NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    //
    [super endDraw];
}

@end
