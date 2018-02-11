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
#import "MI_SchematicElement.h"
#import "MI_ElementConnector.h"
#import "MI_ConnectionPoint.h"
#import "MI_SchematicInfo.h"

extern int MI_alignsVertically;
extern int MI_alignsHorizontally;

// Used for storing data about the point that alignment occurs with
typedef struct MI_Alignment_
{
    NSPoint horizontalAlignmentPoint; // The point that is found to align
    NSPoint verticalAlignmentPoint; // The point that is found to align
    // This integer has to be masked with
    // MI_alignsVertically or MI_alignsHorizontally to determine if
    // alignment is given for a particular axis.
    int alignment;
} MI_Alignment;

// Modification types used for undo operations
extern NSString* MI_SCHEMATIC_MODIFIED_NOTIFICATION;
extern NSString* MI_SCHEMATIC_ADD_CHANGE;
extern NSString* MI_SCHEMATIC_DELETE_CHANGE;
extern NSString* MI_SCHEMATIC_CONNECT_CHANGE;
extern NSString* MI_SCHEMATIC_DISCONNECT_CHANGE;
extern NSString* MI_SCHEMATIC_MOVE_CHANGE;
extern NSString* MI_SCHEMATIC_EDIT_PROPERTY_CHANGE;

/*
This class represents a schematic. It acts like
a schematics element but is only a container for
other schematics elements, their positions and
connections between the elements.
*/
@interface MI_Schematic : MI_SchematicElement <NSCoding, NSCopying>

/* Adds a schematic element. Returns YES on success. */
- (BOOL) addElement:(MI_SchematicElement*)element;

/* Returns YES if the element was found and removed, NO otherwise. */
- (BOOL) removeElement:(MI_SchematicElement*)element;

- (void) removeSelectedElements;

- (NSEnumerator*) elementEnumerator;

- (NSUInteger) numberOfElements;

- (BOOL) containsElement:(MI_SchematicElement*)element;

/* Adds a connector to the canvas. */
- (void) addConnector:(MI_ElementConnector*)connector;

/* Returns YES if the connector was found and removed, NO otherwise. */
- (BOOL) removeConnector:(MI_ElementConnector*)connector;

- (NSEnumerator*) connectorEnumerator;

- (BOOL) hasBeenModified;

- (void) markAsModified:(BOOL)modified;

/* Returns the element whose graphical representation contains the
given position. This method is used to determine the selected
element whenever the mouse is clicked or dragged. Returns nil if no
element could be found at the given position. */
- (MI_SchematicElement*) elementAtPosition:(NSPoint)position;

/* Returns nil if no connection point was found at the given relative position
    of the given schematic element. */
- (MI_ConnectionPoint*) connectionPointOfElement:(MI_SchematicElement*)element
                             forRelativePosition:(NSPoint)relPosition;

/* Returns the element connector which is connected to the given connection
    point. Observe that the schematic will allow only one connector to be
    connected to a connection point. Returns nil if the connection point
    is not connected. */
- (MI_ElementConnector*) connectorForConnectionPoint:(MI_ConnectionPoint*)point
                                           ofElement:(MI_SchematicElement*)element;

/* The returned array has to be freed by the caller of this method. The parameter
    for the number of points must be a pointer to an allocated unsigned integer
    and will hold the number of points that will be put into the route when the
    method has finished. The previous route can be set to NULL. */
- (NSPoint*) makeRouteFrom:(NSPoint)start
                        to:(NSPoint)end
            numberOfPoints:(unsigned*)number
             previousRoute:(NSPoint*)oldRoute
    previousNumberOfPoints:(int)oldNumPoints;

/* Convenience method, which calls makeRouteFrom:to:numberOfPoints: to set the
    route of the given connector. */
- (void) calculateRouteForConnector:(MI_ElementConnector*)theConnector;

/* Returns the element with the given identifier string.
    Returns nil if no element was found. */
- (MI_SchematicElement*) elementForIdentifier:(NSString*)identifier;

// Returns an indication of whether a crosshair set at the given position would be
// in alignment with other crosshairs set at the positions of the connection
// points of the other elements in the schematic. If 'unselectedOnly' is YES,
// only alignment with connection points of unselected elements is checked for.
// The tolerance specifies how close the points have to be in one direction to
// be considered aligning.
- (MI_Alignment) checkAlignmentWithOtherConnectionPoints:(NSPoint)thePoint
                                    ofUnselectedElements:(BOOL)unselectedOnly
                                               tolerance:(float)tol;

- (MI_SchematicInfo*) infoForLocation:(NSPoint)location;

/* Returns the connector whose route intersects the circle given by its
    center point 'p' and radius 'r' */
- (MI_ElementConnector*) connectorForPoint:(NSPoint)p
                                    radius:(float)r;

/* Splits the given connector by creating two connectors which are attached
    to the start and end points of the given connector and to appropriate
    points of the inserted element. */
- (void) splitConnector:(MI_ElementConnector*)connector
            withElement:(MI_SchematicElement <MI_InsertableSchematicElement>*)element;


/****** element selection methods *******/
- (void) selectElement:(MI_SchematicElement*)element;   // adds to selection
- (void) deselectElement:(MI_SchematicElement*)element; // removes from selection
- (void) selectAllElementsInRect:(NSRect)rect;          // selects only those elements within the given rectangular region
- (void) selectAllElements;                             // selects all elements of the schematic
- (void) deselectAll;                                   // clears the selection
- (BOOL) isSelected:(MI_SchematicElement*)element;
- (NSUInteger) numberOfSelectedElements;
- (MI_SchematicElement*) firstSelectedElement;
- (NSEnumerator*) selectedElementEnumerator;
/***************************************/

// An underscore character ('_') is appended to the label of each copied element.
- (NSArray*) copyOfSelectedElements;

/* Rotates selected elements and re-routes connected connectors. */
- (void) rotateSelectedElements:(float)angle;

/* Flips elements horizontally if parameter is YES, flips vertically if NO. */
- (void) flipSelectedElements:(BOOL)horizontally;

/* Returns YES if quick info of single parameter elements is shown next to the
    element when they are drawn. */
- (BOOL) showsQuickInfo;

/* Turns displaying quick info on or off. */
- (void) setShowsQuickInfo:(BOOL)show;

// Calculates the smallest rectangle that encloses all elements.
- (NSRect) boundingBox;

// Returns the bounding box for the selected elements only.
- (NSRect) boundingBoxOfSelectedElements;

@end
