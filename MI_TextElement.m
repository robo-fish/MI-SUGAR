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
#import "MI_TextElement.h"
#import "MI_TroubleShooter.h"
#import "MI_SVGConverter.h"

@implementation MI_TextElement
{
  BOOL _locked;
  NSFont* _textFont;
  NSColor* _textColor;
}

- (instancetype) init
{
  if (self = [super init])
  {
    self.name = @"Text Element";
    self.label = @"Text";
    _textFont = [NSFont userFontOfSize:0]; // the default font is the system-wide user font
    _textColor = [NSColor blackColor];
    self.labelPosition = MI_DirectionNone;
    self.drawsFrame = NO;
    _locked = NO;
  }
  return self;
}


- (void) setFont:(NSFont*) newFont
{
  if (!_locked)
  {
    _textFont = newFont;
  }
}

- (NSFont*) font
{
  return _textFont;
}

- (void) setColor:(NSColor*) newColor
{
  if (!_locked)
  {
    _textColor = newColor;
  }
}

- (NSColor*) color
{
  return _textColor;
}

- (void) lock
{
  _locked = YES;
}

- (void) unlock
{
  _locked = NO;
}

- (void) draw
{
  [super draw];
  NSDictionary* attributes = @{NSFontAttributeName : _textFont, NSForegroundColorAttributeName : _textColor};
  NSSize const s = [self.label sizeWithAttributes:attributes];
  if (self.drawsFrame)
  {
    [NSBezierPath strokeRect:NSMakeRect(self.position.x - s.width/2.0f - 3.0f,
          self.position.y - s.height/2.0f - 3.0f, s.width + 6.0f, s.height + 6.0f)];
  }
  /*
  [label drawAtPoint:NSMakePoint(position.x - s.width/2.0, position.y - s.height/2.0)
     withAttributes:attributes];
   */
  // workaround for clipping bug
  [MI_TroubleShooter drawString:self.label
                     attributes:attributes
                        atPoint:NSMakePoint(self.position.x - s.width/2.0, self.position.y - s.height/2.0)
                       rotation:self.rotation];
  [super endDraw];
}

// overrides parent method
- (NSSize) size
{
  NSSize s = [self.label sizeWithAttributes:@{NSFontAttributeName:_textFont, NSForegroundColorAttributeName:_textColor}];
  s.width = fabs(s.width * cos(self.rotation)) + fabs(s.height * sin(self.rotation));
  s.height = fabs(s.height * cos(self.rotation)) + fabs(s.width * sin(self.rotation));
  return s;
}

// Overrides parent method. Keeps the text from appearing twice in the schematic
- (void) setLabelPosition:(MI_Direction)newLabelPosition
{
}

// Don't allow text to be flipped by overriding parent implementation with empty one.
- (void) flip:(BOOL)horizontally
{
}

- (NSString*) shapeToSVG
{
  NSSize const s = [self.label sizeWithAttributes:@{NSFontAttributeName:_textFont, NSForegroundColorAttributeName:_textColor}];
  NSColor* c = [_textColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
  return [NSString stringWithFormat:@"%@<text transform=\"translate(0,%g) scale(1,-1) translate(0,%g)\" x=\"%g\" y=\"%g\" stroke=\"none\" fill=\"rgb(%g%%,%g%%,%g%%)\" font-family=\"%@\" font-size=\"%g\">%@</text>%@",
      [super shapeToSVG], self.position.y, -self.position.y,
      self.position.x - s.width/2.0f, self.position.y + s.height/2.0f + [_textFont descender] - 1.0f,
      //[c redComponent]*100, [c greenComponent]*100, [c blueComponent]*100,
      [c redComponent]*100, [c greenComponent]*100, [c blueComponent]*100,
      [_textFont familyName], [_textFont pointSize],
      [MI_SVGConverter filterSpecialCharacters:self.label], [super endSVG]];
}


/********************** NSCoding methods *********************/

- (id)initWithCoder:(NSCoder *)decoder
{
  if (self = [super initWithCoder:decoder])
  {
    _textFont = [decoder decodeObjectForKey:@"TextFont"];
    _textColor = [decoder decodeObjectForKey:@"TextColor"];
    _drawsFrame = [decoder decodeBoolForKey:@"DrawsFrame"];
    _locked = NO;
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [super encodeWithCoder:encoder];
  [encoder encodeObject:_textFont forKey:@"TextFont"];
  [encoder encodeObject:_textColor forKey:@"TextColor"];
  [encoder encodeBool:_drawsFrame forKey:@"DrawsFrame"];
}

/************************* NSCopying methods ****************/

- (id) copyWithZone:(NSZone*) zone
{
  MI_TextElement* myCopy = [super copyWithZone:zone];
  myCopy.font = self.font;
  myCopy.color = self.color;
  myCopy.drawsFrame = self.drawsFrame;
  return myCopy;
}

- (id) mutableCopyWithZone:(NSZone*) zone
{
  return [self copyWithZone:zone];
}

@end
