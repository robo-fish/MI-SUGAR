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
#import "MI_CircuitSchematic.h"
#import "MI_NodeAssignmentTableItem.h"
#import "MI_CircuitElement.h"
#import "MI_TroubleShooter.h"

#define ROUNDED_NODE_NUMBER_BACKGROUND

@implementation MI_CircuitSchematic
{
@private
  NSMutableArray* nodeAssignmentTable; // array of NodeAssignmentTableItem objects
  BOOL showsNodeNumbers;
  BOOL isSubcircuit;
  int MI_version;

  // Tracks the count of all types of circuit elements added to the schematic.
  // Keys are the class names of the dropped elements.
  // Values are integer NSNumber instances which hold the count of elements dropped on the canvas.
  // This is used to append numbers to the labels of dropped elements so the user
  // does not need to change the label of each element after dropping it.
  NSMutableDictionary* elementTypeRegistry;

  /**
   * This dictionary stores the font properties used for drawing node numbers
   */
  NSMutableDictionary *nodeNumberFontAttributes;
}

- (instancetype) init
{
    if (self = [super init])
    {
        isSubcircuit = NO;
        MI_version = MI_SCHEMATIC_VERSION;
        nodeAssignmentTable = [[NSMutableArray alloc] initWithCapacity:20];
        showsNodeNumbers = NO;
        elementTypeRegistry = [[NSMutableDictionary alloc] initWithCapacity:10];
        nodeNumberFontAttributes = nil;
    }
    return self;
}


/**
* The font attributes used to draw the node numbers must be set at every render pass
  to be effective. This slows down rendering.
* Thanks to Steffan Diedrichsen for pointing out that the background color too has
  to be set at every render pass.
*/
- (void) draw
{
    [super draw];
    
    // Draw assigned node numbers
    if ( showsNodeNumbers && ([nodeAssignmentTable count] > 0) )
    {
        NSEnumerator* nodePointEnum = [nodeAssignmentTable objectEnumerator];
        MI_NodeAssignmentTableItem* nodeTableItem;
        MI_SchematicElement* currentElement;
        MI_ConnectionPoint* currentPoint;
        int effectivePosition;
        float xOffset, yOffset;
        NSString* nodeNumberString;

        // Create background color
        NSColor* nodeNumberBackground =
            [NSColor colorWithDeviceRed: 63.0f/255.0f
                                  green: 76.0f/255.0f
                                   blue: 93.0f/255.0f
                                  alpha: 1.0f];
                                                          
        while (nodeTableItem = [nodePointEnum nextObject])
        {
            if ([nodeTableItem node] == -1 && [nodeTableItem nodeName] == nil)
                continue;
            currentElement = [self elementForIdentifier:[nodeTableItem elementID]];
            currentPoint = [[currentElement connectionPoints] objectForKey:[nodeTableItem pointName]];
            effectivePosition = (int)[currentPoint preferredNodeNumberPlacement];
            // Check the rotation and flip of the element and change the position accordingly
            if (effectivePosition != MI_DirectionNone)
            {
                if ([currentElement flippedHorizontally])
                {
                    switch (effectivePosition)
                    {
                        case MI_DirectionNortheast: effectivePosition = MI_DirectionNorthwest; break;
                        case MI_DirectionNorthwest: effectivePosition = MI_DirectionNortheast; break;
                        case MI_DirectionSoutheast: effectivePosition = MI_DirectionSouthwest; break;
                        case MI_DirectionSouthwest: effectivePosition = MI_DirectionSoutheast; break;
                        default: /*do nothing*/;
                    }
                }
                if (nearbyintf([currentElement rotation])/90.0f != 0.0f)
                {
                    /* Here, I am using the fact that MI_Direction is an integer where the directions
                    are values between 0 and 7 and are ordered counterclockwise */
                    if ([currentElement flippedHorizontally])
                    {
                        effectivePosition -= 2 * (int)nearbyintf([currentElement rotation] / 90.0f);
                        while (effectivePosition < 0) effectivePosition += 8;
                    }
                    else
                    {
                        effectivePosition += 2 * (int)nearbyintf([currentElement rotation] / 90.0f);
                        while (effectivePosition > 7) effectivePosition -= 8;
                    }
                }
            }
            // Using font metrics to calculate the final position
            if ([nodeTableItem nodeName] == nil)
                nodeNumberString = [NSString stringWithFormat:@"%d",[nodeTableItem node]];
            else
                nodeNumberString = [nodeTableItem nodeName];
            NSSize stringSize = [nodeNumberString sizeWithAttributes:nodeNumberFontAttributes];
            switch (effectivePosition)
            {
#ifdef ROUNDED_NODE_NUMBER_BACKGROUND
                case MI_DirectionNorthwest:
                    xOffset = -3.0f - stringSize.width - stringSize.height/2.0f;
                    yOffset = 3.0f;
                    break;
                case MI_DirectionNortheast:
                    xOffset = 3.0f + stringSize.height/2.0f;
                    yOffset = 3.0f;
                    break;
                case MI_DirectionSouthwest:
                    xOffset = -3.0f - stringSize.width - stringSize.height/2.0f;
                    yOffset = -3.0f - stringSize.height;
                    break;
                case MI_DirectionSoutheast:
                    xOffset = 3.0f + stringSize.height/2.0f;
                    yOffset = -3.0f - stringSize.height;
                    break;
#else
                case MI_DirectionNorthwest:
                    xOffset = -3.0f - stringSize.width;
                    yOffset = 3.0f;
                    break;
                case MI_DirectionNortheast:
                    xOffset = 3.0f;
                    yOffset = 3.0f;
                    break;
                case MI_DirectionSouthwest:
                    xOffset = -3.0f - stringSize.width;
                    yOffset = -3.0f - stringSize.height;
                    break;
                case MI_DirectionSoutheast:
                    xOffset = 3.0f;
                    yOffset = -3.0f - stringSize.height;
                    break;
#endif
                default: continue;
            }
            NSPoint place = NSMakePoint([currentElement position].x + [currentPoint relativePosition].x + xOffset,
                                        [currentElement position].y + [currentPoint relativePosition].y + yOffset);
            [nodeNumberBackground set];
            
            // Draw nodeNumberBackground
#ifdef ROUNDED_NODE_NUMBER_BACKGROUND
            NSBezierPath* bp = [NSBezierPath bezierPath];
            [bp appendBezierPathWithArcWithCenter:NSMakePoint(place.x - 0.5f,
                                                              place.y + stringSize.height/2.0f - 0.5f)
                                           radius:stringSize.height/2.0f
                                       startAngle:270.0f
                                         endAngle:90.0f
                                        clockwise:YES];
            [bp lineToPoint:NSMakePoint(place.x + stringSize.width + 1, place.y + stringSize.height - 0.5f)];
            [bp appendBezierPathWithArcWithCenter:NSMakePoint(place.x + stringSize.width + 1,
                                                              place.y + stringSize.height/2.0f - 0.5f)
                                           radius:stringSize.height/2.0f
                                       startAngle:90.0f
                                         endAngle:-90.0f
                                        clockwise:YES];
            [bp closePath];
            [bp fill];
            
#else
            [NSBezierPath fillRect:NSMakeRect(place.x - 1, place.y - 1, stringSize.width + 2, stringSize.height + 2)];
#endif

            if (nodeNumberFontAttributes != nil)
            {
                [nodeNumberFontAttributes removeObjectForKey:NSFontAttributeName];
                nodeNumberFontAttributes = nil;
            }
            nodeNumberFontAttributes = [[NSMutableDictionary alloc] initWithCapacity:
                [[[MI_SchematicElement labelFontAttributes] allKeys] count] ];
            [nodeNumberFontAttributes setDictionary:[MI_SchematicElement labelFontAttributes]];
            [nodeNumberFontAttributes setObject:[NSColor whiteColor]
                                         forKey:NSForegroundColorAttributeName];
            [nodeNumberFontAttributes setObject:[NSFont systemFontOfSize:9.0f]
                                         forKey:NSFontAttributeName];
            
            [nodeNumberString drawAtPoint:place
                           withAttributes:nodeNumberFontAttributes];
            
            /*this is a workaround for the string clipping bug but it has a problem: only one node number gets displayed
            [MI_TroubleShooter drawString:nodeNumberString
                               attributes:nodeNumberFontAttributes
                                  atPoint:place
                                 rotation:0.0f];
             */
        }
    }
}


- (void) setNodeAssignmentTable:(NSArray*)newAssignmentTable
{
    [nodeAssignmentTable setArray:newAssignmentTable];
}

- (BOOL) showsNodeNumbers { return showsNodeNumbers; }

- (void) setShowsNodeNumbers:(BOOL)show { showsNodeNumbers = show; }

- (BOOL) isSubcircuit { return isSubcircuit; }

- (void) setIsSubcircuit:(BOOL)subcircuit { isSubcircuit = subcircuit; }


// Adds to the parent implementation to provide automatic element labelling
- (BOOL) addElement:(MI_SchematicElement*)element
{
    if (![element conformsToProtocol:@protocol(MI_ElectricallyTransparentElement)] &&
        ![element conformsToProtocol:@protocol(MI_ElectricallyGroundedElement)])
    {
        // Automatically assign a new postfix to the droppedElement based on element type count
        if ([[element label] length] == 0)
            [element setLabel:[self postfixForElementType:[element className]]];
        else
        {
            // Check for a possible decimal digit suffix and remove it
            NSString* tmp = [element label];
            NSRange r = [tmp rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]
                                             options:NSBackwardsSearch];
            while ( ([tmp length] > 0) && (r.location == ([tmp length] - 1)) )
            {
                tmp = [tmp substringToIndex:([tmp length] - 1)];
                r = [tmp rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]
                                         options:NSBackwardsSearch];
            }
            
            [element setLabel:[tmp stringByAppendingString:[self postfixForElementType:[element className]]]];
        }
    }
    return [super addElement:element];
}


- (NSString*) postfixForElementType:(NSString*)type
{
    int postfix;
    if ([elementTypeRegistry objectForKey:type] != nil)
        postfix = [[elementTypeRegistry objectForKey:type] intValue];
    else
        postfix = 1;
    
    [elementTypeRegistry setObject:[NSNumber numberWithInt:postfix + 1]
                                forKey:type];

    return [NSString stringWithFormat:@"%d", postfix];
}

/********************** Archiving **********************/

- (instancetype) initWithCoder:(NSCoder*)decoder
{
  if (self = [super initWithCoder:decoder])
  {
    MI_version = [decoder decodeIntForKey:@"Version"];
    // Depending on the version decoding of the rest can be handled differently
    isSubcircuit = [decoder decodeBoolForKey:@"IsSubcircuit"];
    nodeAssignmentTable = [decoder decodeObjectForKey:@"NodeAssignmentTable"];
    showsNodeNumbers = NO;
    elementTypeRegistry = [decoder decodeObjectForKey:@"ElementTypeRegistry"];
    if (elementTypeRegistry == nil)
    {
      elementTypeRegistry = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
  }
  return self;
}


- (void) encodeWithCoder:(NSCoder*)encoder
{
  [super encodeWithCoder:encoder];
  [encoder encodeInt:MI_version forKey:@"Version"];
  [encoder encodeBool:isSubcircuit forKey:@"IsSubcircuit"];
  [encoder encodeObject:nodeAssignmentTable forKey:@"NodeAssignmentTable"];
  [encoder encodeObject:elementTypeRegistry forKey:@"ElementTypeRegistry"];
}

/************************* NSCopying methods ****************/

- (id) copyWithZone:(NSZone*) zone
{
  MI_CircuitSchematic* myCopy = [super copyWithZone:zone];
  [myCopy setIsSubcircuit:[self isSubcircuit]];
  [myCopy setNodeAssignmentTable:[nodeAssignmentTable copy]];
  if (myCopy->elementTypeRegistry == nil)
  {
    myCopy->elementTypeRegistry = [elementTypeRegistry copy];
  }
  [myCopy setShowsNodeNumbers:NO];
  return myCopy;
}

/*******************************************************/

- (void) dealloc
{
  if (nodeNumberFontAttributes != nil)
  {
    // System fonts must not be deallocated. remove from font attributes dictionary
    [nodeNumberFontAttributes removeObjectForKey:NSFontAttributeName];
    nodeNumberFontAttributes = nil;
  }
}

@end
