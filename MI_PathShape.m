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
#import "MI_PathShape.h"


@implementation MI_PathShape

- (id) initWithSize:(NSSize)theSize;
{
    if (self = [super init])
    {
        size = theSize;
        filledPaths = [[NSMutableArray alloc] initWithCapacity:10];
        outlinePaths = [[NSMutableArray alloc] initWithCapacity:10];
        svgEquivalent = @"";
    }
    return self;
}


- (NSArray*) filledPaths
{
    return [NSArray arrayWithArray:filledPaths];
}


- (NSArray*) outlinePaths
{
    return [NSArray arrayWithArray:outlinePaths];
}


- (void) setFilledPaths:(NSArray*)newFilledPaths
{
    if (filledPaths == nil)
        filledPaths = [[NSMutableArray alloc] initWithCapacity:10];
    [filledPaths setArray:newFilledPaths];
}


- (void) setOutlinePaths:(NSArray*)newPaths
{
    if (outlinePaths == nil)
        outlinePaths = [[NSMutableArray alloc] initWithCapacity:10];
    [outlinePaths setArray:newPaths];
}


- (void) setSVGEquivalent:(NSString*)theSVGShape
{
    [theSVGShape retain];
    [svgEquivalent release];
    svgEquivalent = theSVGShape;
}


- (NSString*) shapeToSVG
{
    if (!svgEquivalent)
        svgEquivalent = @"";
    return [NSString stringWithString:svgEquivalent];
}


// overrides parent method to draw the shape
- (void) drawAtPoint:(NSPoint)position
{
    // It is assumed that all paths start with an absolute move command.
    // This requires a shift in the coordinate origin in order to position
    // the shape correctly on the canvas.
    NSBezierPath *path, *tmp;
    NSEnumerator* pathEnum = [outlinePaths objectEnumerator];
    
    NSGraphicsContext* currentContext = [NSGraphicsContext currentContext];
    [currentContext saveGraphicsState];
    NSAffineTransform* offsetTransform = [NSAffineTransform transform];
    [offsetTransform translateXBy:position.x
                              yBy:position.y];
    [offsetTransform concat];
    
    while (path = [pathEnum nextObject])
    {
        tmp = [NSBezierPath bezierPath];
        [tmp moveToPoint:position];
        [tmp appendBezierPath:path];
        [tmp stroke];
    }
    pathEnum = [filledPaths objectEnumerator];
    while (path = [pathEnum nextObject])
    {
        tmp = [NSBezierPath bezierPath];
        [tmp moveToPoint:position];
        [tmp appendBezierPath:path];
        [tmp fill];
    }

    [currentContext restoreGraphicsState];
}

/************* NSCoding methods *******************/

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super initWithCoder:decoder])
    {
        filledPaths = [[decoder decodeObjectForKey:@"PathShapeFilledPaths"] retain];
        outlinePaths = [[decoder decodeObjectForKey:@"PathShapeOutlinePaths"] retain];
        svgEquivalent = [[decoder decodeObjectForKey:@"SVGEquivalent"] retain];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:filledPaths
                   forKey:@"PathShapeFilledPaths"];
    [encoder encodeObject:outlinePaths
                   forKey:@"PathShapeOutlinePaths"];
    [encoder encodeObject:svgEquivalent
                   forKey:@"SVGEquivalent"];
}

/******** NSCopying protocol implementation *********/

- (id) copyWithZone:(NSZone*) zone
{
    MI_PathShape* myCopy = [super copyWithZone:zone];
    [myCopy setFilledPaths:[[[NSArray alloc] initWithArray:filledPaths
                                         copyItems:YES] autorelease]];
    [myCopy setOutlinePaths:[[[NSArray alloc] initWithArray:outlinePaths
                                                  copyItems:YES] autorelease]];
    [myCopy setSVGEquivalent:[self shapeToSVG]];
    return myCopy;
}

/***************/


- (void) dealloc
{
    [filledPaths release];
    [outlinePaths release];
    [svgEquivalent release];
    [super dealloc];
}

@end
