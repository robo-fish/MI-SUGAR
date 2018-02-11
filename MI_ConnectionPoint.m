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
{
  NSSize _size; // size is needed although the point is invisible
  NSString* _name;
  MI_Direction _preferredNodeNumberPlacement;
  int MI_version; // see version note above
}

- (instancetype) initWithPosition:(NSPoint)myRelativePos
                   size:(NSSize)theSize
                   name:(NSString*)myName
    nodeNumberPlacement:(MI_Direction)nodePlacement;
{
  if (self == [super init])
  {
    self.relativePosition = myRelativePos;
    _size = theSize;
    _name = [myName copy];
    _preferredNodeNumberPlacement = nodePlacement;
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
            nodeNumberPlacement:MI_DirectionNone];
}


- (NSString*) name
{
  return _name;
}


- (NSSize) size
{
  return _size;
}


- (MI_Direction) preferredNodeNumberPlacement
{
    return _preferredNodeNumberPlacement;
}


/******************** NSCoding methods *******************/


- (id)initWithCoder:(NSCoder*)decoder
{
  if (self = [super init])
  {
    MI_version = [decoder decodeIntForKey:@"Version"];
    _name = [decoder decodeObjectForKey:@"Name"];
    self.relativePosition = [decoder decodePointForKey:@"Position"];
    _size = [decoder decodeSizeForKey:@"Size"];
    _preferredNodeNumberPlacement = [decoder decodeIntForKey:@"NodeNumberPlacement"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:MI_version forKey:@"Version"];
  [encoder encodeObject:_name forKey:@"Name"];
  [encoder encodePoint:self.relativePosition forKey:@"Position"];
  [encoder encodeSize:_size forKey:@"Size"];
  [encoder encodeInt:_preferredNodeNumberPlacement forKey:@"NodeNumberPlacement"];
}

/******************* NSCopying protocol implementation ******************/

- (id) copyWithZone:(NSZone*) zone
{
    return [[[self class] allocWithZone:zone] initWithPosition:self.relativePosition
                                                          size:_size
                                                          name:_name
                                           nodeNumberPlacement:_preferredNodeNumberPlacement];
}


@end
