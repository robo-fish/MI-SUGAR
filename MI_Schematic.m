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
#import "MI_Schematic.h"
#import "MI_CircuitElement.h"
#import "MI_TroubleShooter.h"
#include <math.h>

int MI_alignsVertically = 0x01;
int MI_alignsHorizontally = 0x02;

NSString* MI_SCHEMATIC_MODIFIED_NOTIFICATION = @"MI-SUGAR Schematic Change Notification";
NSString* MI_SCHEMATIC_ADD_CHANGE = @"Add";
NSString* MI_SCHEMATIC_DELETE_CHANGE = @"Delete";
NSString* MI_SCHEMATIC_CONNECT_CHANGE = @"Connect";
NSString* MI_SCHEMATIC_DISCONNECT_CHANGE = @"Disconnect";
NSString* MI_SCHEMATIC_MOVE_CHANGE = @"Move";
NSString* MI_SCHEMATIC_EDIT_PROPERTY_CHANGE = @"Edit Property";

//#define MI_SINGLE_LINE_ROUTE;

@implementation MI_Schematic
{
  NSMutableArray* elements; // MI_SchematicElement objects
  NSMutableArray* connectors; // MI_ElementConnector objects
  NSMutableArray* selectedElements;
  BOOL hasBeenModified;
  BOOL showsQuickInfo;
  BOOL calculateBoundingBoxForSelectedElementsOnly;
}

- (instancetype) init
{
    if (self = [super init])
    {
        elements = [[NSMutableArray alloc] initWithCapacity:10];
        connectors = [[NSMutableArray alloc] initWithCapacity:10];
        selectedElements = [[NSMutableArray alloc] initWithCapacity:5];
        hasBeenModified = NO;
        showsQuickInfo = NO;
        calculateBoundingBoxForSelectedElementsOnly = NO;
    }
    return self;
}


- (BOOL) addElement:(MI_SchematicElement*)newElement
{
    if (![elements containsObject:newElement])
    {
        [elements addObject:newElement];
        [self markAsModified:YES];
        return YES;
    }
    else
        return NO;
}


- (BOOL) removeElement:(MI_SchematicElement*)element
{
    if (![elements containsObject:element])
        return NO;
    else
    {
        // Remove all connectors that are connected to the object
        NSEnumerator* pointEnum = [[element connectionPoints] objectEnumerator];
        MI_ConnectionPoint* currentPoint;
        while (currentPoint = [pointEnum nextObject])
            [self removeConnector:
                [self connectorForConnectionPoint:currentPoint
                                        ofElement:element]];
        // remove target
        [elements removeObject:element];
        [self markAsModified:YES];
    }
    return YES;
}


- (void) removeSelectedElements
{
    NSEnumerator* selectedEnum = [selectedElements objectEnumerator];
    MI_SchematicElement* currentElement;
    while (currentElement = [selectedEnum nextObject])
        [self removeElement:currentElement];
    [self deselectAll];
}


- (NSEnumerator*) elementEnumerator
{
    return [elements objectEnumerator];
}


- (unsigned long) numberOfElements
{
    return [elements count];
}


- (BOOL) containsElement:(MI_SchematicElement*)element
{
    return [elements containsObject:element];
}


- (void) addConnector:(MI_ElementConnector*)newConnector
{
    [connectors addObject:newConnector];
    [self markAsModified:YES];
}


- (BOOL) removeConnector:(MI_ElementConnector*)connector
{
    unsigned long index = [connectors indexOfObject:connector];
    if (index == NSNotFound)
        return NO;
    [connectors removeObjectAtIndex:index];
    [self markAsModified:YES];
    return YES;
}


- (NSEnumerator*) connectorEnumerator
{
    return [connectors objectEnumerator];
}


- (NSSize) size
{
    // The size of the schematic is the extend of the bounding box,
    // which encloses all elements.
    return [self boundingBox].size;
    
}


- (NSRect) boundingBox
{
    if ([elements count] == 0)
        return NSMakeRect(0, 0, 0, 0);
    
    float minX, minY, maxX, maxY;
    NSEnumerator* elementEnum;
    
    if (calculateBoundingBoxForSelectedElementsOnly)
        elementEnum = [selectedElements objectEnumerator];
    else
        elementEnum = [elements objectEnumerator];
    
    MI_SchematicElement* currentElement = [elementEnum nextObject];
    // Find circuit's lower left corner position
    NSRect totalRect = [currentElement totalRect];
    minX = totalRect.origin.x;
    minY = totalRect.origin.y;
    maxX = minX + totalRect.size.width;
    maxY = minY + totalRect.size.height;
    while (currentElement = [elementEnum nextObject])
    {
        totalRect = [currentElement totalRect];
        if (totalRect.origin.x < minX)
            minX = totalRect.origin.x;
        if ( (totalRect.origin.x + totalRect.size.width) > maxX)
            maxX = totalRect.origin.x + totalRect.size.width;
        if (totalRect.origin.y < minY)
            minY = totalRect.origin.y;
        if ( (totalRect.origin.y + totalRect.size.height) > maxY)
            maxY = totalRect.origin.y + totalRect.size.height;
    }
    return NSMakeRect(minX, minY, maxX - minX, maxY - minY);
}


- (NSRect) boundingBoxOfSelectedElements
{
    calculateBoundingBoxForSelectedElementsOnly = YES;
    NSRect box = [self boundingBox];
    calculateBoundingBoxForSelectedElementsOnly = NO;
    return box;
}


- (BOOL) hasBeenModified
{
    return hasBeenModified;
}


- (void) markAsModified:(BOOL)modified
{
    hasBeenModified = modified;
    // Notify listeners
    [[NSNotificationCenter defaultCenter]
        postNotificationName:MI_SCHEMATIC_MODIFIED_NOTIFICATION
                      object:self];
}


- (MI_SchematicElement*) elementAtPosition:(NSPoint)targetPosition
{
    // Takes the bounding box of the element into consideration
    NSEnumerator* elementEnum = [elements objectEnumerator];
    MI_SchematicElement* tmpElement;
    NSSize elementSize;
    while ( tmpElement = [elementEnum nextObject] )
    {
        elementSize = [tmpElement size];
        if ( NSPointInRect(targetPosition,
                NSMakeRect([tmpElement position].x - (elementSize.width/2.0f) - 3.0f,
                           [tmpElement position].y - (elementSize.height/2.0f) - 3.0f,
                           elementSize.width + 6.0f,
                           elementSize.height + 6.0f) ) )
             return tmpElement;
    }
    return nil;
}


- (MI_ConnectionPoint*) connectionPointOfElement:(MI_SchematicElement*)element
                             forRelativePosition:(NSPoint)relPosition
{
  for (MI_ConnectionPoint* currentPoint in [[element connectionPoints] allValues])
  {
    /*
    NSLog(@"relative position = (%f, %f)", relPosition.x, relPosition.y);
    NSLog(@"checking connection at (%f, %f)", [currentPoint relativePosition].x,
          [currentPoint relativePosition].y);
    */
    NSRect const rect = NSMakeRect([currentPoint relativePosition].x - [currentPoint size].width / 2,
                                   [currentPoint relativePosition].y - [currentPoint size].height / 2,
                                   [currentPoint size].width,
                                   [currentPoint size].height);
    if (NSPointInRect(relPosition, rect))
    {
      return currentPoint;
    }
  }
  return nil;
}


- (MI_ElementConnector*) connectorForConnectionPoint:(MI_ConnectionPoint*)point
                                           ofElement:(MI_SchematicElement*)element
{
    NSEnumerator* connectorEnum = [connectors objectEnumerator];
    MI_ElementConnector* tmpConnector;
    NSString* targetElementID = [element identifier];
    while (tmpConnector = [connectorEnum nextObject])
        if ( ([[tmpConnector startElementID] isEqualToString:targetElementID] &&
              [[tmpConnector startPointName] isEqualToString:[point name]]) ||
             ([[tmpConnector endElementID] isEqualToString:targetElementID] &&
              [[tmpConnector endPointName] isEqualToString:[point name]]) )
            return tmpConnector;
    return nil;
}


- (NSPoint*) makeRouteFrom:(NSPoint)start
                        to:(NSPoint)end
            numberOfPoints:(unsigned*)number
             previousRoute:(NSPoint*)oldRoute
    previousNumberOfPoints:(int)oldNumPoints
{
    NSPoint* route;
#ifdef MI_SINGLE_LINE_ROUTE
    // Route consists of a single line
    route = (NSPoint*) malloc(2 * sizeof(NSPoint));
    route[0] = start;
    route[1] = end;
    *number = 2;
#else
    // 3-Point route, consisting of two orthogonal lines
    // The previous route can be in the reverse direction
    BOOL reverse = NO;
    if ( oldRoute && (oldNumPoints > 2) && (oldRoute[2].x == start.x) && (oldRoute[2].y == start.y) )
        reverse = YES;

    route = (NSPoint*) malloc(3 * sizeof(NSPoint));
    route[0] = reverse ? end : start;
    route[2] = reverse ? start : end;
    *number = 3;
    // Calculate the middle point.
    // Within a distance from the start point the user can choose whether the route starts horizontally or vertically.
    if ( ((((end.x - start.x) * (end.x - start.x)) + ((end.y - start.y) * (end.y - start.y))) < 225.0f) ||
         (oldRoute == NULL) || (oldNumPoints < 3) )
    {
        /* We are either very close to the starting point and the direction of the first line
        can still be changed, or we don't know the history of the connector's route. */
        if ( fabs(end.x - start.x) > fabs(end.y - start.y) )
            route[1] = NSMakePoint(route[2].x, route[0].y);
        else
            route[1] = NSMakePoint(route[0].x, route[2].y);
    }
    else
    {
        // We use the previous route to determine the middle point
        if ( oldRoute[1].x == oldRoute[0].x )
            route[1] = NSMakePoint(route[0].x, route[2].y);
        else
            route[1] = NSMakePoint(route[2].x, route[0].y);
    }
#endif
    return route;
}


- (void) calculateRouteForConnector:(MI_ElementConnector*)theConnector
{
    // simple implementation for now
    unsigned numPoints;
    NSPoint startPosition, endPosition;
    MI_SchematicElement* startElement = [self elementForIdentifier:[theConnector startElementID]];
    MI_SchematicElement* endElement = [self elementForIdentifier:[theConnector endElementID]];
    MI_ConnectionPoint* startPoint = [[startElement connectionPoints] objectForKey:[theConnector startPointName]];
    MI_ConnectionPoint* endPoint = [[endElement connectionPoints] objectForKey:[theConnector endPointName]];
    startPosition = NSMakePoint([startElement position].x + [startPoint relativePosition].x,
                                [startElement position].y + [startPoint relativePosition].y);
    endPosition = NSMakePoint([endElement position].x + [endPoint relativePosition].x,
                              [endElement position].y + [endPoint relativePosition].y);

    NSPoint* route = [self makeRouteFrom:startPosition
                                      to:endPosition
                          numberOfPoints:&numPoints
                           previousRoute:[theConnector route]
                  previousNumberOfPoints:[theConnector numberOfRoutePoints]];

    [theConnector setRoute:route
            numberOfPoints:numPoints];
}


- (MI_SchematicElement*) elementForIdentifier:(NSString*)theIdentifier
{
    NSEnumerator* elementEnum = [elements objectEnumerator];
    MI_SchematicElement* tmpElement;
    while (tmpElement = [elementEnum nextObject])
        if ([[tmpElement identifier] isEqualToString:theIdentifier])
            return tmpElement;
    return nil;
}


- (void) draw
{
    NSEnumerator* elementEnum = [elements objectEnumerator];
    MI_SchematicElement* currentElement;
    NSEnumerator* connectorEnum = [connectors objectEnumerator];
    MI_ElementConnector* currentConnector;
    NSMutableDictionary *quickInfoFontAttributes;
    quickInfoFontAttributes = [NSMutableDictionary dictionaryWithCapacity:[[[MI_SchematicElement labelFontAttributes] allKeys] count]];
    [quickInfoFontAttributes setDictionary:[MI_SchematicElement labelFontAttributes]];
    [quickInfoFontAttributes setObject:[NSColor colorWithDeviceRed:37.0f/255.0f green:93.0f/255.0f blue:70.0f/255.0f alpha:1.0f]
                                forKey:NSForegroundColorAttributeName];

    while (currentElement = [elementEnum nextObject])
    {
        // Draw elements
        if ([selectedElements containsObject:currentElement] &&
            [NSGraphicsContext currentContextDrawingToScreen])
            [[NSColor redColor] set];
        else
            [[NSColor blackColor] set];
        [currentElement draw];
        
        // Draw QuickInfo
        if ( showsQuickInfo && ([currentElement quickInfo] != nil) )
        {
            NSString* qInfo = [currentElement quickInfo];
            NSSize quickInfoSize = [qInfo sizeWithAttributes:quickInfoFontAttributes];
            // The quick info will be shown at the position opposite to the label
            NSPoint quickInfoPosition;
            switch ([currentElement labelPosition])
            {
                case MI_DirectionLeft:
                    quickInfoPosition = NSMakePoint([currentElement position].x + [currentElement size].width/2.0f + 2.0f,
                        [currentElement position].y - quickInfoSize.height/2.0f);
                    break;
                case MI_DirectionRight:
                    quickInfoPosition = NSMakePoint([currentElement position].x - [currentElement size].width/2.0f -
                        quickInfoSize.width - 2.0f, [currentElement position].y - quickInfoSize.height/2.0f);
                    break;
                case MI_DirectionUp:
                    quickInfoPosition = NSMakePoint([currentElement position].x - quickInfoSize.width/2.0f,
                        [currentElement position].y - [currentElement size].height/2.0f - quickInfoSize.height - 2.0f);
                    break;
                default: /* MI_DirectionDown */
                    quickInfoPosition = NSMakePoint([currentElement position].x - quickInfoSize.width/2.0f,
                        [currentElement position].y + [currentElement size].height/2.0f + 2.0f);
            }
            /* use the workaround for the string clipping bug instead
            [qInfo drawAtPoint:quickInfoPosition
                withAttributes:quickInfoFontAttributes];
             */
            [MI_TroubleShooter drawString:qInfo
                               attributes:quickInfoFontAttributes
                                  atPoint:quickInfoPosition
                                 rotation:0.0f];
        }
    }
    
    // Draw connectors
    while (currentConnector = [connectorEnum nextObject])
    {
        if ([currentConnector needsRouting])
            [self calculateRouteForConnector:currentConnector];
        [currentConnector draw];
    }
}


- (MI_Alignment) checkAlignmentWithOtherConnectionPoints:(NSPoint)thePoint
                                    ofUnselectedElements:(BOOL)unselectedOnly
                                               tolerance:(float)tol
{
    NSEnumerator* elementEnum = [elements objectEnumerator];
    MI_SchematicElement* currentElement;
    NSEnumerator* connectionPointEnum;
    MI_ConnectionPoint* currentConnectionPoint;
    MI_Alignment align;
    align.verticalAlignmentPoint = NSMakePoint(0, 0);
    align.horizontalAlignmentPoint = NSMakePoint(0, 0);
    align.alignment = 0x00;
    BOOL horizontally = NO;
    BOOL vertically = NO;
    /* Check either all elements or only until both vertical and horizontal
        alignment has been detected. Stop checking for one kind of
        alignment after the first detection of that kind of alignment. */
    while (currentElement = [elementEnum nextObject])
    {
        if (unselectedOnly && [selectedElements containsObject:currentElement])
            continue;
        connectionPointEnum = [[currentElement alignableConnectionPoints] objectEnumerator];
        while (currentConnectionPoint = [connectionPointEnum nextObject])
        {
            if ( !vertically &&
                (fabs([currentElement position].x + [currentConnectionPoint relativePosition].x - thePoint.x) <= tol) )
            {
                align.verticalAlignmentPoint =
                    NSMakePoint([currentElement position].x + [currentConnectionPoint relativePosition].x,
                                [currentElement position].y + [currentConnectionPoint relativePosition].y);
                vertically = YES;
            }
            if ( !horizontally &&
                (fabs([currentElement position].y + [currentConnectionPoint relativePosition].y - thePoint.y) <= tol) )
            {
                align.horizontalAlignmentPoint =
                    NSMakePoint([currentElement position].x + [currentConnectionPoint relativePosition].x,
                                [currentElement position].y + [currentConnectionPoint relativePosition].y);
                horizontally = YES;
            }
            if (horizontally && vertically)
                break;
        }
        if (horizontally && vertically)
            break;
    }
    if (vertically)
        align.alignment = align.alignment | MI_alignsVertically;
    if (horizontally)
        align.alignment = align.alignment | MI_alignsHorizontally;
    return align;
}


- (MI_SchematicInfo*) infoForLocation:(NSPoint)location
{
  MI_SchematicElement* targetElement;
  MI_SchematicInfo* info = [[MI_SchematicInfo alloc] init];

  targetElement = [self elementAtPosition:location];

  if (targetElement != nil)
  {
    info.element = targetElement;
    NSPoint const relPosition = NSMakePoint( location.x - [targetElement position].x, location.y - [targetElement position].y );
    MI_ConnectionPoint* targetPoint = [self connectionPointOfElement:targetElement forRelativePosition:relPosition];
    if ( targetPoint != nil )
    {
      info.connectionPoint = targetPoint;
      if ([self connectorForConnectionPoint:targetPoint ofElement:targetElement])
      {
        info.isConnected = YES;
      }
    }
  }
  return info;
}


- (MI_ElementConnector*) connectorForPoint:(NSPoint)p
                                    radius:(float)r
{
    double startPointX = 0.0f, startPointY = 0.0f, endPointX = 0.0f, endPointY = 0.0f;
#ifndef MI_SINGLE_LINE_ROUTE
    NSPoint midPoint;
#else
    double startToEndDistance, pointToEndDistance, pointToStartDistance;
#endif
    MI_ElementConnector* currentConnector;
    NSEnumerator* connectorEnum = [connectors objectEnumerator];
    MI_ElementConnector* result = nil;
    // Check all connectors of the schematic
    while (currentConnector = [connectorEnum nextObject])
    {
        if ([currentConnector route] == NULL)
            continue;
        // Get the position of the end point
#ifdef MI_SINGLE_LINE_ROUTE
        endPointX = [currentConnector route][1].x;
        endPointY = [currentConnector route][1].y;
#else
        endPointX = [currentConnector route][2].x;
        endPointY = [currentConnector route][2].y;
        midPoint = [currentConnector route][1];
#endif        
        // Get the position of the start point
        startPointX = [currentConnector route][0].x;
        startPointY = [currentConnector route][0].y;
                
#ifdef MI_SINGLE_LINE_ROUTE
        startToEndDistance = sqrt( ((endPointX - startPointX) * (endPointX - startPointX)) +
                                   ((endPointY - startPointY) * (endPointY - startPointY)) );
        pointToStartDistance = sqrt( ((p.x - startPointX) * (p.x - startPointX)) +
                                     ((p.y - startPointY) * (p.y - startPointY)) );
        pointToEndDistance = sqrt( ((p.x - endPointX) * (p.x - endPointX)) +
                                   ((p.y - endPointY) * (p.y - endPointY)) );
        //NSLog(@"start-end: %f, p-start: %f, p-end: %f", startToEndDistance, pointToStartDistance, pointToEndDistance);
        
        /* A quick check: For each of the two connection points the given point must be closer
            than the other connection point. */
        if ( (startToEndDistance < pointToEndDistance) || (startToEndDistance < pointToStartDistance) )
            continue;

        if ( fabs(pointToEndDistance + pointToStartDistance - startToEndDistance) < r )
        {
            result = currentConnector;
            break;
        }
#else
        if (
             // Check if the point is between the start point and midpoint of the route
             (
              // horizontal segment
              ( (startPointX == midPoint.x) && (fabs(p.x - startPointX) < r) && 
                ( ( (midPoint.y > startPointY) && (p.y > startPointY) && (p.y < midPoint.y) ) ||
                  ( (midPoint.y < startPointY) && (p.y < startPointY) && (p.y > midPoint.y) ) )
              ) ||
              // vertical segment
              ( (startPointY == midPoint.y) && (fabs(p.y - startPointY) < r) &&
                ( ( (midPoint.x > startPointX) && (p.x > startPointX) && (p.x < midPoint.x) ) ||
                  ( (midPoint.x < startPointX) && (p.x < startPointX) && (p.x > midPoint.x) ) )
              )
             ) ||
             // Check if the point is between the midpoint and end point of the route
             (
              // horizontal segment
              ( (endPointX == midPoint.x) && (fabs(p.x - endPointX) < r) && 
                ( ( (midPoint.y > endPointY) && (p.y > endPointY) && (p.y < midPoint.y) ) ||
                  ( (midPoint.y < endPointY) && (p.y < endPointY) && (p.y > midPoint.y) ) )
              ) ||
              // vertical segment
              ( (endPointY == midPoint.y) && (fabs(p.y - endPointY) < r) &&
                ( ( (midPoint.x > endPointX) && (p.x > endPointX) && (p.x < midPoint.x) ) ||
                  ( (midPoint.x < endPointX) && (p.x < endPointX) && (p.x > midPoint.x) ) )
              )
             )
           )
            {
                result = currentConnector;
                break;
            }
#endif
    }
    return result;
}


- (void) splitConnector:(MI_ElementConnector*)connector
            withElement:(MI_SchematicElement <MI_InsertableSchematicElement>*)element
{
    MI_ElementConnector* newConnector1 = [[MI_ElementConnector alloc] init];
    MI_ElementConnector* newConnector2 = [[MI_ElementConnector alloc] init];
#ifdef MI_SINGLE_LINE_ROUTE
    MI_SchematicElement* startElement = [schematic elementForIdentifier:[conn startElementID]];
#else
    NSPoint* route = [connector route];
    NSPoint* route1 = (NSPoint*) malloc(3 * sizeof(NSPoint));
    NSPoint* route2 = (NSPoint*) malloc(3 * sizeof(NSPoint));
#endif

    [newConnector1 setStartElementID:[connector startElementID]];
    [newConnector1 setStartPointName:[connector startPointName]];
    [newConnector1 setEndElementID:[element identifier]];
    
    [newConnector2 setStartElementID:[element identifier]];
    [newConnector2 setEndElementID:[connector endElementID]];
    [newConnector2 setEndPointName:[connector endPointName]];
    
#ifdef MI_SINGLE_LINE_ROUTE
    if (fabs([startElement position].x - destination.x) >
        fabs([startElement position].y - destination.y) )
    {
        if ( ([startElement position].x - destination.x) > 0.0f )
        {
            [newConnector1 setEndPointName:[[element rightPoint] name]];
            [newConnector2 setStartPointName:[[element leftPoint] name]];
        }
        else
        {
            [newConnector1 setEndPointName:[[element leftPoint] name]];
            [newConnector2 setStartPointName:[[element rightPoint] name]];
        }
    }
    else
    {
        if ( ([startElement position].y - destination.y) > 0.0f )
        {
            [newConnector1 setEndPointName:[[element topPoint] name]];
            [newConnector2 setStartPointName:[[element bottomPoint] name]];
        }
        else
        {
            [newConnector1 setEndPointName:[[element bottomPoint] name]];
            [newConnector2 setStartPointName:[[element topPoint] name]];
        }
    }
#else
    // Assuming a 3-point route
    if (route[0].x == route[1].x) // midpoint and start point are on the same vertical
    {
        if ( fabs([element position].x - route[0].x) < fabs([element position].y - route[2].y) )
        {
            // Element will be inserted between the start point and the middle point
            MI_ConnectionPoint* startSideElementPoint = (route[0].y > route[1].y) ? [element topPoint] : [element bottomPoint];
            MI_ConnectionPoint* midSideElementPoint = (route[0].y > route[1].y) ? [element bottomPoint] : [element topPoint];
            [newConnector1 setEndPointName:[startSideElementPoint name]];
            route1[0] = route[0];
            route1[1] = NSMakePoint([element position].x + [startSideElementPoint relativePosition].x, route[0].y);
            route1[2] = NSMakePoint([element position].x + [startSideElementPoint relativePosition].x,
                                    [element position].y + [startSideElementPoint relativePosition].y);
            [newConnector2 setStartPointName:[midSideElementPoint name]];
            route2[0] = NSMakePoint([element position].x + [midSideElementPoint relativePosition].x,
                                    [element position].y + [midSideElementPoint relativePosition].y);
            route2[1] = NSMakePoint([element position].x + [midSideElementPoint relativePosition].x, route[1].y);
            route2[2] = route[2];
        }
        else
        {
            // Element will be inserted between the midpoint and the end point
            MI_ConnectionPoint* midSideElementPoint = (route[1].x < route[2].x) ? [element leftPoint] : [element rightPoint];
            MI_ConnectionPoint* endSideElementPoint = (route[1].x < route[2].x) ? [element rightPoint] : [element leftPoint];
            [newConnector1 setEndPointName:[midSideElementPoint name]];
            route1[0] = route[0];
            route1[1] = NSMakePoint(route[1].x, [element position].y + [midSideElementPoint relativePosition].y);
            route1[2] = NSMakePoint([element position].x + [midSideElementPoint relativePosition].x,
                                    [element position].y + [midSideElementPoint relativePosition].y);
            [newConnector2 setStartPointName:[endSideElementPoint name]];
            route2[0] = NSMakePoint([element position].x + [endSideElementPoint relativePosition].x,
                                    [element position].y + [endSideElementPoint relativePosition].y);
            route2[1] = NSMakePoint(route[2].x, [element position].y + [endSideElementPoint relativePosition].y);
            route2[2] = route[2];
        }
    }
    else // midpoint and start point are on the same horizontal
    {
        if ( fabs([element position].y - route[0].y) < fabs([element position].x - route[2].x) )
        {
            // element will inserted between the start point and the middle point
            MI_ConnectionPoint* startSideElementPoint = (route[0].x < route[1].x) ? [element leftPoint] : [element rightPoint];
            MI_ConnectionPoint* midSideElementPoint = (route[0].x < route[1].x) ? [element rightPoint] : [element leftPoint];
            [newConnector1 setEndPointName:[startSideElementPoint name]];
            route1[0] = route[0];
            route1[1] = NSMakePoint(route[0].x, [element position].y + [startSideElementPoint relativePosition].y);
            route1[2] = NSMakePoint([element position].x + [startSideElementPoint relativePosition].x,
                                    [element position].y + [startSideElementPoint relativePosition].y);
            [newConnector2 setStartPointName:[midSideElementPoint name]];
            route2[0] = NSMakePoint([element position].x + [midSideElementPoint relativePosition].x,
                                    [element position].y + [midSideElementPoint relativePosition].y);
            route2[1] = NSMakePoint(route[1].x, [element position].y + [midSideElementPoint relativePosition].y);
            route2[2] = route[2];
        }
        else
        {
            // element will inserted between the midpoint and the end point
            MI_ConnectionPoint* midSideElementPoint = (route[1].y < route[2].y) ? [element bottomPoint] : [element topPoint];
            MI_ConnectionPoint* endSideElementPoint = (route[1].y < route[2].y) ? [element topPoint] : [element bottomPoint];
            [newConnector1 setEndPointName:[midSideElementPoint name]];
            route1[0] = route[0];
            route1[1] = NSMakePoint([element position].x + [midSideElementPoint relativePosition].x, route[1].y);
            route1[2] = NSMakePoint([element position].x + [midSideElementPoint relativePosition].x,
                                    [element position].y + [midSideElementPoint relativePosition].y);
            [newConnector2 setStartPointName:[endSideElementPoint name]];
            route2[0] = NSMakePoint([element position].x + [endSideElementPoint relativePosition].x,
                                    [element position].y + [endSideElementPoint relativePosition].y);
            route2[1] = NSMakePoint([element position].x + [endSideElementPoint relativePosition].x, route[2].y);
            route2[2] = route[2];
        }
    }
    [newConnector1 setRoute:route1
             numberOfPoints:3];
    [newConnector2 setRoute:route2
             numberOfPoints:3];
#endif
    
    [newConnector1 setNeedsRouting:YES];
    [newConnector2 setNeedsRouting:YES];
    [self removeConnector:connector];
    [self addConnector:newConnector1];
    [self addConnector:newConnector2];
}


/**************************** Selection methods *******************/

- (void) selectElement:(MI_SchematicElement*)element
{
    if (![selectedElements containsObject:element])
        [selectedElements addObject:element];
}


- (void) deselectAll
{
    [selectedElements removeAllObjects];
}


- (void) deselectElement:(MI_SchematicElement*)element
{
    [selectedElements removeObject:element];
}


- (void) selectAllElementsInRect:(NSRect)rect
{
    NSEnumerator* elementEnum = [elements objectEnumerator];
    MI_SchematicElement* currentElement;
    [selectedElements removeAllObjects];
    while (currentElement = [elementEnum nextObject])
        if ( NSPointInRect([currentElement position], rect) )
            [selectedElements addObject:currentElement];
}


- (void) selectAllElements
{
    [selectedElements setArray:elements];
}


- (BOOL) isSelected:(MI_SchematicElement*)element
{
    return [selectedElements containsObject:element];
}


- (NSUInteger) numberOfSelectedElements
{
    return [selectedElements count];
}


- (MI_SchematicElement*) firstSelectedElement
{
    if ([selectedElements count] > 0)
        return [selectedElements objectAtIndex:0];
    else
        return nil;
}


- (NSEnumerator*) selectedElementEnumerator
{
  return [selectedElements objectEnumerator];
}

/***********************************************************************/

- (NSArray*) copyOfSelectedElements
{
  return [[NSArray alloc] initWithArray:selectedElements copyItems:YES];
}

/*********************** Transforming elements ***************************/

- (void) rotateSelectedElements:(float)angle
{
    NSEnumerator* elementEnum = [selectedElements objectEnumerator];
    MI_SchematicElement* currentElement;
    NSEnumerator* pointEnum;
    MI_ConnectionPoint* currentPoint;
    BOOL left = ( fabs(angle - 90.0f) < 5.0f ) ? YES : NO;
    BOOL right = ( fabs(angle + 90.0f) < 5.0f ) ? YES : NO;
    while (currentElement = [elementEnum nextObject])
    {
        [currentElement setRotation:([currentElement rotation] + angle)];
        // Update label positions
        if (left || right)
        {
            if ([currentElement labelPosition] == MI_DirectionUp)
                [currentElement setLabelPosition:(left ? MI_DirectionLeft : MI_DirectionRight)];
            else if ([currentElement labelPosition] == MI_DirectionLeft)
                [currentElement setLabelPosition:(left ? MI_DirectionDown : MI_DirectionUp)];
            else if ([currentElement labelPosition] == MI_DirectionDown)
                [currentElement setLabelPosition:(left ? MI_DirectionRight : MI_DirectionLeft)];
            else if ([currentElement labelPosition] == MI_DirectionRight)
                [currentElement setLabelPosition:(left ? MI_DirectionUp : MI_DirectionDown)];
        }
        
        pointEnum = [[currentElement connectionPoints] objectEnumerator];
        while (currentPoint = [pointEnum nextObject])
            [[self connectorForConnectionPoint:currentPoint
                                     ofElement:currentElement] setNeedsRouting:YES];
    }
}


- (void) flipSelectedElements:(BOOL)horizontally
{
    NSEnumerator* elementEnum = [selectedElements objectEnumerator];
    MI_SchematicElement* currentElement;
    NSEnumerator* pointEnum;
    MI_ConnectionPoint* currentPoint;
    while (currentElement = [elementEnum nextObject])
    {
        [currentElement flip:horizontally];
        // update label position
        if ([currentElement labelPosition] == MI_DirectionRight)
            [currentElement setLabelPosition:MI_DirectionLeft];
        else if ([currentElement labelPosition] == MI_DirectionLeft)
            [currentElement setLabelPosition:MI_DirectionRight];
        // update connection lines
        pointEnum = [[currentElement connectionPoints] objectEnumerator];
        while (currentPoint = [pointEnum nextObject])
            [[self connectorForConnectionPoint:currentPoint
                                     ofElement:currentElement] setNeedsRouting:YES];
    }
}


- (BOOL) showsQuickInfo { return showsQuickInfo; }

- (void) setShowsQuickInfo:(BOOL)show { showsQuickInfo = show; }


/********************** NSCoding methods *********************/

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super initWithCoder:decoder])
    {
        elements = [decoder decodeObjectForKey:@"Elements"];
        connectors = [decoder decodeObjectForKey:@"Connectors"];
        selectedElements = [[NSMutableArray alloc] initWithCapacity:5];
        hasBeenModified = NO;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:elements
                   forKey:@"Elements"];
    [encoder encodeObject:connectors
                   forKey:@"Connectors"];
}

/************************* NSCopying methods ****************/

- (id) copyWithZone:(NSZone*) zone
{
  MI_Schematic* myCopy = [super copyWithZone:zone];
  myCopy->elements = [[NSMutableArray alloc] initWithArray:elements copyItems:YES];
  myCopy->connectors = [[NSMutableArray alloc] initWithArray:connectors copyItems:YES];
  // Iterate over connectors and make sure they get connected to the right
  // element. This needs to be done because the ID of an element changes
  // when it's copied.
  NSEnumerator* connectorEnum = [myCopy connectorEnumerator];
  MI_ElementConnector* connector;
  MI_SchematicInfo* i;
  while (connector = [connectorEnum nextObject])
  {
    i = [myCopy infoForLocation:*[connector route]];
    [connector setStartElementID:[i.element identifier]];
    i = [myCopy infoForLocation:*([connector route] + [connector numberOfRoutePoints] - 1)];
    [connector setEndElementID:[i.element identifier]];
  }

  [myCopy setShowsQuickInfo:NO];
  [myCopy markAsModified:NO];
  return myCopy;
}


@end
