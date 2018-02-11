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
#include <stdlib.h>
#import "MI_SchematicElement.h"
#import "MI_ConnectionPoint.h"
#import "MI_TroubleShooter.h"
#import "MI_SVGConverter.h"

BOOL randomNumberGeneratorSeeded = NO;
NSDictionary* labelFontAttributes = nil;

@interface MI_SchematicElement ()
@property (readwrite) NSSize size;
@property (readwrite) NSSize originalSize;
@property (readwrite) int revision;
@end

@implementation MI_SchematicElement
{
@private
  NSString* identifier;
  BOOL flippedHorizontally;
  NSString* _label;
  float _rotation;
}

- (instancetype) initWithSize:(NSSize)size_
{
  if (self = [super init])
  {
    self.size = size_;
    self.originalSize = size_;
    identifier = [MI_SchematicElement newIdentifier];
    _connectionPoints = nil;                                     // initialized by subclasses
    self.name = @"schematic element";
    self.elementNamespace = @"misugar.basic";
    _rotation = 0.0f;
    self.position = NSMakePoint(0.0f, 0.0f);
    _label = @"";
    self.showsLabel = YES;
    self.labelPosition = MI_DirectionUp;
    flippedHorizontally = NO;
    self.revision = 0;                                           // the default value for all subclasses is 0
    self.comment = @"";
  }
  return self;
}

- (instancetype) init
{
  return [self initWithSize:NSMakeSize(0.0f, 0.0f)];
}

- (NSString*) identifier
{
  if (identifier == nil)
  {
    identifier = [MI_SchematicElement newIdentifier];
  }
  return [identifier copy];
}


- (BOOL) isEqual:(id)anotherObject
{
    return ([anotherObject isKindOfClass:[self class]] &&
            [identifier isEqualToString:[anotherObject identifier]]);    
}


- (NSString*) label
{
  return _label;
}

- (void) setLabel:(NSString*)newLabel
{
  _label = [newLabel stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}


- (NSImage*) image
{
    // Create the image of the schematics Element
    NSPoint tmpPosition = self.position;
    NSSize s = [self size]; // this line provides compatibility with MI_TextElement
    self.position = NSMakePoint(s.width / 2.0f + 1.0f, s.height / 2.0f + 1.0f);
    NSImage* myImage = [[NSImage alloc] init];
    [myImage setSize:NSMakeSize(s.width + 2.0f, s.height + 2.0f)];
    [myImage lockFocus];
    [self draw];
    [myImage unlockFocus];
    self.position = tmpPosition;
    return myImage;
}


- (NSString*) fullyQualifiedName
{
  if (self.elementNamespace && [self.elementNamespace length])
    return [NSString stringWithFormat:@"%@.%@", self.elementNamespace, self.name];
  else
    return [NSString stringWithString:self.name];
}

/***************************************** Geometric transforms *****************/

- (float) rotation
{
  return _rotation;
}

- (void) setRotation:(float)newRotation
{
  float angle = newRotation - _rotation; // difference angle

  _rotation += (flippedHorizontally ? -angle : angle);

  // Make sure the stored rotation value is between 0 and 360 (excluded)
  while (_rotation < 0.0f) _rotation += 360.0f;
  while (_rotation >= 360.0f) _rotation -= 360.0f;

  angle = angle * M_PI / 180.0f; // converting to radian

  // Updating the relative position of all connection points
  [self.connectionPoints enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, MI_ConnectionPoint * _Nonnull currentPoint, BOOL * _Nonnull stop) {
    NSPoint const currentPos = currentPoint.relativePosition;
    currentPoint.relativePosition = NSMakePoint(
      (currentPos.x * cos(angle)) - (currentPos.y * sin(angle)),
      (currentPos.y * cos(angle)) + (currentPos.x * sin(angle)) );
  }];

  // Update size
  newRotation = _rotation * M_PI / 180.0f;
  _size.width = fabs(self.originalSize.width * cos(newRotation)) + fabs(self.originalSize.height * sin(newRotation));
  _size.height = fabs(self.originalSize.height * cos(newRotation)) + fabs(self.originalSize.width * sin(newRotation));
}


- (void) flip:(BOOL)horizontally
{
    // Note that the size of an element does not change since it's positioned
    // at its geometric center.
    if (horizontally)
    {
        // Update connection point positions
        NSEnumerator* pointEnum = [self.connectionPoints objectEnumerator];
        MI_ConnectionPoint* currentPoint;
        while (currentPoint = [pointEnum nextObject])
            [currentPoint setRelativePosition:
                NSMakePoint(-[currentPoint relativePosition].x, [currentPoint relativePosition].y)];
        
        flippedHorizontally = !flippedHorizontally;
    }
    /*
    else
    {
        flippedVertically = !horizontally;
    }
    */
}


- (BOOL) flippedHorizontally
{
    return flippedHorizontally;
}


- (NSRect) totalRect
{
    NSSize s = [self size]; // compatible with MI_TextElement
    if (self.labelPosition == MI_DirectionNone || [self.label length] == 0)
        return NSMakeRect(self.position.x - s.width/2, self.position.y - s.height/2,
                          s.width, s.height);
    else
    {
        NSDictionary* attribs = [MI_SchematicElement labelFontAttributes];
        NSSize labelSize = [self.label sizeWithAttributes:attribs];
        if (self.labelPosition == MI_DirectionUp)
        {
            float maxWidth = fmax(labelSize.width, s.width);
            return NSMakeRect(self.position.x - maxWidth/2, self.position.y - s.height/2,
                              maxWidth, s.height + labelSize.height + 2.0f);
        }
        else if (self.labelPosition == MI_DirectionDown)
        {
            float maxWidth = fmax(labelSize.width, s.width);
            return NSMakeRect(self.position.x - maxWidth/2,
                              self.position.y - s.height/2 - labelSize.height - 2.0f,
                              maxWidth, s.height + labelSize.height + 2.0f);
        }
        else if (self.labelPosition == MI_DirectionLeft)
        {
            float maxHeight = fmax(labelSize.height, s.height);
            return NSMakeRect(self.position.x - s.width/2 - labelSize.width - 2.0f,
                              self.position.y - maxHeight/2,
                              s.width + labelSize.width + 2.0f, maxHeight);
        }
        else /*if (labelPosition == MI_DirectionRight)*/
        {
            float maxHeight = fmax(labelSize.height, s.height);
            return NSMakeRect(self.position.x - s.width/2,
                              self.position.y - maxHeight/2,
                              s.width + labelSize.width + 2.0f, maxHeight);
        }
    }
}


- (NSString*) quickInfo
{
    return nil;
}

/**************************************************************************************/

- (NSDictionary*) alignableConnectionPoints { return self.connectionPoints; } // default behavior


- (void) draw
{
    if (_rotation != 0.0f || flippedHorizontally)
    {
        // Rotate around geometrical center
        NSAffineTransform* transform1 = [NSAffineTransform transform];
        NSAffineTransform* transform2 = [NSAffineTransform transform];
        NSAffineTransform* transform3 = [NSAffineTransform transform];
        NSAffineTransform* transform4 = [NSAffineTransform transform];

        [[NSGraphicsContext currentContext] saveGraphicsState];
        [transform1 translateXBy:-self.position.x
                             yBy:-self.position.y];
        [transform2 rotateByDegrees:_rotation];
        [transform3 scaleXBy:-1.0f
                         yBy:1.0f];
        [transform4 translateXBy:self.position.x
                             yBy:self.position.y];

        [transform1 appendTransform:transform2]; // move center of element to origin and rotate
        if (flippedHorizontally)
            [transform1 appendTransform:transform3]; // flip the element over to the lef side
        [transform1 appendTransform:transform4]; // move from origin back to element position
        
        [transform1 concat];
    }
    
// DEBUG
/*
    NSEnumerator* connectionPointEnum = [connectionPoints objectEnumerator];
    MI_ConnectionPoint* currentPoint;
    while (currentPoint = [connectionPointEnum nextObject])
        [[NSBezierPath bezierPathWithOvalInRect:
            NSMakeRect(position.x + [currentPoint relativePosition].x + 1 - [currentPoint size].width/2.0f,
                       position.y + [currentPoint relativePosition].y + 1 - [currentPoint size].height/2.0f,
                       [currentPoint size].width - 2, [currentPoint size].height - 2)] fill];
*/
// DEBUG END
}

- (void) endDraw
{
    if (_rotation != 0.0f || flippedHorizontally)
        [[NSGraphicsContext currentContext] restoreGraphicsState];

    // Draw label using application-scope font attributes
    // Must come after the graphics context has been restored
    if (self.showsLabel &&
        (self.labelPosition != MI_DirectionNone) &&
        ([self.label length] > 0))
    {
        NSPoint labelLocation;
        NSDictionary* attribs = [MI_SchematicElement labelFontAttributes];
        if (self.labelPosition == MI_DirectionUp)
        {
            labelLocation.x = self.position.x - ([self.label sizeWithAttributes:attribs].width/2.0f);
            labelLocation.y = self.position.y + 2.0f + (self.size.height/2.0f);
        }
        else if (self.labelPosition == MI_DirectionDown)
        {
            labelLocation.x = self.position.x - ([self.label sizeWithAttributes:attribs].width/2.0f);
            labelLocation.y = self.position.y - 2.0f - [self.label sizeWithAttributes:attribs].height - (self.size.height/2.0f);
        }
        else if (self.labelPosition == MI_DirectionLeft)
        {
            labelLocation.x = self.position.x - 2.0f - [self.label sizeWithAttributes:attribs].width - (self.size.width/ 2.0f);
            labelLocation.y = self.position.y - ([self.label sizeWithAttributes:attribs].height/2.0f);
        }
        else /*if (labelPosition == MI_DirectionRight)*/
        {
            labelLocation.x = self.position.x + 2.0f + (self.size.width/ 2.0f);
            labelLocation.y = self.position.y - ([self.label sizeWithAttributes:attribs].height/2.0f);
        }
          
        // Cocoa does not handle clipping of NSString's correctly when using affine transforms
        /*
        [label drawAtPoint:labelLocation
            withAttributes:attribs];
         */
        // workaround:
        [MI_TroubleShooter drawString:self.label
                           attributes:attribs
                              atPoint:NSMakePoint(labelLocation.x, labelLocation.y)
                             rotation:0.0f];
    }
}


- (NSString*) shapeToSVG
{
    if (fabs(_rotation) > 1.0f || flippedHorizontally)
    {
        NSMutableString* s = [NSMutableString stringWithCapacity:50];
        [s appendFormat:@"<g transform=\"translate(%g,%g) ", self.position.x, self.position.y];
        if (flippedHorizontally)
            [s appendString:@"scale(-1,1) "];
        if (fabs(_rotation) > 1.0f)
            [s appendFormat:@"rotate(%g) ", _rotation];
        [s appendFormat:@"translate(%g,%g)\">\n", -self.position.x, -self.position.y];
        return s;
    }
    else
        return @"";
}

- (NSString*) endSVG
{
    NSMutableString* s = [NSMutableString stringWithCapacity:50];
    if (fabs(_rotation) > 1.0f || flippedHorizontally)
        [s appendString:@"\n</g>"];
    // Draw label text
    if (self.showsLabel &&
        (self.labelPosition != MI_DirectionNone) &&
        ([self.label length] > 0))
    {
        NSPoint labelLocation;
        NSDictionary* attribs = [MI_SchematicElement labelFontAttributes];
        if (self.labelPosition == MI_DirectionUp)
        {
            labelLocation.x = self.position.x - ([self.label sizeWithAttributes:attribs].width/2.0f);
            labelLocation.y = self.position.y + 2.0f + (self.size.height/2.0f);
        }
        else if (self.labelPosition == MI_DirectionDown)
        {
            labelLocation.x = self.position.x - ([self.label sizeWithAttributes:attribs].width/2.0f);
            labelLocation.y = self.position.y - 2.0f - [self.label sizeWithAttributes:attribs].height - (self.size.height/2.0f);
        }
        else if (self.labelPosition == MI_DirectionLeft)
        {
            labelLocation.x = self.position.x - 2.0f - [self.label sizeWithAttributes:attribs].width - (self.size.width/ 2.0f);
            labelLocation.y = self.position.y - ([self.label sizeWithAttributes:attribs].height/2.0f);
        }
        else /*if (labelPosition == MI_DirectionRight)*/
        {
            labelLocation.x = self.position.x + 2.0f + (self.size.width/ 2.0f);
            labelLocation.y = self.position.y - ([self.label sizeWithAttributes:attribs].height/2.0f);
        }
        //float yOffset = labelLocation.y + [label sizeWithAttributes:attribs].height/2.0f;
        [s appendFormat:@"\n<text stroke=\"none\" fill=\"black\" transform=\"translate(0,%g) scale(1,-1) translate(0,%g)\" x=\"%g\" y=\"%g\" font-family=\"%@\" font-size=\"%g\">%@</text>",
            labelLocation.y, -labelLocation.y, labelLocation.x, labelLocation.y - 1.0f + [[attribs objectForKey:NSFontAttributeName] descender],
            [[attribs objectForKey:NSFontAttributeName] familyName],
            [[attribs objectForKey:NSFontAttributeName] pointSize], [MI_SVGConverter filterSpecialCharacters:self.label]];
    }
    return s;
}

/******************** NSCoding methods *******************/

/*
Note: Pay attention to the encoding/decoding order. They
must be the same because we are not using keyed coding here.
*/

- (id)initWithCoder:(NSCoder *)decoder
{
  if (self = [super init])
  {
    identifier = [decoder decodeObjectForKey:@"Identifier"];
    self.name = [decoder decodeObjectForKey:@"Name"];

    self.elementNamespace = [decoder decodeObjectForKey:@"Namespace"];
    if (self.elementNamespace == nil)
        self.elementNamespace = @"";

    self.label = [decoder decodeObjectForKey:@"Label"];
    self.connectionPoints = [decoder decodeObjectForKey:@"ConnectionPoints"];

    self.comment = [decoder decodeObjectForKey:@"Comment"];
    if (self.comment == nil)
    {
      self.comment = [[NSMutableString alloc] initWithCapacity:25];
    }

    self.size = [decoder decodeSizeForKey:@"Size"];
    self.originalSize = [decoder decodeSizeForKey:@"OriginalSize"];
    self.position = [decoder decodePointForKey:@"Position"];
    _rotation = [decoder decodeFloatForKey:@"Rotation"];
    self.showsLabel = [decoder decodeBoolForKey:@"ShowsLabel"];
    self.labelPosition = [decoder decodeIntForKey:@"LabelPosition"];
    flippedHorizontally = [decoder decodeBoolForKey:@"FlippedHorizontally"];
    self.revision = [decoder decodeIntForKey:@"Revision"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:identifier
                 forKey:@"Identifier"];
  [encoder encodeObject:self.name
                 forKey:@"Name"];
  [encoder encodeObject:self.elementNamespace
                 forKey:@"Namespace"];
  [encoder encodeObject:self.label
                 forKey:@"Label"];
  [encoder encodeObject:self.connectionPoints
                 forKey:@"ConnectionPoints"];
  [encoder encodeObject:self.comment
                 forKey:@"Comment"];
  [encoder encodeSize:self.size
               forKey:@"Size"];
  [encoder encodeSize:self.originalSize
               forKey:@"OriginalSize"];
  [encoder encodePoint:self.position
                forKey:@"Position"];
  [encoder encodeFloat:_rotation
                forKey:@"Rotation"];
  [encoder encodeBool:self.showsLabel
               forKey:@"ShowsLabel"];
  [encoder encodeInt:self.labelPosition
              forKey:@"LabelPosition"];
  [encoder encodeBool:flippedHorizontally
               forKey:@"FlippedHorizontally"];
  [encoder encodeInt:self.revision
              forKey:@"Revision"];
}


/******************* NSCopying protocol implementation ******************/

- (id) copyWithZone:(NSZone*) zone
{
  MI_SchematicElement* myCopy = [[[self class] allocWithZone:zone] init];
  /* Must not copy the connection points:
     Every init method of a concrete schematic element builds its
     own connection points. */
  myCopy.name = self.name;
  myCopy.elementNamespace = self.elementNamespace;
  myCopy.position = self.position;
  myCopy.rotation = self.rotation;
  if (self.flippedHorizontally)
      [myCopy flip:YES];
  myCopy.label = self.label;
  myCopy.showsLabel = self.showsLabel;
  myCopy.labelPosition = self.labelPosition;
  myCopy.size = self.size;
  myCopy.originalSize = self.originalSize;
  myCopy.revision = self.revision;
  [myCopy setComment:[self comment]];
  return myCopy;
}

/************************************************************************/

+ (NSString*) newIdentifier
{
  if (!randomNumberGeneratorSeeded)
  {
    srandom( [[NSDate date] timeIntervalSince1970] );
    randomNumberGeneratorSeeded = YES;
  }
  return [NSString stringWithFormat:@"%@ %d", [[NSDate date] description], (int) random()];
}


+ (NSDictionary*) labelFontAttributes
{
  if (labelFontAttributes == nil)
    labelFontAttributes = @{
      NSFontAttributeName : [NSFont systemFontOfSize:10.0f],
      NSForegroundColorAttributeName : [NSColor blackColor]
    };
  return labelFontAttributes;
}


@end
