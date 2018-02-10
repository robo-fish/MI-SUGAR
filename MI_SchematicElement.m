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


@implementation MI_SchematicElement

- (id) init
{
    if (self = [super init])
    {
        identifier = [[MI_SchematicElement newIdentifier] retain];
        connectionPoints = nil;                                     // initialized by subclasses
        name = [[NSMutableString alloc] initWithCapacity:15];
        [name setString:@"schematic element"];
        [self setElementNamespace:@"macinit.basic"];
        rotation = 0.0f;
        position = NSMakePoint(0.0f, 0.0f);
        label = [[NSMutableString alloc] initWithCapacity:5];
        [label setString:@""];
        showsLabel = YES;
        labelPosition = MI_DIRECTION_UP;
        flippedHorizontally = NO;
        size = NSMakeSize(0.0f, 0.0f);
        revision = 0;                                               // the default value for all subclasses is 0
        comment = [[NSMutableString alloc] initWithCapacity:25];
    }
    return self;
}


- (NSString*) identifier
{
    if (identifier == nil)
        identifier = [[MI_SchematicElement newIdentifier] retain];
    return [NSString stringWithString:identifier];
}


- (BOOL) isEqual:(id)anotherObject
{
    return ([anotherObject isKindOfClass:[self class]] &&
            [identifier isEqualToString:[anotherObject identifier]]);    
}

- (NSSize) size {return size; }

- (NSPoint) position {return position; }

- (void) setPosition:(NSPoint)newPosition
{
    position = newPosition;
}

- (NSString*) label
{
    if (label == nil)
    {
        label = [[NSMutableString alloc] initWithCapacity:1];
        [label setString:@""];
    }
    return [NSString stringWithString:label];
}


- (void) setLabel:(NSString*)newLabel
{
    [label setString:
        [newLabel stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceCharacterSet]]];
}


- (NSImage*) image
{
    // Create the image of the schematics Element
    NSPoint tmpPosition = position;
    NSSize s = [self size]; // this line provides compatibility with MI_TextElement
    position = NSMakePoint(s.width / 2.0f + 1.0f, s.height / 2.0f + 1.0f);
    NSImage* myImage = [[NSImage alloc] init];
    [myImage setSize:NSMakeSize(s.width + 2.0f, s.height + 2.0f)];
    [myImage lockFocus];
    [self draw];
    [myImage unlockFocus];
    position = tmpPosition;
    return [myImage autorelease];
}

- (NSString*) name
{
    if (name == nil)
    {
        name = [[NSMutableString alloc] initWithCapacity:15];
        [name setString:@"schematic element"];
    }
    return [NSString stringWithString:name];
}

- (void) setName:(NSString*)newName
{
    [name setString:newName];
}

- (NSString*) elementNamespace
{
    return [NSString stringWithString:theNamespace];
}

- (void) setElementNamespace:(NSString*)newNamespace
{
    [newNamespace retain];
    [theNamespace release];
    theNamespace = newNamespace;
}


- (NSString*) fullyQualifiedName
{
    if (theNamespace && [theNamespace length])
        return [NSString stringWithFormat:@"%@.%@", theNamespace, name];
    else
        return [NSString stringWithString:name];
}


- (MI_Direction) labelPosition
{
    return labelPosition;
}

- (void) setLabelPosition:(MI_Direction)newLabelPosition
{
    labelPosition = newLabelPosition;
}


- (void) setShowsLabel:(BOOL)showLabel
{
    showsLabel = showLabel;
}

/***************************************** Geometric transforms *****************/

- (float) rotation {return rotation; }

- (void) setRotation:(float)newRotation
{
    float angle = newRotation - rotation; // difference angle
    
    rotation += (flippedHorizontally ? -angle : angle);

    // Make sure the stored rotation value is between 0 and 360 (excluded)
    while (rotation < 0.0f)
        rotation += 360.0f;
    while (rotation >= 360.0f)
        rotation -= 360.0f;

    angle = angle * M_PI / 180.0f; // convert to radian
    // Update the relative position of all connection points
    NSEnumerator* pointEnum = [connectionPoints objectEnumerator];
    MI_ConnectionPoint* currentPoint;
    while (currentPoint = [pointEnum nextObject])
        [currentPoint setRelativePosition:NSMakePoint(
            ([currentPoint relativePosition].x * cos(angle)) - ([currentPoint relativePosition].y * sin(angle)),
            ([currentPoint relativePosition].y * cos(angle)) + ([currentPoint relativePosition].x * sin(angle)) )];
    

    // Update size
    newRotation = rotation * M_PI / 180.0f;
    size.width = fabs(originalSize.width * cos(newRotation)) + fabs(originalSize.height * sin(newRotation));
    size.height = fabs(originalSize.height * cos(newRotation)) + fabs(originalSize.width * sin(newRotation));
}


- (void) flip:(BOOL)horizontally
{
    // Note that the size of an element does not change since it's positioned
    // at its geometric center.
    if (horizontally)
    {
        // Update connection point positions
        NSEnumerator* pointEnum = [connectionPoints objectEnumerator];
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
    if (labelPosition == MI_DIRECTION_NONE || [label length] == 0)
        return NSMakeRect(position.x - s.width/2, position.y - s.height/2,
                          s.width, s.height);
    else
    {
        NSDictionary* attribs = [MI_SchematicElement labelFontAttributes];
        NSSize labelSize = [label sizeWithAttributes:attribs];
        if (labelPosition == MI_DIRECTION_UP)
        {
            float maxWidth = fmax(labelSize.width, s.width);
            return NSMakeRect(position.x - maxWidth/2, position.y - s.height/2,
                              maxWidth, s.height + labelSize.height + 2.0f);
        }
        else if (labelPosition == MI_DIRECTION_DOWN)
        {
            float maxWidth = fmax(labelSize.width, s.width);
            return NSMakeRect(position.x - maxWidth/2,
                              position.y - s.height/2 - labelSize.height - 2.0f,
                              maxWidth, s.height + labelSize.height + 2.0f);
        }
        else if (labelPosition == MI_DIRECTION_LEFT)
        {
            float maxHeight = fmax(labelSize.height, s.height);
            return NSMakeRect(position.x - s.width/2 - labelSize.width - 2.0f,
                              position.y - maxHeight/2,
                              s.width + labelSize.width + 2.0f, maxHeight);
        }
        else /*if (labelPosition == MI_DIRECTION_RIGHT)*/
        {
            float maxHeight = fmax(labelSize.height, s.height);
            return NSMakeRect(position.x - s.width/2,
                              position.y - maxHeight/2,
                              s.width + labelSize.width + 2.0f, maxHeight);
        }
    }
}


- (NSString*) quickInfo
{
    return nil;
}


- (int) revision
{
    return revision;
}


- (NSString*) comment
{
    return [NSString stringWithString:comment];
}


- (void) setComment:(NSString*)newComment
{
    if (newComment != nil)
        [comment setString:newComment];
}


/**************************************************************************************/


- (NSDictionary*) connectionPoints {return connectionPoints; }

- (NSDictionary*) alignableConnectionPoints { return connectionPoints; } // default behavior

- (void) setConnectionPoints:(NSDictionary*)newConnectionPoints
{
    [newConnectionPoints retain];
    [connectionPoints release];
    connectionPoints = newConnectionPoints;
}


- (void) draw
{
    if (rotation != 0.0f || flippedHorizontally)
    {
        // Rotate around geometrical center
        NSAffineTransform* transform1 = [NSAffineTransform transform];
        NSAffineTransform* transform2 = [NSAffineTransform transform];
        NSAffineTransform* transform3 = [NSAffineTransform transform];
        NSAffineTransform* transform4 = [NSAffineTransform transform];

        [[NSGraphicsContext currentContext] saveGraphicsState];
        [transform1 translateXBy:-position.x
                             yBy:-position.y];
        [transform2 rotateByDegrees:rotation];
        [transform3 scaleXBy:-1.0f
                         yBy:1.0f];
        [transform4 translateXBy:position.x
                             yBy:position.y];

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
    if (rotation != 0.0f || flippedHorizontally)
        [[NSGraphicsContext currentContext] restoreGraphicsState];

    // Draw label using application-scope font attributes
    // Must come after the graphics context has been restored
    if (showsLabel &&
        (labelPosition != MI_DIRECTION_NONE) &&
        ([label length] > 0))
    {
        NSPoint labelLocation;
        NSDictionary* attribs = [MI_SchematicElement labelFontAttributes];
        if (labelPosition == MI_DIRECTION_UP)
        {
            labelLocation.x = position.x - ([label sizeWithAttributes:attribs].width/2.0f);
            labelLocation.y = position.y + 2.0f + (size.height/2.0f);
        }
        else if (labelPosition == MI_DIRECTION_DOWN)
        {
            labelLocation.x = position.x - ([label sizeWithAttributes:attribs].width/2.0f);
            labelLocation.y = position.y - 2.0f - [label sizeWithAttributes:attribs].height - (size.height/2.0f);
        }
        else if (labelPosition == MI_DIRECTION_LEFT)
        {
            labelLocation.x = position.x - 2.0f - [label sizeWithAttributes:attribs].width - (size.width/ 2.0f);
            labelLocation.y = position.y - ([label sizeWithAttributes:attribs].height/2.0f);
        }
        else /*if (labelPosition == MI_DIRECTION_RIGHT)*/
        {
            labelLocation.x = position.x + 2.0f + (size.width/ 2.0f);
            labelLocation.y = position.y - ([label sizeWithAttributes:attribs].height/2.0f);
        }
          
        // Cocoa does not handle clipping of NSString's correctly when using affine transforms
        /*
        [label drawAtPoint:labelLocation
            withAttributes:attribs];
         */
        // workaround:
        [MI_TroubleShooter drawString:label
                           attributes:attribs
                              atPoint:NSMakePoint(labelLocation.x, labelLocation.y)
                             rotation:0.0f];
    }
}


- (NSString*) shapeToSVG
{
    if (fabs(rotation) > 1.0f || flippedHorizontally)
    {
        NSMutableString* s = [NSMutableString stringWithCapacity:50];
        [s appendFormat:@"<g transform=\"translate(%g,%g) ", position.x, position.y];
        if (flippedHorizontally)
            [s appendString:@"scale(-1,1) "];
        if (fabs(rotation) > 1.0f)
            [s appendFormat:@"rotate(%g) ", rotation];
        [s appendFormat:@"translate(%g,%g)\">\n", -position.x, -position.y];
        return s;
    }
    else
        return @"";
}

- (NSString*) endSVG
{
    NSMutableString* s = [NSMutableString stringWithCapacity:50];
    if (fabs(rotation) > 1.0f || flippedHorizontally)
        [s appendString:@"\n</g>"];
    // Draw label text
    if (showsLabel &&
        (labelPosition != MI_DIRECTION_NONE) &&
        ([label length] > 0))
    {
        NSPoint labelLocation;
        NSDictionary* attribs = [MI_SchematicElement labelFontAttributes];
        if (labelPosition == MI_DIRECTION_UP)
        {
            labelLocation.x = position.x - ([label sizeWithAttributes:attribs].width/2.0f);
            labelLocation.y = position.y + 2.0f + (size.height/2.0f);
        }
        else if (labelPosition == MI_DIRECTION_DOWN)
        {
            labelLocation.x = position.x - ([label sizeWithAttributes:attribs].width/2.0f);
            labelLocation.y = position.y - 2.0f - [label sizeWithAttributes:attribs].height - (size.height/2.0f);
        }
        else if (labelPosition == MI_DIRECTION_LEFT)
        {
            labelLocation.x = position.x - 2.0f - [label sizeWithAttributes:attribs].width - (size.width/ 2.0f);
            labelLocation.y = position.y - ([label sizeWithAttributes:attribs].height/2.0f);
        }
        else /*if (labelPosition == MI_DIRECTION_RIGHT)*/
        {
            labelLocation.x = position.x + 2.0f + (size.width/ 2.0f);
            labelLocation.y = position.y - ([label sizeWithAttributes:attribs].height/2.0f);
        }
        //float yOffset = labelLocation.y + [label sizeWithAttributes:attribs].height/2.0f;
        [s appendFormat:@"\n<text stroke=\"none\" fill=\"black\" transform=\"translate(0,%g) scale(1,-1) translate(0,%g)\" x=\"%g\" y=\"%g\" font-family=\"%@\" font-size=\"%g\">%@</text>",
            labelLocation.y, -labelLocation.y, labelLocation.x, labelLocation.y - 1.0f + [[attribs objectForKey:NSFontAttributeName] descender],
            [[attribs objectForKey:NSFontAttributeName] familyName],
            [[attribs objectForKey:NSFontAttributeName] pointSize], [MI_SVGConverter filterSpecialCharacters:label]];
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
        identifier = [[decoder decodeObjectForKey:@"Identifier"] retain];
        name = [[decoder decodeObjectForKey:@"Name"] retain];
        
        theNamespace = [decoder decodeObjectForKey:@"Namespace"];
        if (theNamespace == nil)
            theNamespace = @"";
        [theNamespace retain];
        
        label = [[decoder decodeObjectForKey:@"Label"] retain];
        connectionPoints = [[decoder decodeObjectForKey:@"ConnectionPoints"] retain];
        
        comment = [decoder decodeObjectForKey:@"Comment"];
        if (comment == nil)
            comment = [[NSMutableString alloc] initWithCapacity:25];
        else
            [comment retain];
        
        size = [decoder decodeSizeForKey:@"Size"];
        originalSize = [decoder decodeSizeForKey:@"OriginalSize"];
        position = [decoder decodePointForKey:@"Position"];
        rotation = [decoder decodeFloatForKey:@"Rotation"];
        showsLabel = [decoder decodeBoolForKey:@"ShowsLabel"];
        labelPosition = [decoder decodeIntForKey:@"LabelPosition"];
        flippedHorizontally = [decoder decodeBoolForKey:@"FlippedHorizontally"];
        revision = [decoder decodeIntForKey:@"Revision"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:identifier
                   forKey:@"Identifier"];
    [encoder encodeObject:name
                   forKey:@"Name"];
    [encoder encodeObject:theNamespace
                   forKey:@"Namespace"];
    [encoder encodeObject:label
                   forKey:@"Label"];
    [encoder encodeObject:connectionPoints
                   forKey:@"ConnectionPoints"];
    [encoder encodeObject:comment
                   forKey:@"Comment"];
    [encoder encodeSize:size
                 forKey:@"Size"];
    [encoder encodeSize:originalSize
                 forKey:@"OriginalSize"];
    [encoder encodePoint:position
                  forKey:@"Position"];
    [encoder encodeFloat:rotation
                  forKey:@"Rotation"];
    [encoder encodeBool:showsLabel
                 forKey:@"ShowsLabel"];
    [encoder encodeInt:labelPosition
                forKey:@"LabelPosition"];
    [encoder encodeBool:flippedHorizontally
                 forKey:@"FlippedHorizontally"];
    [encoder encodeInt:revision
                forKey:@"Revision"];
}


/******************* NSCopying protocol implementation ******************/

- (id) copyWithZone:(NSZone*) zone
{
    MI_SchematicElement* myCopy = [[[self class] allocWithZone:zone] init];
    /* Must not copy the connection points:
       Every init method of a concrete schematic element builds its
       own connection points. */
    [myCopy setName:[self name]];
    [myCopy setElementNamespace:[self elementNamespace]];
    [myCopy setPosition:position];
    [myCopy setRotation:rotation];
    if (flippedHorizontally)
        [myCopy flip:YES];
    [myCopy setLabel:[self label]];
    [myCopy setShowsLabel:showsLabel];
    [myCopy setLabelPosition:labelPosition];
    myCopy->size = size;
    myCopy->originalSize = originalSize;
    myCopy->revision = revision;
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
        labelFontAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
        [NSFont systemFontOfSize:10.0f], NSFontAttributeName,
        [NSColor blackColor], NSForegroundColorAttributeName,
        NULL] retain];
    return labelFontAttributes;
}


- (void) dealloc
{
    [identifier release];
    [name release];
    [label release];
    [connectionPoints release];
    [comment release];
    [super dealloc];
}

@end
