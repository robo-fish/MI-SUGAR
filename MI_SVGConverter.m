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
#import "MI_SVGConverter.h"
#import "MI_SchematicElement.h"
#import "MI_ElementConnector.h"

static const NSString* SVG_PREAMBLE = @"<?xml version=\"1.0\" encoding=\"iso-8859-1\" standalone=\"no\"?>\n<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">";

static NSString* xmlSpecialCharacters = @"<>&'\"";


@implementation MI_SVGConverter

+ (NSString*) schematicToSVG:(MI_Schematic*)schematic
{
    NSRect drawingArea = NSInsetRect([schematic boundingBox], -10.0f, -10.0f);
    
    NSMutableString* svg = [NSMutableString stringWithCapacity:1000];

    // Header
    [svg appendFormat:@"%@\n<svg width=\"%g\" height=\"%g\" viewBox=\"%g %g %g %g\" xmlns=\"http://www.w3.org/2000/svg\">",
        SVG_PREAMBLE, drawingArea.size.width, drawingArea.size.height,
        drawingArea.origin.x, drawingArea.origin.y,
        drawingArea.origin.x + drawingArea.size.width,
        drawingArea.origin.y + drawingArea.size.height];

    [svg appendFormat:@"\n<!-- Created by MI-SUGAR %@  -  http://www.macinit.com -->", MISUGAR_VERSION];

    // Add a transformation which flips the image over vertically.
    // We need this because the coordinate system of Cocoa drawing and SVG are inverse on the vertical axis.
    [svg appendFormat:@"\n<g transform=\"translate(0,%g) scale(1,-1) translate(0,%g)\">",
        drawingArea.origin.y + drawingArea.size.height/2.0,
        -drawingArea.origin.y - drawingArea.size.height/2.0];

    // Add schematic elements
    [svg appendString:@"\n<!-- Circuit Elements -->"];
    NSEnumerator* elementEnum = [schematic elementEnumerator];
    MI_SchematicElement* currentElement;
    while (currentElement = [elementEnum nextObject])
    {
        [svg appendFormat:@"\n<!-- %@ : %@ -->", [currentElement name],
            ([[currentElement label] length] > 0) ? [currentElement label] : @""];
        [svg appendFormat:@"\n%@",[currentElement shapeToSVG]];
    }
    
    // Add element connectors
    [svg appendString:@"\n<!-- Connection Lines -->"];
    NSEnumerator* connectorEnum = [schematic connectorEnumerator];
    MI_ElementConnector* currentConnector;
    while (currentConnector = [connectorEnum nextObject])
        [svg appendFormat:@"\n%@",[currentConnector shapeToSVG]];
    
    // Add element quickinfo
    if ([schematic showsQuickInfo])
    {
        NSFont *quickInfoFont = [[MI_SchematicElement labelFontAttributes] objectForKey:NSFontNameAttribute];
        NSDictionary* quickInfoFontAttributes = [MI_SchematicElement labelFontAttributes];
        NSString* qInfo;
        NSSize quickInfoSize;
        float quickInfoPositionX;
        float quickInfoPositionY;
        elementEnum = [schematic elementEnumerator];
        while (currentElement = [elementEnum nextObject])
        {
            if (!(qInfo = [currentElement quickInfo]))
                continue;
            quickInfoSize = [qInfo sizeWithAttributes:quickInfoFontAttributes];
            // The quick info will be shown at the position opposite to the label
            switch ([currentElement labelPosition])
            {
                case MI_DIRECTION_LEFT:
                    quickInfoPositionX = [currentElement position].x + [currentElement size].width/2.0f + 2.0f;
                    quickInfoPositionY = [currentElement position].y - quickInfoSize.height/2.0f;
                    break;
                case MI_DIRECTION_RIGHT:
                    quickInfoPositionX = [currentElement position].x - [currentElement size].width/2.0f - quickInfoSize.width - 2.0f;
                    quickInfoPositionY = [currentElement position].y - quickInfoSize.height/2.0f;
                    break;
                case MI_DIRECTION_UP:
                    quickInfoPositionX = [currentElement position].x - quickInfoSize.width/2.0f;
                    quickInfoPositionY = [currentElement position].y - [currentElement size].height/2.0f - quickInfoSize.height - 2.0f;
                    break;
                default: /* MI_DIRECTION_DOWN */
                    quickInfoPositionX = [currentElement position].x - quickInfoSize.width/2.0f;
                    quickInfoPositionY = [currentElement position].y + [currentElement size].height/2.0f + 2.0f;
            }
            [svg appendFormat:@"\n<text stroke=\"none\" fill=\"rgb(14.5%%,36.47%%,27.45%%)\" transform=\"translate(0,%g) scale(1,-1) translate(0,%g)\" x=\"%g\" y=\"%g\" font-family=\"%@\" font-size=\"%g\">%@</text>",
                quickInfoPositionY + quickInfoSize.height/2.0,
                -quickInfoPositionY - quickInfoSize.height/2.0f,
                quickInfoPositionX,
                quickInfoPositionY + [quickInfoFont descender],
                [quickInfoFont familyName], [quickInfoFont pointSize],
                [MI_SVGConverter filterSpecialCharacters:qInfo]];
        }
    }

    // End flipping vertically
    [svg appendString:@"\n</g>"];
    // End SVG
    [svg appendString:@"\n</svg>\n"];
    
    return svg;
}


+ (NSString*) filterSpecialCharacters:(NSString*)input
{
    NSMutableString* filteredLabel = [NSMutableString stringWithString:input];
    NSCharacterSet* cs = [NSCharacterSet characterSetWithCharactersInString:xmlSpecialCharacters];
    NSRange theRange = [filteredLabel rangeOfCharacterFromSet:cs];
    while (theRange.location != NSNotFound)
    {
        char x = [filteredLabel characterAtIndex:theRange.location];
        switch (x)
        {
            case '<':
                [filteredLabel replaceCharactersInRange:theRange
                                             withString:@"&lt;"];
                theRange.location += 4;
                break;
            case '>':
                [filteredLabel replaceCharactersInRange:theRange
                                             withString:@"&gt;"];
                theRange.location += 4;
                break;
            case '&':
                [filteredLabel replaceCharactersInRange:theRange
                                             withString:@"&amp;"];
                theRange.location += 5;
                break;
            case '\'':
                [filteredLabel replaceCharactersInRange:theRange
                                             withString:@"&apos;"];
                theRange.location += 6;
                break;
            case '"':
                [filteredLabel replaceCharactersInRange:theRange
                                             withString:@"&quot;"];
                theRange.location += 6;
                break;
            default: /* that's impossible. do nothing */;
        }
        theRange = [filteredLabel rangeOfCharacterFromSet:cs
                                                  options:0
                                                    range:NSMakeRange(theRange.location,
                                                                      [filteredLabel length] - theRange.location)];
    }
    return [NSString stringWithString:filteredLabel];
}

@end
