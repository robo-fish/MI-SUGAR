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
#import "MI_MiscellaneousElements.h"
#import "MI_ConnectionPoint.h"

/********************************************** NODE WITH 4 CONNECTIONS *****/

@implementation MI_NodeElement

- (instancetype) init
{

  if (self = [super initWithSize:NSMakeSize(6.0f, 6.0f)])
  {
    [self setName:@"Node (4 Connectors)"];
    [self setLabel:@""];
    [self setShowsLabel:NO];
    MI_ConnectionPoint* left = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(-3.0f, 0.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Left"];
    MI_ConnectionPoint* right = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(3.0f, 0.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Right"];
    MI_ConnectionPoint* bottom = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(0.0f, -3.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Bottom"];
    MI_ConnectionPoint* top = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(0.0f, 3.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Top"];
    self.connectionPoints = @{@"Left": left, @"Right": right, @"Bottom": bottom, @"Top": top};
  }
  return self;
}

- (NSDictionary*) alignableConnectionPoints
{
    return [NSDictionary dictionaryWithObject:[[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(0.0f, 0.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Center"]
                                       forKey:@"Center"];
}

- (void) draw
{
    [super draw];
    [[NSBezierPath bezierPathWithOvalInRect:
        NSMakeRect(self.position.x - 3.0f, self.position.y - 3.0f, 6.0f, 6.0f)] fill];
    [super endDraw];
}

/* InsertableSchematicElement protocol implementation */
- (MI_ConnectionPoint*) topPoint { return [self.connectionPoints objectForKey:@"Top"]; }
- (MI_ConnectionPoint*) bottomPoint  { return [self.connectionPoints objectForKey:@"Bottom"]; }
- (MI_ConnectionPoint*) leftPoint  { return [self.connectionPoints objectForKey:@"Left"]; }
- (MI_ConnectionPoint*) rightPoint  { return [self.connectionPoints objectForKey:@"Right"]; }


- (NSString*) shapeToSVG
{
    return [NSString stringWithFormat:@"%@<circle stroke=\"none\" fill=\"black\" cx=\"%g\" cy=\"%g\" r=\"3\"/>%@",
        [super shapeToSVG], self.position.x, self.position.y, [super endSVG]];
}

@end

/**************************************** SPIKY NODE WITH 4 CONNECTIONS *****/

@implementation MI_SpikyNodeElement

- (instancetype) init
{
  if (self = [super initWithSize:NSMakeSize(10.0f, 10.0f)])
  {
    [self setName:@"Alt. Node (4 Connectors)"];
    [self setLabel:@""];
    [self setShowsLabel:NO];
    MI_ConnectionPoint* left = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(-5.0f, 0.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Left"];
    MI_ConnectionPoint* right = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(5.0f, 0.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Right"];
    MI_ConnectionPoint* bottom = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(0.0f, -5.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Bottom"];
    MI_ConnectionPoint* top = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(0.0f, 5.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Top"];
    self.connectionPoints = @{@"Left": left, @"Right": right, @"Bottom": bottom, @"Top": top};
  }
  return self;
}

- (NSDictionary*) alignableConnectionPoints
{
    return [NSDictionary dictionaryWithObject:[[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(0.0f, 0.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Center"]
                                       forKey:@"Center"];
}

- (void) draw
{
  [super draw];
  NSPoint const position = self.position;
  [NSBezierPath strokeLineFromPoint:NSMakePoint(position.x - 5.0f, position.y)
                            toPoint:NSMakePoint(position.x + 5.0f, position.y)];
  [NSBezierPath strokeLineFromPoint:NSMakePoint(position.x, position.y - 5.0f)
                            toPoint:NSMakePoint(position.x, position.y + 5.0f)];
  [[NSBezierPath bezierPathWithOvalInRect:
      NSMakeRect(position.x - 3.0f, position.y - 3.0f, 6.0f, 6.0f)] fill];
  [super endDraw];
}

/* InsertableSchematicElement protocol implementation */
- (MI_ConnectionPoint*) topPoint { return [self.connectionPoints objectForKey:@"Top"]; }
- (MI_ConnectionPoint*) bottomPoint  { return [self.connectionPoints objectForKey:@"Bottom"]; }
- (MI_ConnectionPoint*) leftPoint  { return [self.connectionPoints objectForKey:@"Left"]; }
- (MI_ConnectionPoint*) rightPoint  { return [self.connectionPoints objectForKey:@"Right"]; }


- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<circle stroke=\"none\" fill=\"black\" cx=\"%g\" cy=\"%g\" r=\"3\"/>",
        [super shapeToSVG], self.position.x, self.position.y];
    [svg appendFormat:@"<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 10 m -5 5 v -10\"/>%@",
        self.position.x - 5, self.position.y, [super endSVG]];
    return svg;
}

@end

/***************************************** GROUND WITH 3 CONNECTIONs *****/

@implementation MI_GroundElement

- (instancetype) init
{
  if (self = [super initWithSize:NSMakeSize(16.0f, 24.0f)])
  {
    [self setName:@"Ground (3 Connectors)"];
    [self setLabel:@""];
    [self setShowsLabel:NO];
    MI_ConnectionPoint* top = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(0.0f, 12.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Top"];
    MI_ConnectionPoint* right = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(3.0f, 9.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Right"];
    MI_ConnectionPoint* left = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(-3.0f, 9.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Left"];
    self.connectionPoints = @{@"Left": left, @"Right": right, @"Top": top};
  }
  return self;
}

- (NSDictionary*) alignableConnectionPoints
{
    return [NSDictionary dictionaryWithObject:[[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(0.0f, 9.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Center"]
                                       forKey:@"Center"];
}

- (void) draw
{
    [super draw];
    [[NSBezierPath bezierPathWithOvalInRect:
        NSMakeRect(self.position.x - 3.0f, self.position.y + 6.0f, 6.0f, 6.0f)] fill];
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(self.position.x, self.position.y + 6.0f)]; // (0, 6)
    [bp relativeLineToPoint:NSMakePoint(  0.0f, -10.0f)]; // ( 0, -4)
    [bp relativeMoveToPoint:NSMakePoint( -8.0f,  0.0f)]; // ( -8, -4)
    [bp relativeLineToPoint:NSMakePoint( 16.0f,  0.0f)]; // (8, -4)
    [bp relativeMoveToPoint:NSMakePoint(-12.0f, -4.0f)]; // ( -4, -8)
    [bp relativeLineToPoint:NSMakePoint(  8.0f,  0.0f)]; // (4, -8)
    [bp relativeMoveToPoint:NSMakePoint( -6.0f, -4.0f)]; // (-2, -12)
    [bp relativeLineToPoint:NSMakePoint(  4.0f,  0.0f)]; // (2, -12)
    [bp stroke];
    [super endDraw];
}


- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<circle stroke=\"none\" fill=\"black\" cx=\"%g\" cy=\"%g\" r=\"3\"/>",
        [super shapeToSVG], self.position.x, self.position.y + 9.0f];
    [svg appendFormat:@"\n<path stroke=\"black\" fill=\"none\" d=\"M %g %g v -10 m -8 0 h 16 m -12 -4 h 8 m -6 -4 h 4\"/>%@",
        self.position.x, self.position.y + 6.0f, [super endSVG]];
    return svg;
}

@end

/************************************ GROUND WITH SINGLE CONNECTION *****/

@implementation MI_PlainGroundElement

- (instancetype) init
{
    if (self = [super initWithSize:NSMakeSize(16.0f, 18.0f)])
    {
      [self setName:@"Ground"];
      [self setLabel:@""];
      [self setShowsLabel:NO];
      MI_ConnectionPoint* ground = [[MI_ConnectionPoint alloc]
          initWithPosition:NSMakePoint(0.0f, 9.0f)
                      size:NSMakeSize(6.0f, 6.0f)
                      name:@"Ground"];
      self.connectionPoints = @{ @"Ground": ground };
    }
    return self;
}


- (void) draw
{
    [super draw];
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(self.position.x, self.position.y + 9.0f)]; // (0, 6)
    [bp relativeLineToPoint:NSMakePoint(  0.0f, -10.0f)]; // ( 0, -4)
    [bp relativeMoveToPoint:NSMakePoint( -8.0f,  0.0f)]; // ( -8, -4)
    [bp relativeLineToPoint:NSMakePoint( 16.0f,  0.0f)]; // (8, -4)
    [bp relativeMoveToPoint:NSMakePoint(-12.0f, -4.0f)]; // ( -4, -8)
    [bp relativeLineToPoint:NSMakePoint(  8.0f,  0.0f)]; // (4, -8)
    [bp relativeMoveToPoint:NSMakePoint( -6.0f, -4.0f)]; // (-2, -12)
    [bp relativeLineToPoint:NSMakePoint(  4.0f,  0.0f)]; // (2, -12)
    [bp stroke];
    [super endDraw];
}


- (NSString*) shapeToSVG
{
    return [NSString stringWithFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g v -10 m -8 0 h 16 m -12 -4 h 8 m -6 -4 h 4\"/>%@",
        [super shapeToSVG], self.position.x, self.position.y + 9.0f, [super endSVG]];
}

@end

/*************************************************** VOLTAGE-CONTROLLED SWITCH *****/

@implementation MI_VoltageControlledSwitchElement

- (instancetype) init
{
  if (self = [super initWithSize:NSMakeSize(36.0f, 20.0f)])
  {
    [self setName:@"Voltage-controlled Switch"];
    [self setLabel:@"S"];
    [self setLabelPosition:MI_DirectionUp];
    MI_ConnectionPoint* terminal1 = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(-18.0f, 6.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Terminal1"
     nodeNumberPlacement:MI_DirectionNorthwest];
    MI_ConnectionPoint* terminal2 = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(18.0f, 6.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Terminal2"
     nodeNumberPlacement:MI_DirectionNortheast];
    MI_ConnectionPoint* controlPlus = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(-6.0f, -10.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"ControlPlus"
     nodeNumberPlacement:MI_DirectionSouthwest];
    MI_ConnectionPoint* controlMinus = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(6.0f, -10.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"ControlMinus"
     nodeNumberPlacement:MI_DirectionSoutheast];
    self.connectionPoints = @{ @"Terminal1": terminal1, @"Terminal2": terminal2, @"ControlPlus" : controlPlus, @"ControlMinus": controlMinus };
    [self.parameters setObject:@"DefaultSwitch" forKey:@"Model"];
    [self.parameters setObject:@"OFF" forKey:@"Initial State"];
  }
  return self;
}

- (void) draw
{
    [super draw];
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(self.position.x - 18.0f, self.position.y + 6.0f)];
    [bp relativeLineToPoint:NSMakePoint(12.0f, 0.0f)]; // (-6, 6)
    [bp relativeMoveToPoint:NSMakePoint(12.0f, 0.0f)]; // (6, 6)
    [bp relativeLineToPoint:NSMakePoint(12.0f, 0.0f)]; // (18, 6)
    [bp relativeMoveToPoint:NSMakePoint(-6.0f, -6.0f)]; // (12, 0)
    [bp relativeLineToPoint:NSMakePoint(-24.0f, 0.0f)]; // (-12, 0)
    [bp relativeMoveToPoint:NSMakePoint(6.0f, 0.0f)]; // (-6, 0)
    [bp relativeLineToPoint:NSMakePoint(0.0f, -10.0f)]; // (-6, -10)
    [bp relativeMoveToPoint:NSMakePoint(12.0f, 0.0f)]; // (6, -10)
    [bp relativeLineToPoint:NSMakePoint(0.0f, 10.0f)]; // (6, 0)
    // Draw plus sign
    [bp relativeMoveToPoint:NSMakePoint(-17.0f, -3.0f)];
    [bp relativeLineToPoint:NSMakePoint(0.0f, -5.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-2.5f, 2.5f)];
    [bp relativeLineToPoint:NSMakePoint(5.0f, 0.0f)];
    [bp stroke];
    [[NSBezierPath bezierPathWithOvalInRect:
        NSMakeRect(self.position.x - 8.0f, self.position.y + 4.0f, 4.0f, 4.0f)] fill];
    [[NSBezierPath bezierPathWithOvalInRect:
        NSMakeRect(self.position.x + 4.0f, self.position.y + 4.0f, 4.0f, 4.0f)] fill];
    [super endDraw];
}


- (MI_DeviceModelType) usedDeviceModelType
{
    return MI_DeviceModelTypeSwitch;
}


- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 12 m 12 0 h 12 m -6 -6 h -24 m 6 0 v -10 m 12 0 v 10 m -17 -3 v -5 m -2.5 2.5 h 5\"/>",
        [super shapeToSVG], self.position.x - 18.0f, self.position.y + 6.0f];
    [svg appendFormat:@"\n<circle stroke=\"none\" fill=\"black\" cx=\"%g\" cy=\"%g\" r=\"2\"/>",
        self.position.x - 6.0f, self.position.y + 6.0f];
    [svg appendFormat:@"\n<circle stroke=\"none\" fill=\"black\" cx=\"%g\" cy=\"%g\" r=\"2\"/>%@",
        self.position.x + 6.0f, self.position.y + 6.0f, [super endSVG]];
    return svg;
}

@end

