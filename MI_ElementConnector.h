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
#define MI_ELEMENT_CONNECTOR_VERSION 1
/*
 Version | Note
 -----------------------
    0    | MI-SUGAR 0.5 and 0.5.1
    1    | MI-SUGAR 0.5.2
*/

/* Represent a directed connection between the connection points of
two schematics elements*/
@interface MI_ElementConnector : NSObject <NSCoding, NSCopying>
{
    NSString* startElementID; // unique identifier of the schematic element at the start
    NSString* endElementID; // unique identifier of the schematic element at the end
    NSString* startPointName; // name of the connection point at the start
    NSString* endPointName; // name of the connection point at the end
    NSPoint* route; // array of NSPoint structs
    int numberOfRoutePoints;
    BOOL needsRouting; // indicates to the schematic that a new route has to be calculated
    BOOL isHighlighted;
    BOOL hasBeenTraversed; // used when converting the schematic
    int MI_version; // needed for archiving
}
- (NSString*) startElementID;

- (NSString*) endElementID;

- (void) setStartElementID:(NSString*)newStartElementID;

- (void) setEndElementID:(NSString*)newEndElementID;

- (NSString*) startPointName;

- (NSString*) endPointName;

- (void) setStartPointName:(NSString*)newStartPointName;

- (void) setEndPointName:(NSString*)newEndPointName;

/* Usually called by the schematic managing object after it has calculated a new route. */
- (void) setRoute:(NSPoint*)newRoute
   numberOfPoints:(unsigned)numOfPoints;

- (NSPoint*) route;

- (int) numberOfRoutePoints;

- (void) setNeedsRouting:(BOOL)needsRouting;

- (BOOL) needsRouting;

- (void) setHighlighted:(BOOL)highlighted;

- (BOOL) hasBeenTraversed;

- (void) setTraversed:(BOOL)traversed;

- (void) draw;

// Returns the graphical representation of the connector in SVG format.
- (NSString*) shapeToSVG;

@end
