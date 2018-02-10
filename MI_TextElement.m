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

- (id) init
{
    if (self = [super init])
    {
        [self setName:@"Text Element"];
        [self setLabel:@"Text"];
        textFont = [NSFont userFontOfSize:0]; // default font is system-wide user font
        textColor = [[NSColor blackColor] retain]; // default color is black
        labelPosition = MI_DIRECTION_NONE;
        drawsFrame = NO;
        locked = NO;
    }
    return self;
}


- (void) setFont:(NSFont*) newFont
{
    if (!locked)
    {
        [newFont retain];
        if (textFont != nil)
            [textFont release];
        textFont = newFont;
    }
}

- (NSFont*) font
{
    return textFont;
}

- (void) setColor:(NSColor*) newColor
{
    if (!locked)
    {
        [newColor retain];
        [textColor release];
        textColor = newColor;
    }
}

- (NSColor*) color
{
    return textColor;
}

- (void) lock
{
    locked = YES;
}

- (void) unlock
{
    locked = NO;
}


- (BOOL) drawsFrame
{
    return drawsFrame;
}


- (void) setDrawsFrame:(BOOL)drawFrame
{
    drawsFrame = drawFrame;
}


- (void) draw
{
    [super draw];
    NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:
        textFont, NSFontAttributeName, textColor, NSForegroundColorAttributeName, NULL];
    NSSize s = [label sizeWithAttributes:attributes];
    if (drawsFrame)
        [NSBezierPath strokeRect:NSMakeRect(position.x - s.width/2.0f - 3.0f,
            position.y - s.height/2.0f - 3.0f, s.width + 6.0f, s.height + 6.0f)];
    /*
    [label drawAtPoint:NSMakePoint(position.x - s.width/2.0, position.y - s.height/2.0)
       withAttributes:attributes];
     */
    // workaround for clipping bug
    [MI_TroubleShooter drawString:label
                       attributes:attributes
                          atPoint:NSMakePoint(position.x - s.width/2.0, position.y - s.height/2.0)
                         rotation:rotation];
    [super endDraw];
}

// overrides parent method
- (NSSize) size
{
    NSSize s = [label sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
        textFont, NSFontAttributeName, textColor, NSForegroundColorAttributeName, NULL]];
    s.width = fabs(s.width * cos(rotation)) + fabs(s.height * sin(rotation));
    s.height = fabs(s.height * cos(rotation)) + fabs(s.width * sin(rotation));
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
    NSSize s = [label sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
        textFont, NSFontAttributeName, textColor, NSForegroundColorAttributeName, NULL]];
    NSColor* c = [textColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    return [NSString stringWithFormat:@"%@<text transform=\"translate(0,%g) scale(1,-1) translate(0,%g)\" x=\"%g\" y=\"%g\" stroke=\"none\" fill=\"rgb(%g%%,%g%%,%g%%)\" font-family=\"%@\" font-size=\"%g\">%@</text>%@",
        [super shapeToSVG], position.y, -position.y,
        position.x - s.width/2.0f, position.y + s.height/2.0f + [textFont descender] - 1.0f,
        //[c redComponent]*100, [c greenComponent]*100, [c blueComponent]*100,
        [c redComponent]*100, [c greenComponent]*100, [c blueComponent]*100,
        [textFont familyName], [textFont pointSize],
        [MI_SVGConverter filterSpecialCharacters:label], [super endSVG]];
}


/********************** NSCoding methods *********************/

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super initWithCoder:decoder])
    {
        textFont = [[decoder decodeObjectForKey:@"TextFont"] retain];
        textColor = [[decoder decodeObjectForKey:@"TextColor"] retain];
        drawsFrame = [decoder decodeBoolForKey:@"DrawsFrame"];
        locked = NO;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:textFont
                   forKey:@"TextFont"];
    [encoder encodeObject:textColor
                   forKey:@"TextColor"];
    [encoder encodeBool:drawsFrame
                 forKey:@"DrawsFrame"];
}

/************************* NSCopying methods ****************/

- (id) copyWithZone:(NSZone*) zone
{
    MI_TextElement* myCopy = [super copyWithZone:zone];
    [myCopy setFont:[self font]];
    [myCopy setColor:[self color]];
    [myCopy setDrawsFrame:[self drawsFrame]];
    return myCopy;
}

- (id) mutableCopyWithZone:(NSZone*) zone
{
    return [self copyWithZone:zone];
}

/************************************************************/

- (void) dealloc
{
    [textFont release];
    [textColor release];
    [super dealloc];
}

@end
