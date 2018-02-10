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
#import "MI_SubcircuitElement.h"
#import "SugarManager.h"


@implementation MI_SubcircuitElement

- (id) initWithDefinition:(MI_SubcircuitDocumentModel*)model
{
    if (self = [super init])
    {
        numberOfPins = [model numberOfPins];
        originalSize = size = [[model shape] size];
        [self setName:[model circuitName]];
        [self setElementNamespace:[model circuitNamespace]];
        [self setLabel:@"X"];
        [self setLabelPosition:MI_DIRECTION_RIGHT];
        [self setConnectionPoints:[[model shape] connectionPoints]];
    }
    return self;
}


- (int) numberOfPins
{
    return numberOfPins;
}


- (MI_SubcircuitDocumentModel*) definition
{
    return [[[SugarManager sharedManager] subcircuitLibraryManager]
        modelForSubcircuitName:[self fullyQualifiedName]];
}


- (void) draw
{
    [super draw];
    [[[self definition] shape] drawAtPoint:position];
    [super endDraw];
}


- (void) flip:(BOOL)horizontally
{
    /* Overrides parent implementation by doing nothing.
       Subcircuit representations are not allowed to be flipped over
       because it also mirrors the name on the body and confuses the
       user when it comes to pin numbers. */
}


- (NSString*) shapeToSVG
{
    return [NSString stringWithFormat:@"%@<g transform=\"translate(%g,%g)\">\n%@\n</g>%@", 
        [super shapeToSVG], position.x, position.y, [[[self definition] shape] shapeToSVG], [super endSVG]];
}

/******************** NSCoding methods *******************/

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super initWithCoder:decoder])
    {
        numberOfPins = [decoder decodeIntForKey:@"NumberOfPins"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:numberOfPins
                forKey:@"NumberOfPins"];
}

/******************* NSCopying protocol implementation ******************/

- (id) copyWithZone:(NSZone*) zone
{
    MI_SubcircuitElement* myCopy = [super copyWithZone:zone];
    myCopy->numberOfPins = numberOfPins;
    [myCopy setConnectionPoints:connectionPoints];
    /* Note: The original connection point objects of the master copy
        (in the elements panel) are shared among all copies. */
    return myCopy;
}

- (id) mutableCopyWithZone:(NSZone*) zone
{
    return [self copyWithZone:zone];
}

/************************************************************************/

- (void) dealloc
{
    [super dealloc];
}


@end
