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
#import "MI_ConnectionPoint.h"


@implementation MI_ConnectionPoint

- (instancetype) initWithPosition:(NSPoint)myRelativePos
                   size:(NSSize)theSize
                   name:(NSString*)myName
    nodeNumberPlacement:(MI_Direction)nodePlacement;
{
  if (self == [super init])
  {
    relativePosition = myRelativePos;
    size = theSize;
    name = myName;
    preferredNodeNumberPlacement = nodePlacement;
    MI_version = MI_CONNECTION_POINT_VERSION;
  }
  return self;
}


- (instancetype) initWithPosition:(NSPoint)myRelativePos
                   size:(NSSize)theSize
                   name:(NSString*)myName
{
  return [self initWithPosition:myRelativePos
                           size:theSize
                           name:myName
            nodeNumberPlacement:MI_DIRECTION_NONE];
}


- (NSPoint) relativePosition
{
  return relativePosition;
}


- (void) setRelativePosition:(NSPoint)newPosition
{
  relativePosition = newPosition;
}


- (NSString*) name
{
  return [name copy];
}


- (NSSize) size
{
  return size;
}


- (MI_Direction) preferredNodeNumberPlacement
{
    return preferredNodeNumberPlacement;
}


/******************** NSCoding methods *******************/


- (id)initWithCoder:(NSCoder*)decoder
{
    if (self = [super init])
    {
        MI_version = [decoder decodeIntForKey:@"Version"];
        name = [decoder decodeObjectForKey:@"Name"];
        relativePosition = [decoder decodePointForKey:@"Position"];
        size = [decoder decodeSizeForKey:@"Size"];
        preferredNodeNumberPlacement = [decoder decodeIntForKey:@"NodeNumberPlacement"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:MI_version forKey:@"Version"];
  [encoder encodeObject:name forKey:@"Name"];
  [encoder encodePoint:relativePosition forKey:@"Position"];
  [encoder encodeSize:size forKey:@"Size"];
  [encoder encodeInt:preferredNodeNumberPlacement forKey:@"NodeNumberPlacement"];
}

/******************* NSCopying protocol implementation ******************/

- (id) copyWithZone:(NSZone*) zone
{
    return [[[self class] allocWithZone:zone] initWithPosition:relativePosition
                                                          size:size
                                                          name:name
                                           nodeNumberPlacement:preferredNodeNumberPlacement];
}


@end
