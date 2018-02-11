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


- (instancetype) initWithSize:(NSSize)theSize;
{
  if (self = [super initWithSize:theSize])
  {
    self.svgEquivalent = @"";
  }
  return self;
}

- (NSString*) shapeToSVG
{
    if (!self.svgEquivalent)
        self.svgEquivalent = @"";
    return [NSString stringWithString:self.svgEquivalent];
}


// overrides parent method to draw the shape
- (void) drawAtPoint:(NSPoint)position
{
  // It is assumed that all paths start with an absolute move command.
  // This requires a shift in the coordinate origin in order to position
  // the shape correctly on the canvas.

  NSGraphicsContext* currentContext = [NSGraphicsContext currentContext];
  [currentContext saveGraphicsState];
  NSAffineTransform* offsetTransform = [NSAffineTransform transform];
  [offsetTransform translateXBy:position.x yBy:position.y];
  [offsetTransform concat];

  for (NSBezierPath* path in self.outlinePaths)
  {
    NSBezierPath* tmp = [NSBezierPath bezierPath];
    [tmp moveToPoint:position];
    [tmp appendBezierPath:path];
    [tmp stroke];
  }

  for (NSBezierPath* path in self.filledPaths)
  {
    NSBezierPath* tmp = [NSBezierPath bezierPath];
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
    self.filledPaths = [decoder decodeObjectForKey:@"PathShapeFilledPaths"];
    self.outlinePaths = [decoder decodeObjectForKey:@"PathShapeOutlinePaths"];
    self.svgEquivalent = [decoder decodeObjectForKey:@"SVGEquivalent"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [super encodeWithCoder:encoder];
  [encoder encodeObject:self.filledPaths forKey:@"PathShapeFilledPaths"];
  [encoder encodeObject:self.outlinePaths forKey:@"PathShapeOutlinePaths"];
  [encoder encodeObject:self.svgEquivalent forKey:@"SVGEquivalent"];
}

/******** NSCopying protocol implementation *********/

- (id) copyWithZone:(NSZone*) zone
{
  MI_PathShape* myCopy = [super copyWithZone:zone];
  myCopy.filledPaths = [self.filledPaths copy];
  myCopy.outlinePaths = [self.outlinePaths copy];
  myCopy.svgEquivalent = [self shapeToSVG];
  return myCopy;
}

@end
