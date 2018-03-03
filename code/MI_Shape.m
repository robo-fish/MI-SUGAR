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

@interface MI_Shape ()
@property (readwrite) NSSize size;
@end

@implementation MI_Shape
{
@protected
  NSSize _size;
}

@synthesize size = _size;

- (instancetype) initWithSize:(NSSize)size_
{
  if (self = [super init])
  {
    _size = size_;
  }
  return self;
}

- (instancetype) init
{
  return [self initWithSize:NSMakeSize(0, 0)];
}

- (void) drawAtPoint:(NSPoint)position
{
}

- (NSString*) shapeToSVG
{
    return @"";
}

/************* NSCoding implementation *******************/

- (id)initWithCoder:(NSCoder *)decoder
{
  if (self = [super init])
  {
    _connectionPoints = [decoder decodeObjectForKey:@"ShapeConnectionPoints"];
    _size = [decoder decodeSizeForKey:@"ShapeSize"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  if (_connectionPoints != nil)
  {
    [encoder encodeObject:_connectionPoints forKey:@"ShapeConnectionPoints"];
  }
  [encoder encodeSize:_size forKey:@"ShapeSize"];
}

/******** NSCopying implementation *********/

- (id) copyWithZone:(NSZone*) zone
{
  MI_Shape* myCopy = [[[self class] allocWithZone:zone] init];
  myCopy.connectionPoints = self.connectionPoints;
  myCopy.size = self.size;
  return myCopy;
}

@end
