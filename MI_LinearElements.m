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
#import "MI_LinearElements.h"
#import "MI_ConnectionPoint.h"

/******************************************* RESISTOR (IEC) *********/
@implementation MI_Resistor_IEC_Element

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(42.0f, 12.0f);
        [self setName:@"Resistor"];
        [self setLabel:@"R"];
        [self setLabelPosition:MI_DIRECTION_UP];
        MI_ConnectionPoint* A = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-21.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"A"
         nodeNumberPlacement:MI_DIRECTION_NORTHWEST] autorelease];
        MI_ConnectionPoint* B = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(21.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"B"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            A, @"A", B, @"B", NULL] retain];
        [parameters setObject:@"1k" forKey:@"Resistance"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(position.x - 21.0f, position.y)];
    [bp relativeLineToPoint:NSMakePoint(  8.0f, 0.0f)];
    [bp relativeMoveToPoint:NSMakePoint( 26.0f, 0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  8.0f, 0.0f)];
    [bp stroke];
    [NSBezierPath strokeRect:NSMakeRect(position.x - 13.0f, position.y - 6.0f, 26.0f, 12.0f)];
    [super endDraw];
}


- (NSString*) shapeToSVG
{
    NSMutableString* svg = [[NSMutableString alloc] initWithCapacity:50];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 8.0 m 26.0 0.0 h 8.0\"/>",
        [super shapeToSVG], position.x - 21.0f, position.y];
    [svg appendFormat:@"\n<rect x=\"%g\" y=\"%g\" width=\"26.0\" height=\"12.0\"/>%@",
        position.x - 13.0f, position.y - 6.0f, [super endSVG]];
    return [svg autorelease];
}

@end

/******************************************* RESISTOR (US) *********/
@implementation MI_Resistor_US_Element

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(42.0f, 12.0f);
        [self setName:@"Resistor"];
        [self setLabel:@"R"];
        [self setLabelPosition:MI_DIRECTION_UP];
        MI_ConnectionPoint* A = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-21.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"A"
         nodeNumberPlacement:MI_DIRECTION_NORTHWEST] autorelease];
        MI_ConnectionPoint* B = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(21.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"B"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            A, @"A", B, @"B", NULL] retain];
        [parameters setObject:@"1k" forKey:@"Resistance"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(position.x - 21.0f, position.y)];
    [bp relativeLineToPoint:NSMakePoint(  8.0f,   0.0f)];
    // draw zigzag
    [bp relativeLineToPoint:NSMakePoint( 2.17f,   6.0f)];
    [bp relativeLineToPoint:NSMakePoint( 4.33f, -12.0f)];
    [bp relativeLineToPoint:NSMakePoint( 4.33f,  12.0f)];
    [bp relativeLineToPoint:NSMakePoint( 4.33f, -12.0f)];
    [bp relativeLineToPoint:NSMakePoint( 4.33f,  12.0f)];
    [bp relativeLineToPoint:NSMakePoint( 4.33f, -12.0f)];
    [bp relativeLineToPoint:NSMakePoint( 2.17f,   6.0f)];
    [bp relativeLineToPoint:NSMakePoint(  8.0f,   0.0f)];
    [bp stroke];
    [super endDraw];
}


- (NSString*) shapeToSVG
{
    return [NSString stringWithFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 8.0 l 2.17 6.0 l 4.33 -12.0 l 4.33 12.0 l 4.33 -12.0 l 4.33 12.0 l 4.33 -12.0 l 2.17 6.0 h 8.0\"/>%@",
        [super shapeToSVG], position.x - 21.0f, position.y, [super endSVG]];
}


@end

/******************************************* RHEOSTAT (IEC) *********/
@implementation MI_Rheostat_IEC_Element

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(42.0f, 28.0f);
        [self setName:@"Rheostat"];
        [self setLabel:@"R"];
        [self setLabelPosition:MI_DIRECTION_UP];
        MI_ConnectionPoint* A = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-21.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"A"
         nodeNumberPlacement:MI_DIRECTION_NORTHWEST] autorelease];
        MI_ConnectionPoint* B = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(21.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"B"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            A, @"A", B, @"B", NULL] retain];
        [parameters setObject:@"1k" forKey:@"Resistance"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(position.x - 21.0f, position.y)];
    [bp relativeLineToPoint:NSMakePoint(   8.0f,  0.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  26.0f,  0.0f)];
    [bp relativeLineToPoint:NSMakePoint(   8.0f,  0.0f)];
    [bp relativeMoveToPoint:NSMakePoint( -34.0f,-14.0f)];
    [bp relativeLineToPoint:NSMakePoint(  25.5f, 27.5f)];    
    [bp stroke];
    [NSBezierPath strokeRect:NSMakeRect(position.x - 13.0f, position.y - 6.0f, 26.0f, 12.0f)];
    // Draw arrow head
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(position.x + 13.0f, position.y + 14.0f)];
    [bp relativeLineToPoint:NSMakePoint( -2.0f,  -6.5f)];
    [bp relativeLineToPoint:NSMakePoint( -4.0f,   4.0f)];
    [bp closePath];
    [bp fill];
    [super endDraw];
}

- (NSString*) shapeToSVG
{
    NSMutableString* svg = [[NSMutableString alloc] initWithCapacity:50];
    [svg appendFormat:@"%@<path d=\"M %g %g h 8.0 m 26.0 0.0 h 8.0\"/>",
        [super shapeToSVG], position.x - 21.0f, position.y];
    [svg appendFormat:@"\n<rect x=\"%g\" y=\"%g\" width=\"26.0\" height=\"12.0\"/>",
        position.x - 13.0f, position.y - 6.0f];
    // draw arrow
    [svg appendFormat:@"\n<line x1=\"%g\" y1=\"%g\" x2=\"%g\" y2=\"%g\" />",
        position.x - 13.0f, position.y - 14.0f, position.x + 13.0f, position.y + 14.0f];
    [svg appendFormat:@"\n<path stroke=\"black\" fill=\"black\" d=\"M %g %g l -2.0 -6.5 l -4.0 4.0\"/>%@",
        position.x + 13.0f, position.y + 14.0f, [super endSVG]];
    return [svg autorelease];
}

@end

/******************************************* RHEOSTAT (US) *********/
@implementation MI_Rheostat_US_Element

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(42.0f, 28.0f);
        [self setName:@"Rheostat"];
        [self setLabel:@"R"];
        [self setLabelPosition:MI_DIRECTION_UP];
        MI_ConnectionPoint* A = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-21.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"A"
         nodeNumberPlacement:MI_DIRECTION_NORTHWEST] autorelease];
        MI_ConnectionPoint* B = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(21.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"B"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            A, @"A", B, @"B", NULL] retain];
        [parameters setObject:@"1k" forKey:@"Resistance"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(position.x - 21.0f, position.y)];
    [bp relativeLineToPoint:NSMakePoint(  8.0f,   0.0f)];
    // draw zigzag
    [bp relativeLineToPoint:NSMakePoint( 2.17f,   6.0f)];
    [bp relativeLineToPoint:NSMakePoint( 4.33f, -12.0f)];
    [bp relativeLineToPoint:NSMakePoint( 4.33f,  12.0f)];
    [bp relativeLineToPoint:NSMakePoint( 4.33f, -12.0f)];
    [bp relativeLineToPoint:NSMakePoint( 4.33f,  12.0f)];
    [bp relativeLineToPoint:NSMakePoint( 4.33f, -12.0f)];
    [bp relativeLineToPoint:NSMakePoint( 2.17f,   6.0f)];
    [bp relativeLineToPoint:NSMakePoint(  8.0f,   0.0f)];
    [bp relativeMoveToPoint:NSMakePoint( -34.0f,-14.0f)];
    [bp relativeLineToPoint:NSMakePoint(  25.5f, 27.5f)];    
    [bp stroke];
    // Draw arrow head
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(position.x + 13.0f, position.y + 14.0f)];
    [bp relativeLineToPoint:NSMakePoint( -2.0f,  -6.5f)];
    [bp relativeLineToPoint:NSMakePoint( -4.0f,   4.0f)];
    [bp closePath];
    [bp fill];
    [super endDraw];
}

- (NSString*) shapeToSVG
{
    NSMutableString* svg = [[NSMutableString alloc] initWithCapacity:50];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 8.0 l 2.17 6.0 l 4.33 -12.0 l 4.33 12.0 l 4.33 -12.0 l 4.33 12.0 l 4.33 -12.0 l 2.17 6.0 h 8.0\"/>",
        [super shapeToSVG], position.x - 21.0f, position.y];
    // draw arrow
    [svg appendFormat:@"\n<line x1=\"%g\" y1=\"%g\" x2=\"%g\" y2=\"%g\" />",
        position.x - 13.0f, position.y - 14.0f, position.x + 13.0f, position.y + 14.0f];
    [svg appendFormat:@"\n<path stroke=\"black\" fill=\"black\" d=\"M %g %g l -2.0 -6.5 l -4.0 4.0\"/>%@",
        position.x + 13.0f, position.y + 14.0f, [super endSVG]];
    return [svg autorelease];
}

@end

/******************************************* Inductor (IEC) *********/
@implementation MI_Inductor_IEC_Element

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(42.0f, 12.0f);
        [self setName:@"Inductor"];
        [self setLabel:@"L"];
        [self setLabelPosition:MI_DIRECTION_UP];
        MI_ConnectionPoint* A = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-21.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"A"
         nodeNumberPlacement:MI_DIRECTION_NORTHWEST] autorelease];
        MI_ConnectionPoint* B = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(21.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"B"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            A, @"A", B, @"B", NULL] retain];
        [parameters setObject:@"1u" forKey:@"Inductance"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(position.x - 21.0f, position.y - 6.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,  6.0f)];
    [bp relativeLineToPoint:NSMakePoint(  8.0f,  0.0f)];
    [bp relativeMoveToPoint:NSMakePoint( 26.0f,  0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  8.0f,  0.0f)];
    [bp stroke];
    [NSBezierPath fillRect:NSMakeRect(position.x - 13.0f, position.y - 6.0f, 26.0f, 12.0f)];
    [super endDraw];
}

- (NSString*) shapeToSVG
{
    NSMutableString* svg = [[NSMutableString alloc] initWithCapacity:50];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 8.0 m 26.0 0.0 h 8.0\"/>",
        [super shapeToSVG], position.x - 21.0f, position.y];
    [svg appendFormat:@"\n<rect fill=\"black\" x=\"%g\" y=\"%g\" width=\"26.0\" height=\"12.0\"/>%@",
        position.x - 13.0f, position.y - 6.0f, [super endSVG]];
    return [svg autorelease];
}

@end

/******************************************* Inductor (US) *********/
@implementation MI_Inductor_US_Element

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(42.0f, 12.0f);
        [self setName:@"Inductor"];
        [self setLabel:@"L"];
        [self setLabelPosition:MI_DIRECTION_UP];
        MI_ConnectionPoint* A = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-21.0f, -6.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"A"
         nodeNumberPlacement:MI_DIRECTION_NORTHWEST] autorelease];
        MI_ConnectionPoint* B = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(21.0f, -6.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"B"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            A, @"A", B, @"B", NULL] retain];
        [parameters setObject:@"1u" forKey:@"Inductance"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(position.x - 21.0f, position.y - 6.0f)];
    [bp relativeLineToPoint:NSMakePoint( 8.0f,  0.0f)];
    [bp relativeLineToPoint:NSMakePoint( 0.0f,  6.0f)];
    [bp relativeMoveToPoint:NSMakePoint( 6.5f,  0.0f)];
    [bp relativeLineToPoint:NSMakePoint( 0.0f, -6.0f)];
    [bp relativeMoveToPoint:NSMakePoint( 6.5f,  0.0f)];
    [bp relativeLineToPoint:NSMakePoint( 0.0f,  6.0f)];
    [bp relativeMoveToPoint:NSMakePoint( 6.5f,  0.0f)];
    [bp relativeLineToPoint:NSMakePoint( 0.0f, -6.0f)];
    [bp relativeMoveToPoint:NSMakePoint( 6.5f,  6.0f)];
    [bp relativeLineToPoint:NSMakePoint( 0.0f, -6.0f)];
    [bp relativeLineToPoint:NSMakePoint( 8.0f,  0.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-8.0f,  6.0f)];

    [bp appendBezierPathWithArcWithCenter:NSMakePoint(position.x + 9.75f, position.y)
                                   radius:3.25f
                               startAngle:0.0f
                                 endAngle:180.0f];
    [bp appendBezierPathWithArcWithCenter:NSMakePoint(position.x + 3.25f, position.y)
                                   radius:3.25f
                               startAngle:0.0f
                                 endAngle:180.0f];
    [bp appendBezierPathWithArcWithCenter:NSMakePoint(position.x - 3.25f, position.y)
                                   radius:3.25f
                               startAngle:0.0f
                                 endAngle:180.0f];
    [bp appendBezierPathWithArcWithCenter:NSMakePoint(position.x - 9.75f, position.y)
                                   radius:3.25f
                               startAngle:0.0f
                                 endAngle:180.0f];

    [bp stroke];
    [super endDraw];
}

- (NSString*) shapeToSVG
{
    return [NSString stringWithFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 8 v 6 m 6.5,0 v -6 m 6.5,0 v 6 m 6.5,0 v -6 m 6.5,6 v -6 h 8 m -8,6 a 3.25 3.25 0 0 1 -6.5,0 a 3.25 3.25 0 0 1 -6.5,0 a 3.25 3.25 0 0 1 -6.5,0 a 3.25 3.25 0 0 1 -6.5,0\"/>%@",
        [super shapeToSVG], position.x - 21.0f, position.y - 6.0f, [super endSVG]];
}

@end

/******************************************* TRANSFORMER (US) ********/

@implementation MI_Transformer_US_Element

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(36.0f, 42.0f);
        [self setName:@"Transformer"];
        [self setLabel:@"TR"];
        [self setLabelPosition:MI_DIRECTION_UP];
        MI_ConnectionPoint* L11 = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-18.0f, -21.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"L11"
         nodeNumberPlacement:MI_DIRECTION_NORTHWEST] autorelease];
        MI_ConnectionPoint* L12 = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-18.0f, 21.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"L12"
         nodeNumberPlacement:MI_DIRECTION_SOUTHWEST] autorelease];
        MI_ConnectionPoint* L21 = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint( 18.0f, -21.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"L21"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        MI_ConnectionPoint* L22 = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint( 18.0f, 21.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"L22"
         nodeNumberPlacement:MI_DIRECTION_SOUTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            L11, @"L11", L12, @"L12", L21, @"L21", L22, @"L22", NULL] retain];
        [parameters setObject:@"1u" forKey:@"Inductance 1"];
        [parameters setObject:@"1u" forKey:@"Inductance 2"];
        [parameters setObject:@"0.8" forKey:@"Coupling"];
    }
    return self;
}


- (void) draw
{
    NSBezierPath* bp;
    [super draw];
    bp = [NSBezierPath bezierPath];

    // Draw left coil
    [bp moveToPoint:NSMakePoint(position.x - 18.0f, position.y + 21.0f)];
    [bp relativeLineToPoint:NSMakePoint( 0.0f, -8.0f)];
    [bp relativeLineToPoint:NSMakePoint( 6.0f,  0.0f)];
    [bp relativeMoveToPoint:NSMakePoint( 0.0f, -6.5f)];
    [bp relativeLineToPoint:NSMakePoint(-6.0f,  0.0f)];
    [bp relativeMoveToPoint:NSMakePoint( 0.0f, -6.5f)];
    [bp relativeLineToPoint:NSMakePoint( 6.0f,  0.0f)];
    [bp relativeMoveToPoint:NSMakePoint( 0.0f, -6.5f)];
    [bp relativeLineToPoint:NSMakePoint(-6.0f,  0.0f)];
    [bp relativeMoveToPoint:NSMakePoint( 6.0f, -6.5f)];
    [bp relativeLineToPoint:NSMakePoint(-6.0f,  0.0f)];
    [bp relativeLineToPoint:NSMakePoint( 0.0f, -8.0f)];
    [bp relativeMoveToPoint:NSMakePoint( 6.0f,  8.0f)];

    [bp appendBezierPathWithArcWithCenter:NSMakePoint(position.x - 12.0f, position.y - 9.75f)
                                   radius:3.25f
                               startAngle:-90.0f
                                 endAngle:90.0f];
    [bp appendBezierPathWithArcWithCenter:NSMakePoint(position.x - 12.0f, position.y - 3.25f)
                                   radius:3.25f
                               startAngle:-90.0f
                                 endAngle:90.0f];
    [bp appendBezierPathWithArcWithCenter:NSMakePoint(position.x - 12.0f, position.y + 3.25f)
                                   radius:3.25f
                               startAngle:-90.0f
                                 endAngle:90.0f];
    [bp appendBezierPathWithArcWithCenter:NSMakePoint(position.x - 12.0f, position.y + 9.75f)
                                   radius:3.25f
                               startAngle:-90.0f
                                 endAngle:90.0f];

    // Draw right coil
    [bp moveToPoint:NSMakePoint(position.x + 18.0f, position.y + 21.0f)];
    [bp relativeLineToPoint:NSMakePoint( 0.0f, -8.0f)];
    [bp relativeLineToPoint:NSMakePoint(-6.0f,  0.0f)];
    [bp relativeMoveToPoint:NSMakePoint( 0.0f, -6.5f)];
    [bp relativeLineToPoint:NSMakePoint( 6.0f,  0.0f)];
    [bp relativeMoveToPoint:NSMakePoint( 0.0f, -6.5f)];
    [bp relativeLineToPoint:NSMakePoint(-6.0f,  0.0f)];
    [bp relativeMoveToPoint:NSMakePoint( 0.0f, -6.5f)];
    [bp relativeLineToPoint:NSMakePoint( 6.0f,  0.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-6.0f, -6.5f)];
    [bp relativeLineToPoint:NSMakePoint( 6.0f,  0.0f)];
    [bp relativeLineToPoint:NSMakePoint( 0.0f, -8.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-6.0f,  8.0f)];

    [bp appendBezierPathWithArcWithCenter:NSMakePoint(position.x + 12.0f, position.y - 9.75f)
                                   radius:3.25f
                               startAngle:270.0f
                                 endAngle:90.0f
                                clockwise:YES];
    [bp appendBezierPathWithArcWithCenter:NSMakePoint(position.x + 12.0f, position.y - 3.25f)
                                   radius:3.25f
                               startAngle:270.0f
                                 endAngle:90.0f
                                clockwise:YES];
    [bp appendBezierPathWithArcWithCenter:NSMakePoint(position.x + 12.0f, position.y + 3.25f)
                                   radius:3.25f
                               startAngle:270.0f
                                 endAngle:90.0f
                                clockwise:YES];
    [bp appendBezierPathWithArcWithCenter:NSMakePoint(position.x + 12.0f, position.y + 9.75f)
                                   radius:3.25f
                               startAngle:270.0f
                                 endAngle:90.0f
                                clockwise:YES];

    // Draw coupling lines
    [bp moveToPoint:NSMakePoint(position.x + 2.0f, position.y + 13.0f)];
    [bp relativeLineToPoint:NSMakePoint(0.0f, -26.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-4.0f, 0.0f)];
    [bp relativeLineToPoint:NSMakePoint(0.0f, 26.0f)];
    [bp stroke];

    // Draw primary side indicator
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(position.x - 15.0f, position.y + 18.0f, 3.0f, 3.0f)] fill];

    [super endDraw];
}    


- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:200];
    // left coil
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g v -8 h 6 m 0 -6.5 h -6 m 0 -6.5 h 6 m 0 -6.5 h -6 m 6 -6.5 h -6 v -8 m 6 8 a 3.25 3.25 0 0 1 0 6.5 a 3.25 3.25 0 0 1 0 6.5 a 3.25 3.25 0 0 1 0 6.5 a 3.25 3.25 0 0 1 0 6.5\"/>",
        [super shapeToSVG], position.x - 18.0f, position.y + 21.0f];
    // right coil
    [svg appendFormat:@"\n<path stroke=\"black\" fill=\"none\" d=\"M %g %g v -8 h -6 m 0 -6.5 h 6 m 0 -6.5 h -6 m 0 -6.5 h 6 m -6 -6.5 h 6 v -8 m -6 8 a 3.25 3.25 0 0 0 0 6.5 a 3.25 3.25 0 0 0 0 6.5 a 3.25 3.25 0 0 0 0 6.5 a 3.25 3.25 0 0 0 0 6.5\"/>",
        position.x + 18.0f, position.y + 21.0f];
    // coupling lines
    [svg appendFormat:@"\n<path stroke=\"black\" fill=\"none\" d=\"M %g %g v -26 m -4 0 v 26\"/>",
        position.x + 2.0f, position.y + 13.0f];    
    // primary side indicator
    [svg appendFormat:@"\n<circle stroke=\"black\" fill=\"black\" cx=\"%g\" cy=\"%g\" r=\"1.5\"/>%@",
        position.x - 13.5f, position.y + 19.5f, [super endSVG]];
    return svg;
}

@end

/******************************************* TRANSFORMER (IEC) ********/

@implementation MI_Transformer_IEC_Element

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(36.0f, 42.0f);
        [self setName:@"Transformer"];
        [self setLabel:@"TR"];
        [self setLabelPosition:MI_DIRECTION_UP];
        MI_ConnectionPoint* L11 = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-12.0f, -21.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"L11"
         nodeNumberPlacement:MI_DIRECTION_NORTHWEST] autorelease];
        MI_ConnectionPoint* L12 = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-12.0f, 21.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"L12"
         nodeNumberPlacement:MI_DIRECTION_SOUTHWEST] autorelease];
        MI_ConnectionPoint* L21 = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint( 12.0f, -21.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"L21"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        MI_ConnectionPoint* L22 = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint( 12.0f, 21.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"L22"
         nodeNumberPlacement:MI_DIRECTION_SOUTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            L11, @"L11", L12, @"L12", L21, @"L21", L22, @"L22", NULL] retain];
        [parameters setObject:@"1u" forKey:@"Inductance A"];
        [parameters setObject:@"1u" forKey:@"Inductance B"];
        [parameters setObject:@"0.8" forKey:@"Coupling"];
    }
    return self;
}


- (void) draw
{
    NSBezierPath* bp;
    [super draw];
    bp = [NSBezierPath bezierPath];

    // Draw left coil
    [bp moveToPoint:NSMakePoint(position.x - 12.0f, position.y + 21.0f)];
    [bp relativeLineToPoint:NSMakePoint( 0.0f, -8.0f)];
    [bp relativeMoveToPoint:NSMakePoint( 0.0f,-26.0f)];
    [bp relativeLineToPoint:NSMakePoint( 0.0f, -8.0f)];
    [NSBezierPath fillRect:NSMakeRect(position.x - 18.0f, position.y - 13.0f, 12.0f, 26.0f)];
        
    // Draw right coil
    [bp moveToPoint:NSMakePoint(position.x + 12.0f, position.y + 21.0f)];
    [bp relativeLineToPoint:NSMakePoint( 0.0f, -8.0f)];
    [bp relativeMoveToPoint:NSMakePoint( 0.0f,-26.0f)];
    [bp relativeLineToPoint:NSMakePoint( 0.0f, -8.0f)];
    [NSBezierPath fillRect:NSMakeRect(position.x + 6.0f, position.y - 13.0f, 12.0f, 26.0f)];

    // Draw coupling lines
    [bp moveToPoint:NSMakePoint(position.x + 2.0f, position.y + 13.0f)];
    [bp relativeLineToPoint:NSMakePoint(0.0f, -26.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-4.0f, 0.0f)];
    [bp relativeLineToPoint:NSMakePoint(0.0f, 26.0f)];
    [bp stroke];

    // Draw primary side indicator
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(position.x - 9.0f, position.y + 18.0f, 3.0f, 3.0f)] fill];

    [super endDraw];
}


- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:200];
    // left coil
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g v -8 m 0 -26 v -8\"/>",
        [super shapeToSVG], position.x - 12.0f, position.y + 21.0f];
    [svg appendFormat:@"\n<rect stroke=\"black\" fill=\"black\" x=\"%g\" y=\"%g\" width=\"12\" height=\"26\"/>",
        position.x - 18.0f, position.y - 13.0f];
    // right coil
    [svg appendFormat:@"\n<path stroke=\"black\" fill=\"none\" d=\"M %g %g v -8 m 0 -26 v -8\"/>",
        position.x + 12.0f, position.y + 21.0f];
    [svg appendFormat:@"\n<rect stroke=\"black\" fill=\"black\" x=\"%g\" y=\"%g\" width=\"12\" height=\"26\"/>",
        position.x + 6.0f, position.y - 13.0f];
    // coupling lines
    [svg appendFormat:@"\n<path stroke=\"black\" fill=\"none\" d=\"M %g %g v -26 m -4 0 v 26\"/>",
        position.x + 2.0f, position.y + 13.0f];    
    // primary side indicator
    [svg appendFormat:@"\n<circle stroke=\"black\" fill=\"black\" cx=\"%g\" cy=\"%g\" r=\"1.5\"/>%@",
        position.x - 7.5f, position.y + 19.5f, [super endSVG]];
    return svg;
}

@end

/******************************************* CAPACITOR ***************/
@implementation MI_CapacitorElement

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(32.0f, 24.0f);
        [self setName:@"Capacitor"];
        [self setLabel:@"C"];
        [self setLabelPosition:MI_DIRECTION_UP];
        MI_ConnectionPoint* A = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-16.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"A"
         nodeNumberPlacement:MI_DIRECTION_NORTHWEST] autorelease];
        MI_ConnectionPoint* B = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"B"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            A, @"A", B, @"B", NULL] retain];
        [parameters setObject:@"1u" forKey:@"Capacitance"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(position.x - 16.0f, position.y)];
    [bp relativeLineToPoint:NSMakePoint( 13.0f,   0.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  6.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint( 13.0f,   0.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-19.0f, -12.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  24.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  6.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f, -24.0f)];
    [bp stroke];
    [super endDraw];
}


- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 13 m 6 0 h 13 m -19 -12 v 24 m 6 0 v -24\"/>%@",
        [super shapeToSVG], position.x - 16.0f, position.y, [super endSVG]];
    return svg;
}

@end

/******************************************* POLARIZED CAPACITOR *********/
@implementation MI_PolarizedCapacitorElement

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(32.0f, 24.0f);
        [self setName:@"Polarized Capacitor"];
        [self setLabel:@"C"];
        [self setLabelPosition:MI_DIRECTION_UP];
        MI_ConnectionPoint* A = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-16.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"A"
         nodeNumberPlacement:MI_DIRECTION_NORTHWEST] autorelease];
        MI_ConnectionPoint* B = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(16.0f, 0.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"B"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            A, @"A", B, @"B", NULL] retain];
        [parameters setObject:@"1u" forKey:@"Capacitance"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    [bp moveToPoint:NSMakePoint(position.x - 16.0f, position.y)];
    [bp relativeLineToPoint:NSMakePoint( 13.0f,   0.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  4.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint( 15.0f,   0.0f)];
    [bp relativeMoveToPoint:NSMakePoint(-19.0f, -12.0f)];
    [bp relativeLineToPoint:NSMakePoint(  0.0f,  24.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  8.0f,   0.0f)];
    [bp relativeCurveToPoint:NSMakePoint( 0.0f, -24.0f)
               controlPoint1:NSMakePoint(-4.5f,  -6.0f)
               controlPoint2:NSMakePoint(-4.5f, -18.0f)];
    [bp stroke];
    [super endDraw];
}


- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 13 m 4 0 h 15 m -19 -12 v 24 m 7.9 0 c -4.5 -6 -4.5 -18 0 -24\"/>%@",
        [super shapeToSVG], position.x - 16.0f, position.y, [super endSVG]];
    return svg;
}

@end

/******************************************* TRANSMISSION LINE *********/
@implementation MI_TransmissionLineElement

- (id) init
{
    if (self = [super init])
    {
        originalSize = size = NSMakeSize(50.0f, 24.0f);
        [self setName:@"Transmission Line"];
        [self setLabel:@"TL"];
        [self setLabelPosition:MI_DIRECTION_UP];
        MI_ConnectionPoint* A1 = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-25.0f, 9.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"A1"
         nodeNumberPlacement:MI_DIRECTION_NORTHWEST] autorelease];
        MI_ConnectionPoint* A2 = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(-25.0f, -9.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"A2"
         nodeNumberPlacement:MI_DIRECTION_SOUTHWEST] autorelease];
        MI_ConnectionPoint* B1 = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(25.0f, 9.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"B1"
         nodeNumberPlacement:MI_DIRECTION_NORTHEAST] autorelease];
        MI_ConnectionPoint* B2 = [[[MI_ConnectionPoint alloc]
            initWithPosition:NSMakePoint(25.0f, -9.0f)
                        size:NSMakeSize(6.0f, 6.0f)
                        name:@"B2"
         nodeNumberPlacement:MI_DIRECTION_SOUTHEAST] autorelease];
        connectionPoints = [[NSDictionary dictionaryWithObjectsAndKeys:
            A1, @"A1", A2, @"A2", B1, @"B1", B2, @"B2", NULL] retain];
        [parameters setObject:@"DefaultTransmissionLine" forKey:@"Model"];
    }
    return self;
}

- (void) draw
{
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [super draw];
    // Draw input/output hooks
    [bp moveToPoint:NSMakePoint(position.x - 25.0f, position.y + 9.0f)];
    [bp relativeLineToPoint:NSMakePoint(  8.0f,   0.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f, -18.0f)];
    [bp relativeLineToPoint:NSMakePoint( -8.0f,   0.0f)];
    [bp relativeMoveToPoint:NSMakePoint( 42.0f,   0.0f)];
    [bp relativeLineToPoint:NSMakePoint(  8.0f,   0.0f)];
    [bp relativeMoveToPoint:NSMakePoint(  0.0f,  18.0f)];
    [bp relativeLineToPoint:NSMakePoint( -8.0f,   0.0f)];
    [bp stroke];
    // Draw middle vertical line
    bp = [NSBezierPath bezierPath];
    [bp setLineWidth:2.0f];
    [bp moveToPoint:NSMakePoint(position.x, position.y + 12.0f)];
    [bp relativeLineToPoint:NSMakePoint(0.0f, -5.0f)];
    [bp relativeMoveToPoint:NSMakePoint(0.0f, -4.5f)];
    [bp relativeLineToPoint:NSMakePoint(0.0f, -5.0f)];
    [bp relativeMoveToPoint:NSMakePoint(0.0f, -4.5f)];
    [bp relativeLineToPoint:NSMakePoint(0.0f, -5.0f)];
    [bp stroke];
    // Draw frame
    [NSBezierPath strokeRect:NSMakeRect(position.x - 17.0f, position.y - 12.0f, 34.0f, 24.0f)];
    // Draw primary side indicator
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(position.x - 14.0f, position.y + 7.0f, 3.0f, 3.0f)] fill];
    [super endDraw];
}


- (MI_DeviceModelType) usedDeviceModelType
{
    return TRANSMISSION_LINE_DEVICE_MODEL_TYPE;
}


- (NSString*) shapeToSVG
{
    NSMutableString* svg = [NSMutableString stringWithCapacity:100];
    // input/output hooks
    [svg appendFormat:@"%@<path stroke=\"black\" fill=\"none\" d=\"M %g %g h 8 m 0 -18 h -8 m 42 0 h 8 m 0 18 h -8\"/>",
        [super shapeToSVG], position.x - 25.0f, position.y + 9.0f];
    // middle vertical line
    [svg appendFormat:@"<path stroke-width=\"2\" stroke=\"black\" fill=\"none\" d=\"M %g %g v -5 m 0 -4.5 v -5 m 0 -4.5 v -5\"/>",
        position.x, position.y + 12.0f];
    // frame
    [svg appendFormat:@"\n<rect stroke=\"black\" fill=\"none\" x=\"%g\" y=\"%g\" width=\"34\" height=\"24\"/>",
        position.x - 17.0f, position.y - 12.0f];
    // primary side indicator
    [svg appendFormat:@"\n<circle stroke=\"black\" fill=\"black\" cx=\"%g\" cy=\"%g\" r=\"1.5\"/>%@",
        position.x - 12.5f, position.y + 8.5f, [super endSVG]];
    return svg;
}

@end





