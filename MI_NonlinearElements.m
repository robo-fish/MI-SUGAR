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
#import "MI_NonlinearElements.h"
#import "MI_ConnectionPoint.h"


/************************************************** DIODE ********************/

@implementation MI_DiodeElement

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(32.0f, 14.0f);
        [self setName:@"Diode"];
        [self setLabel:@"D"];
        [self setLabelPosition:MI_DIRECTION_UP];
        MI_ConnectionPoint* anode = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-16.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Anode"
         nodeNumberPlacement:MI_DIRECTION_NORTHWEST] autorelease];
        MI_ConnectionPoint* cathode = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Cathode"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            anode, @"Anode", cathode, @"Cathode", NULL] retain];
        [parameters setObject:@"DefaultDiode" forKey:@"Model"];
        [parameters setObject:@"1.0" forKey:@"Area Factor"];
        [parameters setObject:@"OFF" forKey:@"DC Initial State"];
        [parameters setObject:@"27" forKey:@"Op. Temperature"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(position.x - 16.0f, position.y)];
    [bp relativeLineToPoint:NSMakePoint( 10.0f,  0.0f)];
    // triangle
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  6.0f)];
    [bp relativeLineToPoint:NSMakePoint( 12.0f, -6.0f)];
    [bp relativeLineToPoint:NSMakePoint(-12.0f, -6.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  6.0f)];
    //
    [bp relativeMoveToPoint:NSMakePoint( 12.0f,  0.0f)];
    [bp relativeLineToPoint:NSMakePoint( 10.0f,  0.0f)];
    // vertical line
    [bp relativeMoveToPoint:NSMakePoint(-10.0f, -7.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f, 14.0f)];
    [bp stroke];
    [super endDraw];
}


- (MI_DeviceModelType) usedDeviceModelType
{
    return DIODE_DEVICE_MODEL_TYPE;
}

- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 10 m 12 0 h 10 m -10 -7 v 14\"/>",
        [super shapeToSVG], position.x - 16.0f, position.y];
    [svg appendFormat:@"\n<path stroke=\"black\" fill=\"none\" d=\"M %g %g v 12 l 12 -6 z\"/>%@",
        position.x - 6.0f, position.y -6.0f, [super endSVG]];
    return svg;
}

@end


/************************************************** ZENER DIODE **************/

@implementation MI_ZenerDiodeElement

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(32.0f, 16.0f);
        [self setName:@"Zener Diode"];
        [self setLabel:@"D"];
        [self setLabelPosition:MI_DIRECTION_UP];
        MI_ConnectionPoint* anode = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-16.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Anode"
         nodeNumberPlacement:MI_DIRECTION_NORTHWEST] autorelease];
        MI_ConnectionPoint* cathode = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Cathode"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            anode, @"Anode", cathode, @"Cathode", NULL] retain];
        [parameters setObject:@"DefaultDiode" forKey:@"Model"];
        [parameters setObject:@"1.0" forKey:@"Area Factor"];
        [parameters setObject:@"OFF" forKey:@"DC Initial State"];
        [parameters setObject:@"27" forKey:@"Op. Temperature"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(position.x - 16.0f, position.y)];
    [bp relativeLineToPoint:NSMakePoint( 10.0f,  0.0f)];
    // triangle
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  6.0f)];
    [bp relativeLineToPoint:NSMakePoint( 12.0f, -6.0f)];
    [bp relativeLineToPoint:NSMakePoint(-12.0f, -6.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  6.0f)];
    [bp relativeMoveToPoint:NSMakePoint( 12.0f,  0.0f)];
    [bp relativeLineToPoint:NSMakePoint( 10.0f,  0.0f)];
    // vertical line and zener markings
    [bp relativeMoveToPoint:NSMakePoint(-13.0f, -8.0f)];
    [bp relativeLineToPoint:NSMakePoint(  4.0f,  0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f, 16.0f)];
    [bp relativeLineToPoint:NSMakePoint(  4.0f,  0.0f)];
    [bp stroke];
    [super endDraw];
}


- (MI_DeviceModelType) usedDeviceModelType
{
    return DIODE_DEVICE_MODEL_TYPE;
}

- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 10 m 12 0 h 10 m -13 -8 h 4 v 16 h 4\"/>",
        [super shapeToSVG], position.x - 16.0f, position.y];
    [svg appendFormat:@"\n<path stroke=\"black\" fill=\"none\" d=\"M %g %g v 12 l 12 -6 z\"/>%@",
        position.x - 6.0f, position.y -6.0f, [super endSVG]];
    return svg;
}

@end

/**************************************** LIGHT EMITTING DIODE **************/

@implementation MI_LightEmittingDiodeElement

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(32.0f, 24.0f);
        [self setName:@"Light Emitting Diode"];
        [self setLabel:@"LED"];
        [self setLabelPosition:MI_DIRECTION_DOWN];
        MI_ConnectionPoint* anode = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-16.0f, -6.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Anode"
         nodeNumberPlacement:MI_DIRECTION_NORTHWEST] autorelease];
        MI_ConnectionPoint* cathode = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, -6.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Cathode"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            anode, @"Anode", cathode, @"Cathode", NULL] retain];
        [parameters setObject:@"DefaultDiode" forKey:@"Model"];
        [parameters setObject:@"1.0" forKey:@"Area Factor"];
        [parameters setObject:@"OFF" forKey:@"DC Initial State"];
        [parameters setObject:@"27" forKey:@"Op. Temperature"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(position.x - 16.0f, position.y - 6.0f)];
    [bp relativeLineToPoint:NSMakePoint( 10.0f,  0.0f)];
    // triangle
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  6.0f)];
    [bp relativeLineToPoint:NSMakePoint( 12.0f, -6.0f)];
    [bp relativeLineToPoint:NSMakePoint(-12.0f, -6.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  6.0f)];
    //
    [bp relativeMoveToPoint:NSMakePoint( 12.0f,  0.0f)];
    [bp relativeLineToPoint:NSMakePoint( 10.0f,  0.0f)];
    // vertical line
    [bp relativeMoveToPoint:NSMakePoint(-10.0f, -6.5f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f, 13.0f)];
    [bp relativeMoveToPoint:NSMakePoint( -6.0f,  1.0f)];
    // light rays
    [bp relativeLineToPoint:NSMakePoint(  3.0f,  6.75f)];
    [bp relativeMoveToPoint:NSMakePoint(  4.0f, -6.75f)];
    [bp relativeLineToPoint:NSMakePoint(  3.0f,  6.75f)];
    [bp stroke];
    // Draw arrow heads
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(position.x + 5.0f, position.y + 12.0f)];
    [bp relativeLineToPoint:NSMakePoint(0.0f, -6.0f)];
    [bp relativeLineToPoint:NSMakePoint(-5.0f, 2.0f)];
    [bp closePath];
    [bp fill];
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(position.x + 12.0f, position.y + 12.0f)];
    [bp relativeLineToPoint:NSMakePoint(0.0f, -6.0f)];
    [bp relativeLineToPoint:NSMakePoint(-5.0f, 2.0f)];
    [bp closePath];
    [bp fill];
    [super endDraw];
}


- (MI_DeviceModelType) usedDeviceModelType
{
    return DIODE_DEVICE_MODEL_TYPE;
}


- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 10 m 12 0 h 10 m -10 -6.5 v 13 m -6 1 l 3 6.75 m 4 -6.75 l 3 6.75\"/>",
        [super shapeToSVG], position.x - 16.0f, position.y - 6.0f];
    // triangle
    [svg appendFormat:@"\n<path stroke=\"black\" fill=\"none\" d=\"M %g %g v 12 l 12 -6 z\"/>",
        position.x - 6.0f, position.y - 12.0f];
    // arrow head 1
    [svg appendFormat:@"\n<path stroke=\"none\" fill=\"black\" d=\"M %g %g v -6 l -5 2 z\"/>",
        position.x + 5.0f, position.y + 12.0f];
    // arrow head 2
    [svg appendFormat:@"\n<path stroke=\"none\" fill=\"black\" d=\"M %g %g v -6 l -5 2 z\"/>%@",
        position.x + 12.0f, position.y + 12.0f, [super endSVG]];
    return svg;
}

@end

/************************************************** PHOTO DIODE **************/

@implementation MI_PhotoDiodeElement

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(32.0f, 24.0f);
        [self setName:@"Photo Diode"];
        [self setLabel:@"D"];
        [self setLabelPosition:MI_DIRECTION_DOWN];
        MI_ConnectionPoint* anode = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-16.0f, -6.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Anode"
         nodeNumberPlacement:MI_DIRECTION_NORTHWEST] autorelease];
        MI_ConnectionPoint* cathode = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, -6.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Cathode"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            anode, @"Anode", cathode, @"Cathode", NULL] retain];
        [parameters setObject:@"DefaultDiode" forKey:@"Model"];
        [parameters setObject:@"1.0" forKey:@"Area Factor"];
        [parameters setObject:@"OFF" forKey:@"DC Initial State"];
        [parameters setObject:@"27" forKey:@"Op. Temperature"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(position.x - 16.0f, position.y - 6.0f)];
    [bp relativeLineToPoint:NSMakePoint( 10.0f,  0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  6.0f)];
    [bp relativeLineToPoint:NSMakePoint( 12.0f, -6.0f)];
    [bp relativeLineToPoint:NSMakePoint(-12.0f, -6.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  6.0f)];
    [bp relativeMoveToPoint:NSMakePoint( 12.0f,  0.0f)];
    [bp relativeLineToPoint:NSMakePoint( 10.0f,  0.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-10.0f, -6.5f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f, 13.0f)];
    [bp relativeMoveToPoint:NSMakePoint( -5.0f,  5.25f)];
    [bp relativeLineToPoint:NSMakePoint(  3.0f,  6.75f)];
    [bp relativeMoveToPoint:NSMakePoint(  4.0f, -6.75f)];
    [bp relativeLineToPoint:NSMakePoint(  3.0f,  6.75f)];
    [bp stroke];
    // Draw arrow heads
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(position.x - 0.8f, position.y + 2.0f)];
    [bp relativeLineToPoint:NSMakePoint( 0.0f,  6.0f)];
    [bp relativeLineToPoint:NSMakePoint( 5.0f, -2.0f)];
    [bp closePath];
    [bp fill];
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(position.x + 6.0f, position.y + 2.0f)];
    [bp relativeLineToPoint:NSMakePoint( 0.0f,  6.0f)];
    [bp relativeLineToPoint:NSMakePoint( 5.0f, -2.0f)];
    [bp closePath];
    [bp fill];
    [super endDraw];
}


- (MI_DeviceModelType) usedDeviceModelType
{
    return DIODE_DEVICE_MODEL_TYPE;
}


- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 10 m 12 0 h 10 m -10 -6.5 v 13 m -5 5.25 l 3 6.75 m 4 -6.75 l 3 6.75\"/>",
        [super shapeToSVG], position.x - 16.0f, position.y - 6.0f];
    // triangle
    [svg appendFormat:@"\n<path stroke=\"black\" fill=\"none\" d=\"M %g %g v 12 l 12 -6 z\"/>",
        position.x - 6.0f, position.y - 12.0f];
    // arrow head 1
    [svg appendFormat:@"\n<path stroke=\"none\" fill=\"black\" d=\"M %g %g v 6 l 5 -2 z\"/>",
        position.x - 0.8f, position.y + 2.0f];
    // arrow head 2
    [svg appendFormat:@"\n<path stroke=\"none\" fill=\"black\" d=\"M %g %g v 6 l 5 -2 z\"/>%@",
        position.x + 6.0f, position.y + 2.0f, [super endSVG]];
    return svg;
}

@end

/**************************************** BJT (NPN) TRANSISTOR **************/

@implementation MI_NPNTransistorElement

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(32.0f, 32.0f);
        [self setName:@"BJT (NPN)"];
        [self setLabel:@"NPN"];
        [self setLabelPosition:MI_DIRECTION_RIGHT];
        MI_ConnectionPoint* base = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-16.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Base"
         nodeNumberPlacement:MI_DIRECTION_NORTHWEST] autorelease];
        MI_ConnectionPoint* collector = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, 16.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Collector"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        MI_ConnectionPoint* emitter = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, -16.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Emitter"
         nodeNumberPlacement:MI_DIRECTION_SOUTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            base, @"Base", collector, @"Collector", emitter, @"Emitter", NULL] retain];
        [parameters setObject:@"DefaultBJT" forKey:@"Model"];
        [parameters setObject:@"1.0" forKey:@"Area Factor"];
        [parameters setObject:@"OFF" forKey:@"DC Initial State"];
        [parameters setObject:@"27" forKey:@"Op. Temperature"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(position.x - 16.0f, position.y)]; // ( 0, 16)
    [bp relativeLineToPoint:NSMakePoint( 16.0f,   0.0f)]; // (16, 16)
    [bp relativeMoveToPoint:NSMakePoint(  0.0f, -12.0f)]; // (16,  4)
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  24.0f)]; // (16, 28)
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,  -6.0f)]; // (16, 22)
    [bp relativeLineToPoint:NSMakePoint( 16.0f,   6.0f)]; // (32, 28)
    [bp relativeLineToPoint:NSMakePoint(  0.0f,   4.0f)]; // (32, 32)
    [bp relativeMoveToPoint:NSMakePoint(-16.0f, -22.0f)]; // (16, 10)
    [bp relativeLineToPoint:NSMakePoint( 16.0f,  -6.0f)]; // (32,  4)
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -4.0f)]; // (32,  0)
    [bp stroke];
    // draw the channel-type indicating arrow
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(position.x + 10.0f, position.y - 6.0f)]; // (26, 10)
    [bp relativeLineToPoint:NSMakePoint( 6.0f, -6.0f)]; // (32, 4)
    [bp relativeLineToPoint:NSMakePoint(-8.0f,  0.0f)]; // (24, 3)
    [bp closePath];
    [bp fill];
    [super endDraw];
}


- (MI_DeviceModelType) usedDeviceModelType
{
    return BJT_DEVICE_MODEL_TYPE;
}


- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 16 m 0 -12 v 24 m 0 -6 l 16 6 v 4 m -16 -22 l 16 -6 v -4\"/>",
        [super shapeToSVG], position.x - 16.0f, position.y];
    // draw the channel-type indicating arrow
    [svg appendFormat:@"\n<path stroke=\"none\" fill=\"black\" d=\"M %g %g l 6 -6 h -8 z\"/>%@",
        position.x + 10.0f, position.y - 6.0f, [super endSVG]];
    return svg;
}    

@end

/**************************************** BJT (PNP) TRANSISTOR **************/

@implementation MI_PNPTransistorElement

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(32.0f, 32.0f);
        [self setName:@"BJT (PNP)"];
        [self setLabel:@"PNP"];
        [self setLabelPosition:MI_DIRECTION_RIGHT];
        MI_ConnectionPoint* base = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-16.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Base"
         nodeNumberPlacement:MI_DIRECTION_NORTHWEST] autorelease];
        MI_ConnectionPoint* collector = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, 16.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Collector"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        MI_ConnectionPoint* emitter = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, -16.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Emitter"
         nodeNumberPlacement:MI_DIRECTION_SOUTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            base, @"Base", collector, @"Collector", emitter, @"Emitter", NULL] retain];
        [parameters setObject:@"DefaultBJT" forKey:@"Model"];
        [parameters setObject:@"1.0" forKey:@"Area Factor"];
        [parameters setObject:@"OFF" forKey:@"DC Initial State"];
        [parameters setObject:@"27" forKey:@"Op. Temperature"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(position.x - 16.0f, position.y - 16.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,  16.0f)]; 
    [bp relativeLineToPoint:NSMakePoint( 16.0f,   0.0f)]; 
    [bp relativeMoveToPoint:NSMakePoint(  0.0f, -12.0f)]; 
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  24.0f)]; 
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,  -6.0f)]; 
    [bp relativeLineToPoint:NSMakePoint( 16.0f,   6.0f)]; 
    [bp relativeLineToPoint:NSMakePoint(  0.0f,   4.0f)]; 
    [bp relativeMoveToPoint:NSMakePoint(-16.0f, -22.0f)]; 
    [bp relativeLineToPoint:NSMakePoint( 16.0f,  -6.0f)]; 
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -4.0f)]; 
    [bp stroke];
    // draw the small arrow
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(position.x, position.y - 6.0f)]; 
    [bp relativeLineToPoint:NSMakePoint( 8.0f,  0.0f)];
    [bp relativeLineToPoint:NSMakePoint(-2.0f, -6.0f)];
    [bp closePath];
    [bp fill];
    [super endDraw];
}


- (MI_DeviceModelType) usedDeviceModelType
{
    return BJT_DEVICE_MODEL_TYPE;
}


- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 16 m 0 -12 v 24 m 0 -6 l 16 6 v 4 m -16 -22 l 16 -6 v -4\"/>",
        [super shapeToSVG], position.x - 16.0f, position.y];
    // draw the channel-type indicating arrow
    [svg appendFormat:@"\n<path stroke=\"none\" fill=\"black\" d=\"M %g %g h 8 l -2 -6 z\"/>%@",
        position.x, position.y - 6.0f, [super endSVG]];
    return svg;
}    

@end

/**************************************** NJFET TRANSISTOR **************/

@implementation MI_NJFETTransistorElement

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(32.0f, 32.0f);
        [self setName:@"JFET, N-Channel"];
        [self setLabel:@"NJF"];
        [self setLabelPosition:MI_DIRECTION_RIGHT];
        MI_ConnectionPoint* gate = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-16.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Gate"
         nodeNumberPlacement:MI_DIRECTION_NORTHWEST] autorelease];
        MI_ConnectionPoint* drain = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, 16.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Drain"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        MI_ConnectionPoint* source = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, -16.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Source"
         nodeNumberPlacement:MI_DIRECTION_SOUTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            gate, @"Gate", drain, @"Drain", source, @"Source", NULL] retain];
        [parameters setObject:@"DefaultJFET" forKey:@"Model"];
        [parameters setObject:@"1.0" forKey:@"Area Factor"];
        [parameters setObject:@"OFF" forKey:@"DC Initial State"];
        [parameters setObject:@"27" forKey:@"Op. Temperature"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(position.x - 16.0f, position.y)];
    [bp relativeLineToPoint:NSMakePoint( 16.0f,   0.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f, -12.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  24.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,  -4.0f)];
    [bp relativeLineToPoint:NSMakePoint( 16.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,   8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-16.0f, -24.0f)];
    [bp relativeLineToPoint:NSMakePoint( 16.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp stroke];
    // draw arrow
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(position.x - 4.0f, position.y)];
    [bp relativeLineToPoint:NSMakePoint( -6.5f,  3.5f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f, -7.0f)];
    [bp closePath];
    [bp fill];
    [super endDraw];
}


- (MI_DeviceModelType) usedDeviceModelType
{
    return JFET_DEVICE_MODEL_TYPE;
}


- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 16 m 0 -12 v 24 m 0 -4 h 16 v 8 m -16 -24 h 16 v -8\"/>",
        [super shapeToSVG], position.x - 16.0f, position.y];
    // draw the channel-type indicating arrow
    [svg appendFormat:@"\n<path stroke=\"none\" fill=\"black\" d=\"M %g %g l -6.5 3.5 v -7 z\"/>%@",
        position.x - 4.0f, position.y, [super endSVG]];
    return svg;
}    

@end

/**************************************** PJFET TRANSISTOR **************/

@implementation MI_PJFETTransistorElement

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(32.0f, 32.0f);
        [self setName:@"JFET, P-Channel"];
        [self setLabel:@"PJF"];
        [self setLabelPosition:MI_DIRECTION_RIGHT];
        MI_ConnectionPoint* gate = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-16.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Gate"
         nodeNumberPlacement:MI_DIRECTION_NORTHWEST] autorelease];
        MI_ConnectionPoint* drain = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, 16.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Drain"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        MI_ConnectionPoint* source = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, -16.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Source"
         nodeNumberPlacement:MI_DIRECTION_SOUTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            gate, @"Gate", drain, @"Drain", source, @"Source", NULL] retain];
        [parameters setObject:@"DefaultJFET" forKey:@"Model"];
        [parameters setObject:@"1.0" forKey:@"Area Factor"];
        [parameters setObject:@"OFF" forKey:@"DC Initial State"];
        [parameters setObject:@"27" forKey:@"Op. Temperature"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(position.x - 16.0f, position.y)];
    [bp relativeLineToPoint:NSMakePoint( 16.0f,   0.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f, -12.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  24.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,  -4.0f)];
    [bp relativeLineToPoint:NSMakePoint( 16.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,   8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-16.0f, -24.0f)];
    [bp relativeLineToPoint:NSMakePoint( 16.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp stroke];
    // draw arrow
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(position.x - 11.0f, position.y)];
    [bp relativeLineToPoint:NSMakePoint( 6.5f,  3.5f)];
    [bp relativeLineToPoint:NSMakePoint( 0.0f, -7.0f)];
    [bp closePath];
    [bp fill];
    [super endDraw];
}


- (MI_DeviceModelType) usedDeviceModelType
{
    return JFET_DEVICE_MODEL_TYPE;
}

- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 16 m 0 -12 v 24 m 0 -4 h 16 v 8 m -16 -24 h 16 v -8\"/>",
        [super shapeToSVG], position.x - 16.0f, position.y];
    // draw the channel-type indicating arrow
    [svg appendFormat:@"\n<path stroke=\"none\" fill=\"black\" d=\"M %g %g l 6.5 3.5 v -7 z\"/>%@",
        position.x - 11.0f, position.y, [super endSVG]];
    return svg;
}    

@end

/**************************************** N-CHANNEL DEPLETION MOSFET TRANSISTOR ***********/

@implementation MI_DepletionNMOSTransistorElement

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(32.0f, 32.0f);
        [self setName:@"MOSFET, N-Channel, Depletion"];
        [self setLabel:@"NMOS"];
        [self setLabelPosition:MI_DIRECTION_RIGHT];
        MI_ConnectionPoint* gate = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-16.0f, -11.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Gate"
         nodeNumberPlacement:MI_DIRECTION_SOUTHWEST] autorelease];
        MI_ConnectionPoint* drain = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, 16.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Drain"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        MI_ConnectionPoint* source = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, -16.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Source"
         nodeNumberPlacement:MI_DIRECTION_SOUTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            gate, @"Gate", drain, @"Drain", source, @"Source", NULL] retain];
        [parameters setObject:@"DefaultMOSFET" forKey:@"Model"];
        [parameters setObject:@"5u" forKey:@"W"];
        [parameters setObject:@"10u" forKey:@"L"];
        [parameters setObject:@"100p" forKey:@"AD"];
        [parameters setObject:@"100p" forKey:@"AS"];
        [parameters setObject:@"40u" forKey:@"PD"];
        [parameters setObject:@"40u" forKey:@"PS"];
        [parameters setObject:@"1" forKey:@"NRD"];
        [parameters setObject:@"1" forKey:@"NRS"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(position.x - 16.0f, position.y - 11.0f)];
    [bp relativeLineToPoint:NSMakePoint( 16.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  22.0f)];
    [NSBezierPath fillRect:NSMakeRect(position.x + 3.0f, position.y - 12.0f, 2.0f, 24.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  4.0f,  -3.0f)];
    [bp relativeLineToPoint:NSMakePoint( 12.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,   8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-12.0f, -16.0f)];
    [bp relativeLineToPoint:NSMakePoint( 12.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f, -16.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-12.0f,   8.0f)];
    [bp relativeLineToPoint:NSMakePoint( 12.0f,   0.0f)];
    [bp stroke];
    // draw arrow
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(position.x + 5.0f, position.y)];
    [bp relativeLineToPoint:NSMakePoint( 6.0f,  3.0f)];
    [bp relativeLineToPoint:NSMakePoint( 0.0f, -6.0f)];
    [bp closePath];
    [bp fill];
    [super endDraw];
}


- (MI_DeviceModelType) usedDeviceModelType
{
    return MOS_DEVICE_MODEL_TYPE;
}

- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 16 v 22 m 4 -3 h 12 v 8 m -12 -16 h 12 v -16 m -12 8 h 12\"/>",
        [super shapeToSVG], position.x - 16.0f, position.y - 11.0f];
    [svg appendFormat:@"\n<rect stroke=\"none\" fill=\"black\" x=\"%g\" y=\"%g\" width=\"2\" height=\"24\"/>",
        position.x + 3.0f, position.y - 12.0f];
    // draw the channel-type indicating arrow
    [svg appendFormat:@"\n<path stroke=\"none\" fill=\"black\" d=\"M %g %g l 6 3 v -6 z\"/>%@",
        position.x + 5.0f, position.y, [super endSVG]];
    return svg;
}    

@end

/**************************************** P-CHANNEL DEPLETION MOSFET TRANSISTOR ***********/

@implementation MI_DepletionPMOSTransistorElement

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(32.0f, 32.0f);
        [self setName:@"MOSFET, P-Channel, Depletion"];
        [self setLabel:@"PMOS"];
        [self setLabelPosition:MI_DIRECTION_RIGHT];
        MI_ConnectionPoint* gate = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-16.0f, -11.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Gate"
         nodeNumberPlacement:MI_DIRECTION_SOUTHWEST] autorelease];
        MI_ConnectionPoint* drain = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, 16.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Drain"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        MI_ConnectionPoint* source = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, -16.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Source"
         nodeNumberPlacement:MI_DIRECTION_SOUTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            gate, @"Gate", drain, @"Drain", source, @"Source", NULL] retain];
        [parameters setObject:@"DefaultMOSFET" forKey:@"Model"];
        [parameters setObject:@"5u" forKey:@"W"];
        [parameters setObject:@"10u" forKey:@"L"];
        [parameters setObject:@"100p" forKey:@"AD"];
        [parameters setObject:@"100p" forKey:@"AS"];
        [parameters setObject:@"40u" forKey:@"PD"];
        [parameters setObject:@"40u" forKey:@"PS"];
        [parameters setObject:@"1" forKey:@"NRD"];
        [parameters setObject:@"1" forKey:@"NRS"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(position.x - 16.0f, position.y - 16.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,   5.0f)];
    [bp relativeLineToPoint:NSMakePoint( 16.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  22.0f)];
    [NSBezierPath fillRect:NSMakeRect(position.x + 3.0f, position.y - 12.0f, 2.0f, 24.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  4.0f,  -3.0f)];
    [bp relativeLineToPoint:NSMakePoint( 12.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,   8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-12.0f, -16.0f)];
    [bp relativeLineToPoint:NSMakePoint( 12.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f, -16.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-12.0f,   8.0f)];
    [bp relativeLineToPoint:NSMakePoint( 12.0f,   0.0f)];
    [bp stroke];
    // draw arrow
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(position.x + 15.0f, position.y)];
    [bp relativeLineToPoint:NSMakePoint( -6.0f,  3.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f, -6.0f)];
    [bp closePath];
    [bp fill];
    [super endDraw];
}


- (MI_DeviceModelType) usedDeviceModelType
{
    return MOS_DEVICE_MODEL_TYPE;
}

- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 16 v 22 m 4 -3 h 12 v 8 m -12 -16 h 12 v -16 m -12 8 h 12\"/>",
        [super shapeToSVG], position.x - 16.0f, position.y - 11.0f];
    [svg appendFormat:@"\n<rect stroke=\"none\" fill=\"black\" x=\"%g\" y=\"%g\" width=\"2\" height=\"24\"/>",
        position.x + 3.0f, position.y - 12.0f];
    // draw the channel-type indicating arrow
    [svg appendFormat:@"\n<path stroke=\"none\" fill=\"black\" d=\"M %g %g l -6 3 v -6 z\"/>%@",
        position.x + 15.0f, position.y, [super endSVG]];
    return svg;
}    

@end

/********************************** ENHANCEMENT N-MOSFET TRANSISTOR ******/

@implementation MI_EnhancementNMOSTransistorElement

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(32.0f, 32.0f);
        [self setName:@"MOSFET, N-Channel"];
        [self setLabel:@"NMOS"];
        [self setLabelPosition:MI_DIRECTION_RIGHT];
        MI_ConnectionPoint* gate = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-16.0f, -11.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Gate"
         nodeNumberPlacement:MI_DIRECTION_SOUTHWEST] autorelease];
        MI_ConnectionPoint* drain = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, 16.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Drain"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        MI_ConnectionPoint* source = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, -16.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Source"
         nodeNumberPlacement:MI_DIRECTION_SOUTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            gate, @"Gate", drain, @"Drain", source, @"Source", NULL] retain];
        [parameters setObject:@"DefaultMOSFET" forKey:@"Model"];
        [parameters setObject:@"5u" forKey:@"W"];
        [parameters setObject:@"10u" forKey:@"L"];
        [parameters setObject:@"100p" forKey:@"AD"];
        [parameters setObject:@"100p" forKey:@"AS"];
        [parameters setObject:@"40u" forKey:@"PD"];
        [parameters setObject:@"40u" forKey:@"PS"];
        [parameters setObject:@"1" forKey:@"NRD"];
        [parameters setObject:@"1" forKey:@"NRS"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(position.x - 16.0f, position.y - 16.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,   5.0f)];
    [bp relativeLineToPoint:NSMakePoint( 16.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  22.0f)];
    [NSBezierPath fillRect:NSMakeRect(position.x + 3.0f, position.y - 12.0f, 2.0f, 6.0f)];
    [NSBezierPath fillRect:NSMakeRect(position.x + 3.0f, position.y -  3.0f, 2.0f, 6.0f)];
    [NSBezierPath fillRect:NSMakeRect(position.x + 3.0f, position.y +  6.0f, 2.0f, 6.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  4.0f,  -3.0f)];
    [bp relativeLineToPoint:NSMakePoint( 12.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,   8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-12.0f, -16.0f)];
    [bp relativeLineToPoint:NSMakePoint( 12.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f, -16.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-12.0f,   8.0f)];
    [bp relativeLineToPoint:NSMakePoint( 12.0f,   0.0f)];
    [bp stroke];
    // draw arrow
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(position.x + 5.0f, position.y)];
    [bp relativeLineToPoint:NSMakePoint( 6.0f,  3.0f)];
    [bp relativeLineToPoint:NSMakePoint( 0.0f, -6.0f)];
    [bp closePath];
    [bp fill];
    [super endDraw];
}


- (MI_DeviceModelType) usedDeviceModelType
{
    return MOS_DEVICE_MODEL_TYPE;
}


- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 16 v 22 m 4 -3 h 12 v 8 m -12 -16 h 12 v -16 m -12 8 h 12\"/>",
        [super shapeToSVG], position.x - 16.0f, position.y - 11.0f];
    [svg appendFormat:@"\n<rect stroke=\"none\" fill=\"black\" x=\"%g\" y=\"%g\" width=\"2\" height=\"6\"/>",
        position.x + 3.0f, position.y - 12.0f];
    [svg appendFormat:@"\n<rect stroke=\"none\" fill=\"black\" x=\"%g\" y=\"%g\" width=\"2\" height=\"6\"/>",
        position.x + 3.0f, position.y - 3.0f];
    [svg appendFormat:@"\n<rect stroke=\"none\" fill=\"black\" x=\"%g\" y=\"%g\" width=\"2\" height=\"6\"/>",
        position.x + 3.0f, position.y + 6.0f];
    // draw the channel-type indicating arrow
    [svg appendFormat:@"\n<path stroke=\"none\" fill=\"black\" d=\"M %g %g l 6 3 v -6 z\"/>%@",
        position.x + 5.0f, position.y, [super endSVG]];
    return svg;
}    

@end


/********************************** ENHANCEMENT P-MOSFET TRANSISTOR *********/

@implementation MI_EnhancementPMOSTransistorElement

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(32.0f, 32.0f);
        [self setName:@"MOSFET, P-Channel"];
        [self setLabel:@"PMOS"];
        [self setLabelPosition:MI_DIRECTION_RIGHT];
        MI_ConnectionPoint* gate = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-16.0f, -11.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Gate"
         nodeNumberPlacement:MI_DIRECTION_SOUTHWEST] autorelease];
        MI_ConnectionPoint* drain = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, 16.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Drain"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        MI_ConnectionPoint* source = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, -16.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Source"
         nodeNumberPlacement:MI_DIRECTION_SOUTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            gate, @"Gate", drain, @"Drain", source, @"Source", NULL] retain];
        [parameters setObject:@"DefaultMOSFET" forKey:@"Model"];
        [parameters setObject:@"5u" forKey:@"W"];
        [parameters setObject:@"10u" forKey:@"L"];
        [parameters setObject:@"100p" forKey:@"AD"];
        [parameters setObject:@"100p" forKey:@"AS"];
        [parameters setObject:@"40u" forKey:@"PD"];
        [parameters setObject:@"40u" forKey:@"PS"];
        [parameters setObject:@"1" forKey:@"NRD"];
        [parameters setObject:@"1" forKey:@"NRS"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(position.x - 16.0f, position.y - 16.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,   5.0f)];
    [bp relativeLineToPoint:NSMakePoint( 16.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  22.0f)];
    [NSBezierPath fillRect:NSMakeRect(position.x + 3.0f, position.y - 12.0f, 2.0f, 6.0f)];
    [NSBezierPath fillRect:NSMakeRect(position.x + 3.0f, position.y -  3.0f, 2.0f, 6.0f)];
    [NSBezierPath fillRect:NSMakeRect(position.x + 3.0f, position.y +  6.0f, 2.0f, 6.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  3.0f,  -3.0f)];
    [bp relativeLineToPoint:NSMakePoint( 13.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,   8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-12.0f, -16.0f)];
    [bp relativeLineToPoint:NSMakePoint( 12.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f, -16.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-13.0f,   8.0f)];
    [bp relativeLineToPoint:NSMakePoint( 13.0f,   0.0f)];
    [bp stroke];
    // draw arrow
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(position.x + 15.0f, position.y)];
    [bp relativeLineToPoint:NSMakePoint( -6.0f,  3.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f, -6.0f)];
    [bp closePath];
    [bp fill];
    [super endDraw];
}


- (MI_DeviceModelType) usedDeviceModelType
{
    return MOS_DEVICE_MODEL_TYPE;
}


- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 16 v 22 m 4 -3 h 12 v 8 m -12 -16 h 12 v -16 m -12 8 h 12\"/>",
        [super shapeToSVG], position.x - 16.0f, position.y - 11.0f];
    [svg appendFormat:@"\n<rect stroke=\"none\" fill=\"black\" x=\"%g\" y=\"%g\" width=\"2\" height=\"6\"/>",
        position.x + 3.0f, position.y - 12.0f];
    [svg appendFormat:@"\n<rect stroke=\"none\" fill=\"black\" x=\"%g\" y=\"%g\" width=\"2\" height=\"6\"/>",
        position.x + 3.0f, position.y - 3.0f];
    [svg appendFormat:@"\n<rect stroke=\"none\" fill=\"black\" x=\"%g\" y=\"%g\" width=\"2\" height=\"6\"/>",
        position.x + 3.0f, position.y + 6.0f];
    // draw the channel-type indicating arrow
    [svg appendFormat:@"\n<path stroke=\"none\" fill=\"black\" d=\"M %g %g l -6 3 v -6 z\"/>%@",
        position.x + 15.0f, position.y, [super endSVG]];
    return svg;
}    

@end

/******************************* N-CHANNEL MOSFET TRANSISTOR WITH BULK CONNECTOR **/

@implementation MI_DepletionNMOSwBulkTransistorElement

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(32.0f, 32.0f);
        [self setName:@"MOSFET w/ bulk conn., N-Channel, Depletion"];
        [self setLabel:@"NMOS"];
        [self setLabelPosition:MI_DIRECTION_LEFT];
        MI_ConnectionPoint* gate = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-16.0f, -11.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Gate"
         nodeNumberPlacement:MI_DIRECTION_SOUTHWEST] autorelease];
        MI_ConnectionPoint* drain = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, 16.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Drain"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        MI_ConnectionPoint* source = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, -16.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Source"
         nodeNumberPlacement:MI_DIRECTION_SOUTHEAST] autorelease];
        MI_ConnectionPoint* bulk = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Bulk"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            gate, @"Gate", drain, @"Drain", source, @"Source", bulk, @"Bulk",
            NULL] retain];
        [parameters setObject:@"DefaultMOSFET" forKey:@"Model"];
        [parameters setObject:@"5u" forKey:@"W"];
        [parameters setObject:@"10u" forKey:@"L"];
        [parameters setObject:@"100p" forKey:@"AD"];
        [parameters setObject:@"100p" forKey:@"AS"];
        [parameters setObject:@"40u" forKey:@"PD"];
        [parameters setObject:@"40u" forKey:@"PS"];
        [parameters setObject:@"1" forKey:@"NRD"];
        [parameters setObject:@"1" forKey:@"NRS"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(position.x - 16.0f, position.y - 11.0f)];
    [bp relativeLineToPoint:NSMakePoint( 16.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  22.0f)];
    [NSBezierPath fillRect:NSMakeRect(position.x + 3.0f, position.y - 12.0f, 2.0f, 24.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  4.0f,  -3.0f)];
    [bp relativeLineToPoint:NSMakePoint( 12.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,   8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-12.0f, -16.0f)];
    [bp relativeLineToPoint:NSMakePoint( 12.0f,   0.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-12.0f,   8.0f)];
    [bp relativeLineToPoint:NSMakePoint( 12.0f,   0.0f)];
    [bp stroke];
    // draw arrow
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(position.x + 5.0f, position.y)];
    [bp relativeLineToPoint:NSMakePoint( 6.0f,  3.0f)];
    [bp relativeLineToPoint:NSMakePoint( 0.0f, -6.0f)];
    [bp closePath];
    [bp fill];
    [super endDraw];
}


- (MI_DeviceModelType) usedDeviceModelType
{
    return MOS_DEVICE_MODEL_TYPE;
}

- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 16 v 22 m 4 -3 h 12 v 8 m -12 -16 h 12 m 0 -8 v -8 m -12 8 h 12\"/>",
        [super shapeToSVG], position.x - 16.0f, position.y - 11.0f];
    [svg appendFormat:@"\n<rect stroke=\"none\" fill=\"black\" x=\"%g\" y=\"%g\" width=\"2\" height=\"24\"/>",
        position.x + 3.0f, position.y - 12.0f];
    // draw the channel-type indicating arrow
    [svg appendFormat:@"\n<path stroke=\"none\" fill=\"black\" d=\"M %g %g l 6 3 v -6 z\"/>%@",
        position.x + 5.0f, position.y, [super endSVG]];
    return svg;
}    

@end

/***************************** P-CHANNEL MOSFET TRANSISTOR WITH BULK CONNECTOR **/

@implementation MI_DepletionPMOSwBulkTransistorElement

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(32.0f, 32.0f);
        [self setName:@"MOSFET w/ bulk conn., P-Channel, Depletion"];
        [self setLabel:@"PMOS"];
        [self setLabelPosition:MI_DIRECTION_LEFT];
        MI_ConnectionPoint* gate = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-16.0f, -11.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Gate"
         nodeNumberPlacement:MI_DIRECTION_SOUTHWEST] autorelease];
        MI_ConnectionPoint* drain = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, 16.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Drain"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        MI_ConnectionPoint* source = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, -16.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Source"
         nodeNumberPlacement:MI_DIRECTION_SOUTHEAST] autorelease];
        MI_ConnectionPoint* bulk = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Bulk"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            gate, @"Gate", drain, @"Drain", source, @"Source", bulk, @"Bulk",
            NULL] retain];
        [parameters setObject:@"DefaultMOSFET" forKey:@"Model"];
        [parameters setObject:@"5u" forKey:@"W"];
        [parameters setObject:@"10u" forKey:@"L"];
        [parameters setObject:@"100p" forKey:@"AD"];
        [parameters setObject:@"100p" forKey:@"AS"];
        [parameters setObject:@"40u" forKey:@"PD"];
        [parameters setObject:@"40u" forKey:@"PS"];
        [parameters setObject:@"1" forKey:@"NRD"];
        [parameters setObject:@"1" forKey:@"NRS"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(position.x - 16.0f, position.y - 16.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,   5.0f)];
    [bp relativeLineToPoint:NSMakePoint( 16.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  22.0f)];
    [NSBezierPath fillRect:NSMakeRect(position.x + 3.0f, position.y - 12.0f, 2.0f, 24.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  4.0f,  -3.0f)];
    [bp relativeLineToPoint:NSMakePoint( 12.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,   8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-12.0f, -16.0f)];
    [bp relativeLineToPoint:NSMakePoint( 12.0f,   0.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-12.0f,   8.0f)];
    [bp relativeLineToPoint:NSMakePoint( 12.0f,   0.0f)];
    [bp stroke];
    // draw arrow
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(position.x + 15.0f, position.y)];
    [bp relativeLineToPoint:NSMakePoint( -6.0f,  3.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f, -6.0f)];
    [bp closePath];
    [bp fill];
    [super endDraw];
}


- (MI_DeviceModelType) usedDeviceModelType
{
    return MOS_DEVICE_MODEL_TYPE;
}

- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 16 v 22 m 4 -3 h 12 v 8 m -12 -16 h 12 m 0 -8 v -8 m -12 8 h 12\"/>",
        [super shapeToSVG], position.x - 16.0f, position.y - 11.0f];
    [svg appendFormat:@"\n<rect stroke=\"none\" fill=\"black\" x=\"%g\" y=\"%g\" width=\"2\" height=\"24\"/>",
        position.x + 3.0f, position.y - 12.0f];
    // draw the channel-type indicating arrow
    [svg appendFormat:@"\n<path stroke=\"none\" fill=\"black\" d=\"M %g %g l -6 3 v -6 z\"/>%@",
        position.x + 15.0f, position.y, [super endSVG]];
    return svg;
}    


@end

/************************ ENHANCEMENT N-MOSFET TRANSISTOR WITH BULK CONNECTOR **/

@implementation MI_EnhancementNMOSwBulkTransistorElement

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(32.0f, 32.0f);
        [self setName:@"MOSFET w/ bulk conn., N-Channel"];
        [self setLabel:@"NMOS"];
        [self setLabelPosition:MI_DIRECTION_LEFT];
        MI_ConnectionPoint* gate = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-16.0f, -11.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Gate"
         nodeNumberPlacement:MI_DIRECTION_SOUTHWEST] autorelease];
        MI_ConnectionPoint* drain = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, 16.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Drain"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        MI_ConnectionPoint* source = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, -16.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Source"
         nodeNumberPlacement:MI_DIRECTION_SOUTHEAST] autorelease];
        MI_ConnectionPoint* bulk = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Bulk"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            gate, @"Gate", drain, @"Drain", source, @"Source", bulk, @"Bulk",
            NULL] retain];
        [parameters setObject:@"DefaultMOSFET" forKey:@"Model"];
        [parameters setObject:@"5u" forKey:@"W"];
        [parameters setObject:@"10u" forKey:@"L"];
        [parameters setObject:@"100p" forKey:@"AD"];
        [parameters setObject:@"100p" forKey:@"AS"];
        [parameters setObject:@"40u" forKey:@"PD"];
        [parameters setObject:@"40u" forKey:@"PS"];
        [parameters setObject:@"1" forKey:@"NRD"];
        [parameters setObject:@"1" forKey:@"NRS"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(position.x - 16.0f, position.y - 16.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,   5.0f)];
    [bp relativeLineToPoint:NSMakePoint( 16.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  22.0f)];
    [NSBezierPath fillRect:NSMakeRect(position.x + 3.0f, position.y - 12.0f, 2.0f, 6.0f)];
    [NSBezierPath fillRect:NSMakeRect(position.x + 3.0f, position.y -  3.0f, 2.0f, 6.0f)];
    [NSBezierPath fillRect:NSMakeRect(position.x + 3.0f, position.y +  6.0f, 2.0f, 6.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  4.0f,  -3.0f)];
    [bp relativeLineToPoint:NSMakePoint( 12.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,   8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-12.0f, -16.0f)];
    [bp relativeLineToPoint:NSMakePoint( 12.0f,   0.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-12.0f,   8.0f)];
    [bp relativeLineToPoint:NSMakePoint( 12.0f,   0.0f)];
    [bp stroke];
    // draw arrow
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(position.x + 5.0f, position.y)];
    [bp relativeLineToPoint:NSMakePoint( 6.0f,  3.0f)];
    [bp relativeLineToPoint:NSMakePoint( 0.0f, -6.0f)];
    [bp closePath];
    [bp fill];
    [super endDraw];
}


- (MI_DeviceModelType) usedDeviceModelType
{
    return MOS_DEVICE_MODEL_TYPE;
}


- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 16 v 22 m 4 -3 h 12 v 8 m -12 -16 h 12 m 0 -8 v -8 m -12 8 h 12\"/>",
        [super shapeToSVG], position.x - 16.0f, position.y - 11.0f];
    [svg appendFormat:@"\n<rect stroke=\"none\" fill=\"black\" x=\"%g\" y=\"%g\" width=\"2\" height=\"6\"/>",
        position.x + 3.0f, position.y - 12.0f];
    [svg appendFormat:@"\n<rect stroke=\"none\" fill=\"black\" x=\"%g\" y=\"%g\" width=\"2\" height=\"6\"/>",
        position.x + 3.0f, position.y - 3.0f];
    [svg appendFormat:@"\n<rect stroke=\"none\" fill=\"black\" x=\"%g\" y=\"%g\" width=\"2\" height=\"6\"/>",
        position.x + 3.0f, position.y + 6.0f];
    // draw the channel-type indicating arrow
    [svg appendFormat:@"\n<path stroke=\"none\" fill=\"black\" d=\"M %g %g l 6 3 v -6 z\"/>%@",
        position.x + 5.0f, position.y, [super endSVG]];
    return svg;
}    

@end


/*********************** ENHANCEMENT P-MOSFET TRANSISTOR WITH BULK CONNECTOR **/

@implementation MI_EnhancementPMOSwBulkTransistorElement

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(32.0f, 32.0f);
        [self setName:@"MOSFET w/ bulk conn., P-Channel"];
        [self setLabel:@"PMOS"];
        [self setLabelPosition:MI_DIRECTION_LEFT];
        MI_ConnectionPoint* gate = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-16.0f, -11.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Gate"
         nodeNumberPlacement:MI_DIRECTION_SOUTHWEST] autorelease];
        MI_ConnectionPoint* drain = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, 16.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Drain"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        MI_ConnectionPoint* source = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, -16.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Source"
         nodeNumberPlacement:MI_DIRECTION_SOUTHEAST] autorelease];
        MI_ConnectionPoint* bulk = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"Bulk"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            gate, @"Gate", drain, @"Drain", source, @"Source", bulk, @"Bulk",
            NULL] retain];
        [parameters setObject:@"DefaultMOSFET" forKey:@"Model"];
        [parameters setObject:@"5u" forKey:@"W"];
        [parameters setObject:@"10u" forKey:@"L"];
        [parameters setObject:@"100p" forKey:@"AD"];
        [parameters setObject:@"100p" forKey:@"AS"];
        [parameters setObject:@"40u" forKey:@"PD"];
        [parameters setObject:@"40u" forKey:@"PS"];
        [parameters setObject:@"1" forKey:@"NRD"];
        [parameters setObject:@"1" forKey:@"NRS"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(position.x - 16.0f, position.y - 16.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,   5.0f)];
    [bp relativeLineToPoint:NSMakePoint( 16.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  22.0f)];
    [NSBezierPath fillRect:NSMakeRect(position.x + 3.0f, position.y - 12.0f, 2.0f, 6.0f)];
    [NSBezierPath fillRect:NSMakeRect(position.x + 3.0f, position.y -  3.0f, 2.0f, 6.0f)];
    [NSBezierPath fillRect:NSMakeRect(position.x + 3.0f, position.y +  6.0f, 2.0f, 6.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  3.0f,  -3.0f)];
    [bp relativeLineToPoint:NSMakePoint( 13.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,   8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-12.0f, -16.0f)];
    [bp relativeLineToPoint:NSMakePoint( 12.0f,   0.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  -8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-13.0f,   8.0f)];
    [bp relativeLineToPoint:NSMakePoint( 13.0f,   0.0f)];
    [bp stroke];
    // draw arrow
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(position.x + 15.0f, position.y)];
    [bp relativeLineToPoint:NSMakePoint( -6.0f,  3.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f, -6.0f)];
    [bp closePath];
    [bp fill];
    [super endDraw];
}


- (MI_DeviceModelType) usedDeviceModelType
{
    return MOS_DEVICE_MODEL_TYPE;
}


- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 16 v 22 m 4 -3 h 12 v 8 m -12 -16 h 12 m 0 -8 v -8 m -12 8 h 12\"/>",
        [super shapeToSVG], position.x - 16.0f, position.y - 11.0f];
    [svg appendFormat:@"\n<rect stroke=\"none\" fill=\"black\" x=\"%g\" y=\"%g\" width=\"2\" height=\"6\"/>",
        position.x + 3.0f, position.y - 12.0f];
    [svg appendFormat:@"\n<rect stroke=\"none\" fill=\"black\" x=\"%g\" y=\"%g\" width=\"2\" height=\"6\"/>",
        position.x + 3.0f, position.y - 3.0f];
    [svg appendFormat:@"\n<rect stroke=\"none\" fill=\"black\" x=\"%g\" y=\"%g\" width=\"2\" height=\"6\"/>",
        position.x + 3.0f, position.y + 6.0f];
    // draw the channel-type indicating arrow
    [svg appendFormat:@"\n<path stroke=\"none\" fill=\"black\" d=\"M %g %g l -6 3 v -6 z\"/>%@",
        position.x + 15.0f, position.y, [super endSVG]];
    return svg;
}    

@end


