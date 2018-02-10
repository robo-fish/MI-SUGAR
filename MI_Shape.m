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
#import "MI_Shape.h"

const float MI_SHAPE_MAX_EXTENT = 200.0f;


@implementation MI_Shape

- (id) init
{
    if (self = [super init])
    {
        connectionPoints = [[NSMutableDictionary alloc] initWithCapacity:6];
        size = NSMakeSize(0, 0);
    }
    return self;
}


- (NSDictionary*) connectionPoints
{
    return [NSDictionary dictionaryWithDictionary:connectionPoints];
}


- (void) setConnectionPoints:(NSDictionary*)newConnectionPoints
{
    [connectionPoints setDictionary:newConnectionPoints];
}


- (NSSize) size
{
    return size;
}


- (void) drawAtPoint:(NSPoint)position
{
}


- (NSString*) shapeToSVG
{
    return @"";
}


/************* NSCoding methods *******************/

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init])
    {
        connectionPoints = [[decoder decodeObjectForKey:@"ShapeConnectionPoints"] retain];
        size = [decoder decodeSizeForKey:@"ShapeSize"];
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:connectionPoints
                   forKey:@"ShapeConnectionPoints"];
    [encoder encodeSize:size
                 forKey:@"ShapeSize"];
}


/******** NSCopying protocol implementation *********/


- (id) copyWithZone:(NSZone*) zone
{
    MI_Shape* myCopy = [[[self class] allocWithZone:zone] init];
    [myCopy setConnectionPoints:[self connectionPoints]];
    myCopy->size = [self size];
    return myCopy;
}


/***************/


- (void) dealloc
{
    [connectionPoints release];
    [super dealloc];
}

@end