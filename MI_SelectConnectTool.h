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
#import "MI_Tool.h"
#import "MI_Schematic.h"
#import "MI_ElementConnector.h"

/*
 Tool for selecting and dragging elements and making connections.
 
 When the mouse hovers on top of a connection point the point is
 highlighted (red dot). By clicking on the highlighted dot and
 dragging the mouse the user creates a connection lines which
 is connected to the initial connection point on one end and
 loose on the other. The loose end follows the mouse position.
 The user can abort by releasing the mouse button, which will
 automatically remove the connection line. An unconnected
 connection point is highlighted when the user drags the loose
 end of the connection line over it. A connection is made when
 the mouse button is released over an unconnected connection point.
 
 When the user presses the mouse button over a connection point
 and holds for more than 1 second then the mode switches from
 connection line dragging to element dragging, where the element to
 which the connection point belongs to is added to the selection.
*/
@interface MI_SelectConnectTool : MI_Tool
{
     // The connector that was last dragged.
    MI_ElementConnector* draggedConnector;
    
    // Information needed to construct the current dragged connector
    MI_ConnectionPoint* draggedConnectorDragStartConnectionPoint;
    MI_SchematicElement* draggedConnectorDragStartElement;
    
    // Set to YES when the user presses the button while the mouse is over
    // a connection point. Set to NO when the mouse button is released or the
    // timer expires.
    BOOL connectorIsDragged;
    
    // This is used to indicate that the user wants to pan the view
    BOOL panning;
    BOOL panningRequested;

    // The element that was last dragged. Reference pointer. Do not release object!
    MI_SchematicElement* draggedElement;
    
    BOOL selectionIsDragged; // used to indicate whether selected elements are dragged or a connector
    BOOL copyDragSelectedElements;
    NSPoint dragStartPosition;
    NSPoint elementPositionRelativeToMouseAtDragStart; // in schematic space
}
- (void) setDraggedConnector:(MI_ElementConnector*)theConnector;
- (MI_ElementConnector*) draggedConnector;

/*
 For use by mouse drag and arrow key response methods.
 Moves selected elements and updates connector routes.
 If the 'draggedElement' parameter is given alignment is checked for
 that parameter and placement guides of the canvas are updated.
 The mouse position is needed for the element snapping feature
 and is only used when dragging elements with the mouse.
*/
- (void) moveSelectedElementsVertically:(float)vert
                           Horizontally:(float)hor
                         draggedElement:(MI_SchematicElement*)dElement
                                 canvas:(MI_SchematicsCanvas*)canvas
                              schematic:(MI_Schematic*)schematic
                          mousePosition:(NSPoint)mousePos;

// Called when a timer expires (fires).
// The timer is set when the mouse hovers over a connection point.
// When it expires we know that the user does not want to perform
// a connector drag operation but an element drag.
- (void) timeUp:(NSTimer*)timer;

@end
