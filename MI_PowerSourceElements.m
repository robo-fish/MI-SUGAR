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
#import "MI_PowerSourceElements.h"
#import "MI_ConnectionPoint.h"


/************************************************* DC VOLTAGE SOURCE ******/
@implementation MI_DCVoltageSourceElement

- (instancetype) init
{
  if (self = [super init])
  {
    originalSize = size = NSMakeSize(32.0f, 48.0f);
    [self setName:@"DC Voltage Source"];
    [self setLabel:@"Vdc"];
    [self setLabelPosition:MI_DIRECTION_RIGHT];
    MI_ConnectionPoint* anode = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(0.0f, 24.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Anode"
     nodeNumberPlacement:MI_DIRECTION_NORTHEAST];
    MI_ConnectionPoint* cathode = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(0.0f, -24.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Cathode"
     nodeNumberPlacement:MI_DIRECTION_SOUTHEAST];
    self.connectionPoints = @{@"Anode": anode, @"Cathode": cathode};
    [parameters setObject:@"12.0" forKey:@"Voltage"];
  }
  return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(self.position.x, self.position.y + 24.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,  -6.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f, -18.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp relativeMoveToPoint:NSMakePoint( -4.0f, +30.0f)];
    [bp relativeLineToPoint:NSMakePoint(  8.0f,   0.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f, -14.0f)];
    [bp relativeLineToPoint:NSMakePoint( -8.0f,   0.0f)];
    [bp stroke];
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(self.position.x - 16.0f, self.position.y - 16.0f, 32.0f, 32.0f)] stroke];
    [super endDraw];
}

- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g v -8 m 0 -6 v -8 m 0 -18 v -8 m -4 30 h 8 m 0 -14 h -8\"/>",
        [super shapeToSVG], self.position.x, self.position.y + 24.0f];
    [svg appendFormat:@"\n<circle stroke=\"black\" fill=\"none\" cx=\"%g\" cy=\"%g\" r=\"16\"/>%@",
        self.position.x, self.position.y, [super endSVG]];
    return svg;
}

@end

/************************************************* AC VOLTAGE SOURCE ******/
@implementation MI_ACVoltageSourceElement

- (instancetype) init
{
  if (self = [super init])
  {
    originalSize = size = NSMakeSize(32.0f, 48.0f);
    [self setName:@"AC Voltage Source"];
    [self setLabel:@"Vac"];
    [self setLabelPosition:MI_DIRECTION_RIGHT];
    MI_ConnectionPoint* anode = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(0.0f, 24.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Anode"
     nodeNumberPlacement:MI_DIRECTION_NORTHEAST];
    MI_ConnectionPoint* cathode = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(0.0f, -24.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Cathode"
     nodeNumberPlacement:MI_DIRECTION_SOUTHEAST];
    self.connectionPoints = @{@"Anode": anode, @"Cathode": cathode };
    [parameters setObject:@"380" forKey:@"Magnitude"];
    [parameters setObject:@"0" forKey:@"Phase"];
  }
  return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(self.position.x, self.position.y + 24.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-10.0f, -16.0f)];
    [bp relativeCurveToPoint:NSMakePoint( 10.0f,  0.0f)
               controlPoint1:NSMakePoint(  3.0f,  5.0f)
               controlPoint2:NSMakePoint(  7.0f,  5.0f)];
    [bp relativeCurveToPoint:NSMakePoint( 10.0f,  0.0f)
               controlPoint1:NSMakePoint(  3.0f, -5.0f)
               controlPoint2:NSMakePoint(  7.0f, -5.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-10.0f, -16.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp stroke];
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(self.position.x - 16.0f, self.position.y - 16.0f, 32.0f, 32.0f)] stroke];
    [super endDraw];
}

- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g v -8 m -10 -16 c 3 5 7 5 10 0 c 3 -5 7 -5 10 0 m -10 -16 v -8\"/>",
        [super shapeToSVG], self.position.x, self.position.y + 24.0f];
    [svg appendFormat:@"\n<circle stroke=\"black\" fill=\"none\" cx=\"%g\" cy=\"%g\" r=\"16\"/>%@",
        self.position.x, self.position.y, [super endSVG]];
    return svg;
}

@end

/************************************************* PULSE VOLTAGE SOURCE ******/

@implementation MI_PulseVoltageSourceElement

- (instancetype) init
{
  if (self = [super init])
  {
    originalSize = size = NSMakeSize(32.0f, 48.0f);
    [self setName:@"Pulse Voltage Source"];
    [self setLabel:@"VPulse"];
    [self setLabelPosition:MI_DIRECTION_RIGHT];
    MI_ConnectionPoint* anode = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(0.0f, 24.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Anode"
     nodeNumberPlacement:MI_DIRECTION_NORTHEAST];
    MI_ConnectionPoint* cathode = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(0.0f, -24.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Cathode"
     nodeNumberPlacement:MI_DIRECTION_SOUTHEAST];
    self.connectionPoints = @{@"Anode": anode, @"Cathode": cathode};
    [parameters setObject:@"0" forKey:@"Initial Value"];
    [parameters setObject:@"5" forKey:@"Pulsed Value"];
    [parameters setObject:@"0" forKey:@"Delay Time"];
    [parameters setObject:@"0" forKey:@"Rise Time"];
    [parameters setObject:@"0" forKey:@"Fall Time"];
    [parameters setObject:@"0.001" forKey:@"Pulse Width"];
    [parameters setObject:@"1" forKey:@"Period"];
  }
  return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(self.position.x, self.position.y + 24.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp relativeMoveToPoint:NSMakePoint( -9.0f, -22.0f)];
    [bp relativeLineToPoint:NSMakePoint(  5.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  12.0f)];
    [bp relativeLineToPoint:NSMakePoint(  8.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f, -12.0f)];
    [bp relativeLineToPoint:NSMakePoint(  5.0f,   0.0f)];
    [bp relativeMoveToPoint:NSMakePoint( -9.0f, -10.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp stroke];
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(self.position.x - 16.0f, self.position.y - 16.0f, 32.0f, 32.0f)] stroke];
    [super endDraw];
}

- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g v -8 m -9 -22 h 5 v 12 h 8 v -12 h 5 m -9 -10 v -8\"/>",
        [super shapeToSVG], self.position.x, self.position.y + 24.0f];
    [svg appendFormat:@"\n<circle stroke=\"black\" fill=\"none\" cx=\"%g\" cy=\"%g\" r=\"16\"/>%@",
        self.position.x, self.position.y, [super endSVG]];
    return svg;
}

@end


/******************************************** SINUSOIDAL VOLTAGE SOURCE ******/

@implementation MI_SinusoidalVoltageSourceElement

- (instancetype) init
{
  if (self = [super init])
  {
    originalSize = size = NSMakeSize(32.0f, 48.0f);
    [self setName:@"Sinusoidal Voltage Source"];
    [self setLabel:@"VSin"];
    [self setLabelPosition:MI_DIRECTION_RIGHT];
    MI_ConnectionPoint* anode = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(0.0f, 24.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Anode"
     nodeNumberPlacement:MI_DIRECTION_NORTHEAST];
    MI_ConnectionPoint* cathode = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(0.0f, -24.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Cathode"
     nodeNumberPlacement:MI_DIRECTION_SOUTHEAST];
    self.connectionPoints = @{@"Anode": anode, @"Cathode": cathode};
    [parameters setObject:@"0.0" forKey:@"Offset"];
    [parameters setObject:@"1.0" forKey:@"Amplitude"];
    [parameters setObject:@"50.0" forKey:@"Frequency"];
    [parameters setObject:@"0.0" forKey:@"Delay"];
    [parameters setObject:@"0.0" forKey:@"Damping Factor"];
  }
  return self;
}

- (void) draw
{
  NSBezierPath* bp = [NSBezierPath bezierPath];
  [super draw];
  [bp moveToPoint:NSMakePoint(self.position.x, self.position.y + 24.0f)];
  [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
  [bp relativeMoveToPoint:NSMakePoint(  0.0f, -32.0f)];
  [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
  [bp relativeMoveToPoint:NSMakePoint( -8.0f,  24.0f)];
  [bp relativeCurveToPoint:NSMakePoint( 8.0f,   0.0f)
             controlPoint1:NSMakePoint( 3.0f, -10.0f)
             controlPoint2:NSMakePoint( 5.0f, -10.0f)];
  [bp relativeCurveToPoint:NSMakePoint( 8.0f,   0.0f)
             controlPoint1:NSMakePoint( 3.0f,  10.0f)
             controlPoint2:NSMakePoint( 5.0f,  10.0f)];
  [bp stroke];

  [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(self.position.x - 16.0f, self.position.y - 16.0f, 32.0f, 32.0f)] stroke];
  [super endDraw];
}

- (NSString*) shapeToSVG
{
  NSMutableString* svg = [NSMutableString stringWithCapacity:100];
  [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g v -8 m 0 -32 v -8 m -8 24 c 3 -10 5 -10 8 0 c 3 10 5 10 8 0\"/>",
      [super shapeToSVG], self.position.x, self.position.y + 24.0f];
  [svg appendFormat:@"\n<circle stroke=\"black\" fill=\"none\" cx=\"%g\" cy=\"%g\" r=\"16\"/>%@",
      self.position.x, self.position.y, [super endSVG]];
  return svg;
}

@end


/*************************************************** AC+DC CURRENT SOURCE ******/
@implementation MI_CurrentSourceElement

- (instancetype) init
{
  if (self = [super init])
  {
    originalSize = size = NSMakeSize(32.0f, 48.0f);
    [self setName:@"Current Source"];
    [self setLabel:@"I"];
    [self setLabelPosition:MI_DIRECTION_RIGHT];
    MI_ConnectionPoint* anode = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(0.0f, -24.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Anode"
     nodeNumberPlacement:MI_DIRECTION_NORTHEAST];
    MI_ConnectionPoint* cathode = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(0.0f, 24.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"Cathode"
     nodeNumberPlacement:MI_DIRECTION_SOUTHEAST];
    self.connectionPoints = @{@"Anode": anode, @"Cathode": cathode};
    [parameters setObject:@"1m" forKey:@"DC_Current"];
    [parameters setObject:@"0" forKey:@"AC_Magnitude"];
    [parameters setObject:@"0" forKey:@"AC_Phase"];
  }
  return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(self.position.x, self.position.y + 24.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,  -6.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f, -20.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,  -6.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp stroke];
    // draw arrow head
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(self.position.x, self.position.y + 10.9f)];
    [bp relativeLineToPoint:NSMakePoint(3.0f, -6.0f)];
    [bp relativeLineToPoint:NSMakePoint(-6.0f, 0.0f)];
    [bp closePath];
    [bp fill];
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(self.position.x - 16.0f, self.position.y - 16.0f, 32.0f, 32.0f)] stroke];
    [super endDraw];
}

- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g v -8 m 0 -6 v -20 m 0 -6 v -8\"/>",
        [super shapeToSVG], self.position.x, self.position.y + 24.0f];
    // arrow head
    [svg appendFormat:@"\n<path stroke=\"none\" fill=\"black\" d=\"M %g %g l 3 -6 h -6 z\"/>",
        self.position.x, self.position.y + 10.9f];
    [svg appendFormat:@"\n<circle stroke=\"black\" fill=\"none\" cx=\"%g\" cy=\"%g\" r=\"16\"/>%@",
        self.position.x, self.position.y, [super endSVG]];
    return svg;
}

@end

/************************************************* PULSE CURRENT SOURCE ******/
@implementation MI_PulseCurrentSourceElement

- (instancetype) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(32.0f, 48.0f);
        [self setName:@"Pulse Current Source"];
        [self setLabel:@"IPulse"];
        [self setLabelPosition:MI_DIRECTION_RIGHT];
        MI_ConnectionPoint* anode = [[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(0.0f, -24.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Anode"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST];
        MI_ConnectionPoint* cathode = [[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(0.0f, 24.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Cathode"
         nodeNumberPlacement:MI_DIRECTION_SOUTHEAST];
        self.connectionPoints = [NSDictionary dictionaryWithObjectsAndKeys:
            anode, @"Anode", cathode, @"Cathode", NULL];
        [parameters setObject:@"0" forKey:@"Initial Value"];
        [parameters setObject:@"5" forKey:@"Pulsed Value"];
        [parameters setObject:@"0" forKey:@"Delay Time"];
        [parameters setObject:@"0" forKey:@"Rise Time"];
        [parameters setObject:@"0" forKey:@"Fall Time"];
        [parameters setObject:@"0.001" forKey:@"Pulse Width"];
        [parameters setObject:@"1" forKey:@"Period"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(self.position.x, self.position.y + 24.0f)];
    // Draw top handle
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,  -5.0f)];
    // Draw body of arrow and the pulse symbol
#ifdef standard_pulseCurrentSourceShape
    [bp relativeLineToPoint:NSMakePoint(  0.0f, -22.0f)];
    [bp relativeMoveToPoint:NSMakePoint( -5.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,   7.0f)];
    [bp relativeLineToPoint:NSMakePoint( -5.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,   8.0f)];
    [bp relativeLineToPoint:NSMakePoint(  5.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,   7.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  5.0f, -22.0f)];
#else
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -9.0f)];
    [bp relativeLineToPoint:NSMakePoint( -8.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -6.0f)];
    [bp relativeLineToPoint:NSMakePoint(  8.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -6.0f)];    
#endif
    // Draw bottom handle
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,  -6.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp stroke];
    // draw arrow head
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(self.position.x, self.position.y + 12.9f)];
    [bp relativeLineToPoint:NSMakePoint(3.0f, -6.0f)];
    [bp relativeLineToPoint:NSMakePoint(-6.0f, 0.0f)];
    [bp closePath];
    [bp fill];
    [[NSBezierPath bezierPathWithOvalInRect:
        NSMakeRect(self.position.x - 16.0f, self.position.y - 16.0f, 32.0f, 32.0f)] stroke];
    [super endDraw];
}

- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g v -8 m 0 -5 v -9 h -8 v -6 h 8 v -6 m 0 -6 v -8\"/>",
        [super shapeToSVG], self.position.x, self.position.y + 24.0f];
    // arrow head
    [svg appendFormat:@"\n<path stroke=\"none\" fill=\"black\" d=\"M %g %g l 3 -6 h -6 z\"/>",
        self.position.x, self.position.y + 12.9f];
    [svg appendFormat:@"\n<circle stroke=\"black\" fill=\"none\" cx=\"%g\" cy=\"%g\" r=\"16\"/>%@",
        self.position.x, self.position.y, [super endSVG]];
    return svg;
}

@end

/************************************************* VOLTAGE-CONTROLLED CURRENT SOURCE ******/
@implementation MI_VoltageControlledCurrentSource

- (instancetype) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(36.0f, 48.0f);
        [self setName:@"Voltage-Controlled Current Source"];
        [self setLabel:@"G"];
        [self setLabelPosition:MI_DIRECTION_RIGHT];
        MI_ConnectionPoint* np = [[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(2.0f, 24.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"N+"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST];
        MI_ConnectionPoint* nm = [[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(2.0f, -24.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"N-"
         nodeNumberPlacement:MI_DIRECTION_SOUTHEAST];
        MI_ConnectionPoint* ncp = [[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-18.0f, 8.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"NC+"
         nodeNumberPlacement:MI_DIRECTION_NORTHWEST];
        MI_ConnectionPoint* ncm = [[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-18.0f, -8.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"NC-"
         nodeNumberPlacement:MI_DIRECTION_SOUTHWEST];
        self.connectionPoints = [NSDictionary dictionaryWithObjectsAndKeys:
            np, @"N+", nm, @"N-", ncp, @"NC+", ncm, @"NC-", NULL];
        [parameters setObject:@"0.5" forKey:@"Transconductance"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(self.position.x + 2.0f, self.position.y + 24.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,  -6.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f, -20.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,  -6.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    // Draw the voltage-control connector hooks
    [bp relativeMoveToPoint:NSMakePoint( -13.86f, 16.0f)]; // (-13.86, -8) on the circle
    [bp relativeLineToPoint:NSMakePoint(  -6.14f, 0.0f)]; // (-20, -8)
    [bp relativeMoveToPoint:NSMakePoint(   0.0f, 16.0f)];  // (-20, 8)
    [bp relativeLineToPoint:NSMakePoint(   6.14f, 0.0f)]; // (-13.86, 8) on the circle
    [bp relativeMoveToPoint:NSMakePoint(  -5.14f, 4.5f)];
    [bp relativeLineToPoint:NSMakePoint(   5.0f,  0.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  -2.5f,  2.5f)];
    [bp relativeLineToPoint:NSMakePoint(   0.0f, -5.0f)];
    [bp stroke];
    // draw arrow head
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(self.position.x + 2.0f, self.position.y + 10.9f)];
    [bp relativeLineToPoint:NSMakePoint(3.0f, -6.0f)];
    [bp relativeLineToPoint:NSMakePoint(-6.0f, 0.0f)];
    [bp closePath];
    [bp fill];
    [[NSBezierPath bezierPathWithOvalInRect:
        NSMakeRect(self.position.x - 14.0f, self.position.y - 16.0f, 32.0f, 32.0f)] stroke];
    [super endDraw];
}

- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g v -8 m 0 -6 v -20 m 0 -6 v -8 m -13.86 16 h -6.14 m 0 16 h 6.14 m -5.14 4.5 h 5 m -2.5 2.5 v -5\"/>",
        [super shapeToSVG], self.position.x + 2.0f, self.position.y + 24.0f];
    // arrow head
    [svg appendFormat:@"\n<path stroke=\"none\" fill=\"black\" d=\"M %g %g l 3 -6 h -6 z\"/>",
        self.position.x + 2.0f, self.position.y + 10.9f];
    [svg appendFormat:@"\n<circle stroke=\"black\" fill=\"none\" cx=\"%g\" cy=\"%g\" r=\"16\"/>%@",
        self.position.x + 2.0f, self.position.y, [super endSVG]];
    return svg;
}

@end

/************************************************* VOLTAGE-CONTROLLED VOLTAGE SOURCE ******/
@implementation MI_VoltageControlledVoltageSource

- (instancetype) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(36.0f, 48.0f);
        [self setName:@"Voltage-Controlled Voltage Source"];
        [self setLabel:@"E"];
        [self setLabelPosition:MI_DIRECTION_RIGHT];
        MI_ConnectionPoint* np = [[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(2.0f, 24.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"N+"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST];
        MI_ConnectionPoint* nm = [[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(2.0f, -24.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"N-"
         nodeNumberPlacement:MI_DIRECTION_SOUTHEAST];
        MI_ConnectionPoint* ncp = [[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-18.0f, 8.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"NC+"
         nodeNumberPlacement:MI_DIRECTION_NORTHWEST];
        MI_ConnectionPoint* ncm = [[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-18.0f, -8.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"NC-"
         nodeNumberPlacement:MI_DIRECTION_SOUTHWEST];
        self.connectionPoints = [NSDictionary dictionaryWithObjectsAndKeys:
            np, @"N+", nm, @"N-", ncp, @"NC+", ncm, @"NC-", NULL];
        [parameters setObject:@"0.5" forKey:@"Gain"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(self.position.x + 2.0f, self.position.y + 24.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)]; // ( 0, 16)
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,  -6.0f)]; // ( 0, 10)
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)]; // ( 0, 2)
    [bp relativeMoveToPoint:NSMakePoint(  0.0f, -18.0f)]; // ( 0, -16)
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)]; // ( 0, -24)
    [bp relativeMoveToPoint:NSMakePoint( -4.0f, +30.0f)]; // (-4, 6)
    [bp relativeLineToPoint:NSMakePoint(  8.0f,   0.0f)]; // ( 4, 6)
    [bp relativeMoveToPoint:NSMakePoint(  0.0f, -14.0f)]; // ( 4, -8)
    [bp relativeLineToPoint:NSMakePoint( -8.0f,   0.0f)]; // (-4, -8)
    // Draw the voltage-control connector hooks
    [bp relativeMoveToPoint:NSMakePoint( -9.86f, 0.0f)]; // (-13.86, -8) on the circle
    [bp relativeLineToPoint:NSMakePoint( -6.14f, 0.0f)]; // (-16, -8)
    [bp relativeMoveToPoint:NSMakePoint( 0.0f, 16.0f)];  // (-16, 8)
    [bp relativeLineToPoint:NSMakePoint( 6.14f, 0.0f)]; // (-13.86, 8) on the circle
    [bp relativeMoveToPoint:NSMakePoint(  -5.14f, 4.5f)];
    [bp relativeLineToPoint:NSMakePoint(   5.0f,  0.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  -2.5f,  2.5f)];
    [bp relativeLineToPoint:NSMakePoint(   0.0f, -5.0f)];
    [bp stroke];
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(self.position.x - 14.0f, self.position.y - 16.0f, 32.0f, 32.0f)] stroke];
    [super endDraw];
}

- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g v -8 m 0 -6 v -8 m 0 -18 v -8 m -4 30 h 8 m 0 -14 h -8 m -9.86 0 h -6.14 m 0 16 h 6.14 m -5.14 4.5 h 5 m -2.5 2.5 v -5\"/>",
        [super shapeToSVG], self.position.x + 2.0f, self.position.y + 24.0f];
    [svg appendFormat:@"\n<circle stroke=\"black\" fill=\"none\" cx=\"%g\" cy=\"%g\" r=\"16\"/>%@",
        self.position.x + 2.0f, self.position.y, [super endSVG]];
    return svg;
}

@end

/***************************************** CURRENT-CONTROLLED CURRENT SOURCE ******/
@implementation MI_CurrentControlledCurrentSource

- (instancetype) init
{
  if (self = [super init])
  {
    originalSize = size = NSMakeSize(32.0f, 48.0f);
    [self setName:@"Current-Controlled Current Source"];
    [self setLabel:@"F"];
    [self setLabelPosition:MI_DIRECTION_RIGHT];
    MI_ConnectionPoint* anode = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(0.0f, -24.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"N+"
     nodeNumberPlacement:MI_DIRECTION_NORTHEAST];
    MI_ConnectionPoint* cathode = [[MI_ConnectionPoint alloc]
        initWithPosition:NSMakePoint(0.0f, 24.0f)
                    size:NSMakeSize(6.0f, 6.0f)
                    name:@"N-"
     nodeNumberPlacement:MI_DIRECTION_SOUTHEAST];
    self.connectionPoints = @{@"N+": anode, @"N-": cathode};
    [parameters setObject:@"0.5" forKey:@"Gain"];
    [parameters setObject:@""    forKey:@"VNAM"];
  }
  return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(self.position.x, self.position.y + 24.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,  -6.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f, -20.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,  -6.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-14.0f,   1.0f)];
    [bp relativeLineToPoint:NSMakePoint( 28.0f,  46.0f)];
    [bp stroke];
    // draw arrow head of current direction inside the circle
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(self.position.x, self.position.y + 10.9f)];
    [bp relativeLineToPoint:NSMakePoint(3.0f, -6.0f)];
    [bp relativeLineToPoint:NSMakePoint(-6.0f, 0.0f)];
    [bp closePath];
    [bp fill];
    // draw the circle
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(self.position.x - 16.0f, self.position.y - 16.0f, 32.0f, 32.0f)] stroke];
    // Draw the arrow head of the diagonal line
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(self.position.x + 7.0f, self.position.y + 18.0f)];
    [bp relativeLineToPoint:NSMakePoint(8.0f, 6.0f)];
    [bp relativeLineToPoint:NSMakePoint(-1.8f, -9.5f)];
    [bp closePath];
    [bp fill];
    [super endDraw];
}

- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g v -8 m 0 -6 v -20 m 0 -6 v -8 m -14 1 l 28 46\"/>",
        [super shapeToSVG], self.position.x, self.position.y + 24.0f];
    // arrow head of current direction inside the circle
    [svg appendFormat:@"\n<path stroke=\"none\" fill=\"black\" d=\"M %g %g l 3 -6 h -6 z\"/>",
        self.position.x, self.position.y + 10.9f];
    // arrow head of diagonal line
    [svg appendFormat:@"\n<path stroke=\"none\" fill=\"black\" d=\"M %g %g l 8 6 l -1.8 -9.5 z\"/>",
        self.position.x + 7.0f, self.position.y + 18.0f];
    [svg appendFormat:@"\n<circle stroke=\"black\" fill=\"none\" cx=\"%g\" cy=\"%g\" r=\"16\"/>%@",
        self.position.x, self.position.y, [super endSVG]];
    return svg;
}

@end

/**************************************** CURRENT-CONTROLLED VOLTAGE SOURCE ******/
@implementation MI_CurrentControlledVoltageSource

- (instancetype) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(32.0f, 48.0f);
        [self setName:@"Current-Controlled Voltage Source"];
        [self setLabel:@"H"];
        [self setLabelPosition:MI_DIRECTION_RIGHT];
        MI_ConnectionPoint* anode = [[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(0.0f, -24.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"N+"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST];
        MI_ConnectionPoint* cathode = [[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(0.0f, 24.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"N-"
         nodeNumberPlacement:MI_DIRECTION_SOUTHEAST];
        self.connectionPoints = [NSDictionary dictionaryWithObjectsAndKeys:
            anode, @"N+", cathode, @"N-", NULL];
        [parameters setObject:@"0.5" forKey:@"Transresistance"];
        [parameters setObject:@""    forKey:@"VNAM"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(self.position.x, self.position.y + 24.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,  -6.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f, -18.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp relativeMoveToPoint:NSMakePoint( -4.0f, +30.0f)];
    [bp relativeLineToPoint:NSMakePoint(  8.0f,   0.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f, -14.0f)];
    [bp relativeLineToPoint:NSMakePoint( -8.0f,   0.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-10.0f, -15.0f)];
    [bp relativeLineToPoint:NSMakePoint( 28.0f,  46.0f)];
    [bp stroke];
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(self.position.x - 16.0f, self.position.y - 16.0f, 32.0f, 32.0f)] stroke];
    // Draw the arrow head of the diagonal line
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(self.position.x + 7.0f, self.position.y + 18.0f)];
    [bp relativeLineToPoint:NSMakePoint(8.0f, 6.0f)];
    [bp relativeLineToPoint:NSMakePoint(-1.8f, -9.5f)];
    [bp closePath];
    [bp fill];
    [super endDraw];
}

- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g v -8 m 0 -6 v -8 m 0 -18 v -8 m -4 30 h 8 m 0 -14 h -8 m -10 -15 l 28 46\"/>",
        [super shapeToSVG], self.position.x, self.position.y + 24.0f];
    // arrow head of diagonal line
    [svg appendFormat:@"\n<path stroke=\"none\" fill=\"black\" d=\"M %g %g l 8 6 l -1.8 -9.5 z\"/>",
        self.position.x + 7.0f, self.position.y + 18.0f];
    [svg appendFormat:@"\n<circle stroke=\"black\" fill=\"none\" cx=\"%g\" cy=\"%g\" r=\"16\"/>%@",
        self.position.x, self.position.y, [super endSVG]];
    return svg;
}

@end

/****************************** NONLINEAR DEPENDENT POWER SOURCE **********/
@implementation MI_NonlinearDependentSource

- (instancetype) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(32.0f, 48.0f);
        [self setName:@"Nonlinear Dependent Power Source"];
        [self setLabel:@"B"];
        [self setLabelPosition:MI_DIRECTION_RIGHT];
        MI_ConnectionPoint* anode = [[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(0.0f, 24.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"N+"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST];
        MI_ConnectionPoint* cathode = [[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(0.0f, -24.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"N-"
         nodeNumberPlacement:MI_DIRECTION_SOUTHEAST];
        self.connectionPoints = [NSDictionary dictionaryWithObjectsAndKeys:
            anode, @"N+", cathode, @"N-", NULL];
        [parameters setObject:@"V=1+V(0)" forKey:@"Expression"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(self.position.x, self.position.y + 24.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,  -6.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f, -18.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp relativeMoveToPoint:NSMakePoint( -4.0f, +30.0f)];
    [bp relativeLineToPoint:NSMakePoint(  8.0f,   0.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f, -14.0f)];
    [bp relativeLineToPoint:NSMakePoint( -8.0f,   0.0f)];
    [bp stroke];
    [NSBezierPath strokeRect:NSMakeRect(self.position.x - 16.0f, self.position.y - 16.0f, 32.0f, 32.0f)];
    [super endDraw];
}

- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g v -8 m 0 -6 v -8 m 0 -18 v -8 m -4 30 h 8 m 0 -14 h -8\"/>",
        [super shapeToSVG], self.position.x, self.position.y + 24.0f];
    [svg appendFormat:@"\n<rect stroke=\"black\" fill=\"none\" x=\"%g\" y=\"%g\" width=\"32\" height=\"32\"/>%@",
        self.position.x - 16.0f, self.position.y - 16.0f, [super endSVG]];
    return svg;
}

@end


