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
#import "MI_DIPShape.h"
#import "MI_SchematicElement.h"
#import "MI_TroubleShooter.h"

// the radius of the half sphere that represents the notch of the IC package
static const float NOTCH_RADIUS = 6.0f;


@implementation MI_DIPShape
{
@private
  int _numberOfPins;
}

- (instancetype) initWithNumberOfPins:(int)numPins
{
  NSSize const size = NSMakeSize(10.0f * numPins / 2, 36.0f);
  if (self = [super initWithSize:size])
  {
    self.name = nil;
    _numberOfPins = numPins;
    // Make sure the number of pins is an even number
    if (_numberOfPins % 2)
    {
      _numberOfPins++;
    }

    // Construct connection points
    NSMutableArray* pointNames = [NSMutableArray arrayWithCapacity:10];
    NSMutableArray* points = [NSMutableArray arrayWithCapacity:10];
    NSPoint pointPosition;

    for (int i = 1; i <= _numberOfPins; i++)
    {
      if (i > (_numberOfPins / 2))
          pointPosition = NSMakePoint(size.width/2 + 5.0f - (i - _numberOfPins/2) * 10.0f, size.height/2);
      else
          pointPosition = NSMakePoint(i * 10.0f - 5.0f - size.width/2, -size.height/2);

      [pointNames addObject:[NSString stringWithFormat:@"Pin%d", i]];
      [points addObject:[[MI_ConnectionPoint alloc]
          initWithPosition:pointPosition
                      size:NSMakeSize(6.0f, 6.0f)
                      name:[NSString stringWithFormat:@"Pin%d", i]]];
    }
    self.connectionPoints = [[NSDictionary alloc] initWithObjects:points forKeys:pointNames];
  }
  return self;
}


- (void) drawAtPoint:(NSPoint)position
{
  int const pinsPerSide = _numberOfPins / 2;
  NSSize const size = self.size;

  // Draw main body rectangle with rounded corners
  NSBezierPath* bp = [NSBezierPath bezierPath];
  [bp appendBezierPathWithArcWithCenter:NSMakePoint(position.x - size.width/2.0f + 2.0f, position.y - 11.0f)
                                 radius:2.0f
                             startAngle:270.0f
                               endAngle:180.0f
                              clockwise:YES];
  [bp relativeLineToPoint:NSMakePoint(0.0f, 22.0f)];
  [bp appendBezierPathWithArcWithCenter:NSMakePoint(position.x - size.width/2.0f + 2.0f, position.y + 11.0f)
                                 radius:2.0f
                             startAngle:180.0f
                               endAngle:90.0f
                              clockwise:YES];
  [bp relativeLineToPoint:NSMakePoint(size.width - 4.0f, 0.0f)];
  [bp appendBezierPathWithArcWithCenter:NSMakePoint(position.x + size.width/2.0f - 2.0f, position.y + 11.0f)
                                 radius:2.0f
                             startAngle:90.0f
                               endAngle:0.0f
                              clockwise:YES];
  [bp relativeLineToPoint:NSMakePoint(0.0f, -22.0f)];
  [bp appendBezierPathWithArcWithCenter:NSMakePoint(position.x + size.width/2.0f - 2.0f, position.y - 11.0f)
                                 radius:2.0f
                             startAngle:0.0f
                               endAngle:-90.0f
                              clockwise:YES];
  [bp closePath];
  [bp stroke];

  bp = [NSBezierPath bezierPath];
  // Move to lower left corner... and even further left
  [bp moveToPoint:NSMakePoint(position.x - size.width/2.0f + 5.0f,
                              position.y - 18.0f)];
  // For each pin pair (lower & upper) draw vertical line segments
  for (int i = 0; i < pinsPerSide; i++)
  {
      [bp relativeLineToPoint:NSMakePoint(  0.0f,   5.0f)];
      [bp relativeMoveToPoint:NSMakePoint(  0.0f,  26.0f)];
      [bp relativeLineToPoint:NSMakePoint(  0.0f,   5.0f)];
      [bp relativeMoveToPoint:NSMakePoint( 10.0f, -36.0f)];
  }
  // Draw the notch
  [bp moveToPoint:NSMakePoint(position.x - size.width/2.0f,
                              position.y - NOTCH_RADIUS)];
  [bp appendBezierPathWithArcWithCenter:NSMakePoint(position.x - size.width/2.0f, position.y)
                                 radius:NOTCH_RADIUS
                             startAngle:-90.0f
                               endAngle:90.0f];

  // Draw pin 1 indicator
  [bp appendBezierPathWithOvalInRect:
      NSMakeRect(position.x - size.width/2.0f + 4.0f,
                 position.y - 11.0f, 3.0f, 3.0f)];

  [bp stroke];

  // Draw subcircuit name
  if (_name != nil)
  {
    NSSize const nameStringSize = [_name sizeWithAttributes:[MI_SchematicElement labelFontAttributes]];
    NSPoint const place = NSMakePoint(position.x + (NOTCH_RADIUS - nameStringSize.width)/2.0f,
                                position.y - nameStringSize.height/2.0f);
    if (nameStringSize.width < size.width - NOTCH_RADIUS)
    {
      /* won't work because of text clipping bug in Cocoa
      [name drawAtPoint:place withAttributes:[MI_SchematicElement labelFontAttributes]];
      */
      [MI_TroubleShooter drawString:_name attributes:[MI_SchematicElement labelFontAttributes] atPoint:place rotation:0.0f];
    }
  }
}


- (NSString*) shapeToSVG
{
  NSSize const size = self.size;
  NSMutableString* svg = [NSMutableString stringWithCapacity:100];
  [svg appendFormat:@"<rect stroke=\"black\" fill=\"none\" x=\"%g\" y=\"-13\" width=\"%g\" height=\"26\" rx=\"2\" ry=\"2\"/>",
       size.width / -2.0f, size.width];
  // Drawing pins
  [svg appendFormat:@"\n<path stroke=\"black\" fill=\"none\" d=\"M %g -18",
      5.0f - size.width/2.0f];
  int pinsPerSide = _numberOfPins / 2;
  int i;
  for (i = 0; i < pinsPerSide; i++)
      [svg appendFormat:@" v 5 m 0 26 v 5 m 10 -36"];
  [svg appendString:@"\"/>"];
  // Drawing notch
  [svg appendFormat:@"\n<path stroke=\"black\" fill=\"none\" d=\"M %g %g a %g %g 0 0 1 0 %g\"/>",
      size.width / -2.0f, -NOTCH_RADIUS, NOTCH_RADIUS, NOTCH_RADIUS, 2 * NOTCH_RADIUS];
  // Draw pin 1 indicator
  [svg appendFormat:@"\n<circle stroke=\"black\" fill=\"none\" cx=\"%g\" cy=\"-9.5\" r=\"1.5\"/>",
       5.5f - size.width/2.0f];
  // Draw subcircuit name
  float fontSize = [[[MI_SchematicElement labelFontAttributes] objectForKey:NSFontAttributeName] pointSize];
  NSString* fontFamilyName = [[[MI_SchematicElement labelFontAttributes] objectForKey:NSFontAttributeName] familyName];
  NSSize nameStringSize = [_name sizeWithAttributes:[MI_SchematicElement labelFontAttributes]];
  if (nameStringSize.width < size.width - NOTCH_RADIUS)
      [svg appendFormat:@"\n<text transform=\"translate(0,%g) scale(1,-1) translate(0,%g)\" stroke=\"none\" fill=\"black\" font-family=\"%@\" font-size=\"%g\" x=\"%g\" y=\"%g\">%@</text>",
          nameStringSize.height/-2.0f, nameStringSize.height/2.0f, fontFamilyName, fontSize, (NOTCH_RADIUS - nameStringSize.width)/2.0f,
          [[[MI_SchematicElement labelFontAttributes] objectForKey:NSFontAttributeName] descender] - 1.0f - nameStringSize.height/2.0f,
          _name];

  return svg;
}

/************* NSCoding methods *******************/

- (id)initWithCoder:(NSCoder *)decoder
{
  if (self = [super initWithCoder:decoder])
  {
    self.name = [decoder decodeObjectForKey:@"DIPShapeName"];
    _numberOfPins = [decoder decodeIntForKey:@"DIPShapePinCount"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [super encodeWithCoder:encoder];
  [encoder encodeObject:self.name forKey:@"DIPShapeName"];
  [encoder encodeInt:_numberOfPins forKey:@"DIPShapePinCount"];
}

/******** NSCopying protocol implementation *********/

- (id) copyWithZone:(NSZone*) zone
{
  MI_DIPShape* myCopy = [super copyWithZone:zone];;
  myCopy.name = self.name;
  myCopy->_numberOfPins = _numberOfPins;
  return myCopy;
}

@end
