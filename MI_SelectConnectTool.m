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
#import "MI_SelectConnectTool.h"
#import "MI_AlignmentPoint.h"
#import "SugarManager.h"

// used for highlighting connection points when mouse is over one
static BOOL wasHoveringOverConnectionPoint = NO;

// Next block of variables is used to constrain element dragging.
// allowedMoveDirection == MI_DirectionUp means up/down
// allowedMoveDirection == MI_DirectionRight means left/right
// every other value means no movement is allowed
MI_Direction allowedMoveDirection = MI_DirectionNone;  // valid only when the dragged elements are totally within the work area
MI_Direction allowedMoveDirectionWhenVirtuallyDraggedOutsideWorkArea = MI_DirectionNone; // the allowed direction when the dragged elements are virtually not totally inside the work area
BOOL moveIsConstrained = NO; // indicates if element dragging INSIDE THE WORK AREA is constrained to a specific direction
BOOL dragGestureJustStarted = NO; // needed to detect which direction is constrained
BOOL elementsVirtuallyDraggedOutsideWorkArea; // indicates whether the bounding box of the ghost image of the selected elements is not totally inside the work area

NSRect boundingBoxForElementDragging;

@interface MI_SelectConnectTool (DragNDrop) <NSPasteboardItemDataProvider, NSDraggingSource>
@end


@implementation MI_SelectConnectTool
{
@private
  // Information needed to construct the current dragged connector
  MI_ConnectionPoint* _draggedConnectorDragStartConnectionPoint;
  MI_SchematicElement* _draggedConnectorDragStartElement;

  // Set to YES when the user presses the button while the mouse is over
  // a connection point. Set to NO when the mouse button is released or the
  // timer expires.
  BOOL _connectorIsDragged;

  // This is used to indicate that the user wants to pan the view
  BOOL _panning;
  BOOL _panningRequested;

  // The element that was last dragged. Reference pointer. Do not release object!
  MI_SchematicElement* _draggedElement;
  MI_SchematicsCanvas* _draggedCanvas;

  BOOL _selectionIsDragged; // used to indicate whether selected elements are dragged or a connector
  BOOL _copyDragSelectedElements;
  NSPoint _dragStartPosition;
  NSPoint _elementPositionRelativeToMouseAtDragStart; // in schematic space
}

- (instancetype) init
{
  if (self = [super init])
  {
    [self reset];
  }
  return self;
}

- (void) reset
{
  self.draggedConnector = nil;
  _draggedConnectorDragStartElement = nil;
  _draggedConnectorDragStartConnectionPoint = nil;
  _connectorIsDragged = NO;
  _draggedElement = nil;
  _draggedCanvas = nil;
  _selectionIsDragged = YES;
  _copyDragSelectedElements = NO;
  wasHoveringOverConnectionPoint = NO;
  _panning = NO;
}


- (void) timeUp:(NSTimer*)timer
{
    if (_connectorIsDragged && (self.draggedConnector == nil))
    {
        // The user wants to drag a node element
        NSDictionary* info = (NSDictionary*)[timer userInfo];
        
        _connectorIsDragged = NO;
        _draggedElement = _draggedConnectorDragStartElement;
        
        [[info objectForKey:@"Canvas"] clearPointHighlight];
        
        _selectionIsDragged = YES;
        if (![[info objectForKey:@"AddToSelection"] boolValue] &&
            ![[info objectForKey:@"CopyDrag"] boolValue])
            [[info objectForKey:@"Schematic"] deselectAll];
        [[info objectForKey:@"Schematic"] selectElement:_draggedConnectorDragStartElement];
        _dragStartPosition = [[info objectForKey:@"DragStartPoint"] pointValue];
        _copyDragSelectedElements = [[info objectForKey:@"CopyDrag"] boolValue];

        _elementPositionRelativeToMouseAtDragStart =
            NSMakePoint([_draggedElement position].x - _dragStartPosition.x,
                        [_draggedElement position].y - _dragStartPosition.y);
        boundingBoxForElementDragging = [[info objectForKey:@"Schematic"] boundingBoxOfSelectedElements];
        
        [[MI_Inspector sharedInspector] inspectElement:_draggedConnectorDragStartElement];
        
        [[info objectForKey:@"Canvas"] setNeedsDisplay:YES];
    }
    else if (_panningRequested)
    {
        // The user wants to pan the view and has waited long enough after
        // pressing the mouse button.
        _panning = YES;
        [[NSCursor openHandCursor] set];
    }
}


- (void) mouseDown:(MI_Schematic*) schematic
             event:(NSEvent*)theEvent
            canvas:(MI_SchematicsCanvas*) canvas
{
    NSPoint clickPosition =
        [canvas convertPoint:[theEvent locationInWindow]
                    fromView:nil];
    
    clickPosition = [canvas canvasPointToSchematicPoint:clickPosition];

    MI_SchematicInfo* info = [schematic infoForLocation:clickPosition];
    
    MI_SchematicElement* dragCandidateElement = info.element;
 
    if (info.element == nil && info.connectionPoint == nil)
    {
        // USER HAS CLICKED ON EMPTY AREA
        [schematic deselectAll]; // clear selected element list
        [canvas setSelectionBoxStartPoint:clickPosition]; // remember position in case we are going to draw a selection box
        [canvas setSelectionBox:NSMakeRect(clickPosition.x, clickPosition.y, 0.0f, 0.0f)];
        [canvas setSelectionBoxIsActive:YES]; // set selection box active for now - will be cleared when mouse goes up again
        [[MI_Inspector sharedInspector] inspectElement:nil];
        
        // Do we start panning? Let's start the timer.
        if ([theEvent clickCount] == 1)
        {
            [NSTimer scheduledTimerWithTimeInterval:0.5
                                             target:self
                                           selector:@selector(timeUp:)
                                           userInfo:nil
                                            repeats:NO];
            _panningRequested = YES;
        }
    }
    // IS THE USER STARTING TO DRAG A CONNECTION (BY CLICKING ON A CONNECTION POINT)?
    else if (dragCandidateElement && info.connectionPoint)
    {
        // DRAGGING THE END OF A CONNECTOR
        NSDictionary* dragInfo = [NSDictionary dictionaryWithObjectsAndKeys:
            canvas, @"Canvas", schematic, @"Schematic",
            [NSValue valueWithPoint:clickPosition], @"DragStartPoint",
            [NSNumber numberWithBool:([theEvent modifierFlags] & NSEventModifierFlagCommand) ? YES : NO], @"AddToSelection",
            [NSNumber numberWithBool:([theEvent modifierFlags] & NSEventModifierFlagOption) ? YES : NO], @"CopyDrag",
            nil];
        // start timer - if the user still presses the mouse button
        // after the timer expires we will switch to element dragging mode
        [NSTimer scheduledTimerWithTimeInterval:0.5
                                         target:self
                                       selector:@selector(timeUp:)
                                       userInfo:dragInfo
                                        repeats:NO];
        
        _draggedConnectorDragStartElement = dragCandidateElement;
        _draggedConnectorDragStartConnectionPoint = info.connectionPoint;
        _connectorIsDragged = YES;
        _selectionIsDragged = NO;
    }
    // NO CONNECTOR IS DRAGGED. DOES THE USER WANT TO DRAG AN ELEMENT?
    else if (dragCandidateElement)
    {
        // DRAGGING AN ELEMENT
        [self setDraggedConnector:nil]; // we are not dragging a connector
                                        // Select the element
                                        // Simultaneously pressing COMMAND adds to the selected elements
        if ([theEvent modifierFlags] & NSEventModifierFlagCommand)
        {
            if ([schematic isSelected:dragCandidateElement])
                [schematic deselectElement:dragCandidateElement];
            else
            {
                [schematic selectElement:dragCandidateElement];
                _draggedElement = dragCandidateElement;
            }
        }
        else // not pressing COMMAND will clear previous selections if it's not a selected element
        {
            // Seems like we are starting to drag the selected elements
            if (![schematic isSelected:dragCandidateElement])
            {
                // We are not dragging one of the selected elements
                [schematic deselectAll];
                [schematic selectElement:dragCandidateElement];
            }
            _copyDragSelectedElements = ([theEvent modifierFlags] & NSEventModifierFlagOption) ? YES : NO;
            _selectionIsDragged = YES;
            dragGestureJustStarted = YES;
            _draggedElement = dragCandidateElement;
            _dragStartPosition = clickPosition;
            if ( !_copyDragSelectedElements && ([schematic numberOfSelectedElements] == 1) )
                [[MI_Inspector sharedInspector] inspectElement:dragCandidateElement];
        }
        _elementPositionRelativeToMouseAtDragStart = // needed for snapping feature
            NSMakePoint([dragCandidateElement position].x - clickPosition.x,
                        [dragCandidateElement position].y - clickPosition.y);
        boundingBoxForElementDragging = [schematic boundingBoxOfSelectedElements];
    }
}


- (void) mouseUp:(MI_Schematic*) schematic
           event:(NSEvent*)theEvent
          canvas:(MI_SchematicsCanvas*) canvas
{
    if (self.draggedConnector)
    {
        NSPoint dropLocation =
        [canvas convertPoint:[theEvent locationInWindow]
                    fromView:nil];
        
        dropLocation = [canvas canvasPointToSchematicPoint:dropLocation];
        
        MI_SchematicInfo* info = [schematic infoForLocation:dropLocation];
        
        if (info.element && info.connectionPoint && !info.isConnected)
        {
            if (![[self.draggedConnector startElementID] length])
            {
                [self.draggedConnector setStartElementID:[info.element identifier]];
                [self.draggedConnector setStartPointName:[info.connectionPoint name]];
            }
            else
            {
                [self.draggedConnector setEndElementID:[info.element identifier]];
                [self.draggedConnector setEndPointName:[info.connectionPoint name]];
            }
            [self.draggedConnector setHighlighted:NO];
            [self.draggedConnector setNeedsRouting:YES]; // to make the connection line 'snap' to the connection point
        }
        else
        {
            // this is not an undo point because if we don't want to restore an unconnected connector
            [schematic removeConnector:self.draggedConnector]; // discard the dragged connector
        }
    }
    else
    {
        [canvas clearAlignmentPoints];
        [canvas setSelectionBoxIsActive:NO];
        _selectionIsDragged = NO;
        _copyDragSelectedElements = NO;
        moveIsConstrained = NO;
        _draggedElement = nil;
        _panningRequested = _panning = NO;
    }
    _connectorIsDragged = NO;
    [self setDraggedConnector:nil];
    [canvas setNeedsDisplay:YES];
}


- (void) mouseDragged:(MI_Schematic*) schematic
                event:(NSEvent*)theEvent
               canvas:(MI_SchematicsCanvas*) canvas
{
    if ([theEvent modifierFlags] & NSEventModifierFlagCommand)
    {
      [self _startDraggingImageOfSchematicForDragEvent:theEvent inCanvas:canvas];
    }
    else
    {
        // THE USER IS EITHER DRAGGING AN ELEMENT OR THE END OF A CONNECTOR
        NSPoint const canvasDragPosition = [canvas convertPoint:[theEvent locationInWindow] fromView:nil];
        NSPoint const dragPosition = [canvas canvasPointToSchematicPoint:canvasDragPosition];
            
        if (_connectorIsDragged)
        {
            // THE USER IS DRAGGING THE END OF A CONNECTOR
            if (self.draggedConnector == nil)
            {
                // The dragged connector does not exist yet. It has to be assigned.
                MI_ElementConnector* connectedConnector =
                [schematic connectorForConnectionPoint:_draggedConnectorDragStartConnectionPoint
                                             ofElement:_draggedConnectorDragStartElement];
                if (connectedConnector)
                {
                    // Disconnect one end of the connector from the drag start connection point
                    [[canvas controller] createSchematicUndoPointForModificationType:MI_SCHEMATIC_DISCONNECT_CHANGE];
                    if ( [[connectedConnector startPointName] isEqualToString:[_draggedConnectorDragStartConnectionPoint name]] &&
                         [[connectedConnector startElementID] isEqualToString:[_draggedConnectorDragStartElement identifier]] )
                    {
                        [connectedConnector setStartPointName:@""];
                        [connectedConnector setStartElementID:@""];
                    }
                    else
                    {
                        [connectedConnector setEndPointName:@""];
                        [connectedConnector setEndElementID:@""];
                    }
                    [self setDraggedConnector:connectedConnector];
                    [schematic markAsModified:YES];
                }
                else
                {
                    // Create a new connector and connect one end to this connection point
                    [[canvas controller] createSchematicUndoPointForModificationType:MI_SCHEMATIC_CONNECT_CHANGE];
                    connectedConnector = [[MI_ElementConnector alloc] init];
                    [connectedConnector setStartElementID:[_draggedConnectorDragStartElement identifier]];
                    [connectedConnector setStartPointName:[_draggedConnectorDragStartConnectionPoint name]];
                    [schematic addConnector:connectedConnector];
                    [self setDraggedConnector:connectedConnector];
                }
            }
            //NSLog(@"updating route");
            // Update route of the connector
            if ([[self.draggedConnector startPointName] length])
            {
                // get location of start point
                MI_SchematicElement* startElement =
                [schematic elementForIdentifier:[self.draggedConnector startElementID]];
                if (startElement)
                {
                    MI_ConnectionPoint* startPoint =
                    [[startElement connectionPoints] objectForKey:[self.draggedConnector startPointName]];
                    NSPoint startLocation =
                        NSMakePoint([startElement position].x + [startPoint relativePosition].x,
                                    [startElement position].y + [startPoint relativePosition].y);
                    unsigned numPoints;
                    NSPoint* route = [schematic makeRouteFrom:startLocation
                                                           to:dragPosition
                                               numberOfPoints:&numPoints
                                                previousRoute:[self.draggedConnector route]
                                       previousNumberOfPoints:[self.draggedConnector numberOfRoutePoints]];
                    [self.draggedConnector setRoute:route
                                numberOfPoints:numPoints];
                }
            }
            else
            {
                // get location of end point
                MI_SchematicElement* endElement =
                [schematic elementForIdentifier:[self.draggedConnector endElementID]];
                if (endElement)
                {
                    MI_ConnectionPoint* endPoint =
                    [[endElement connectionPoints] objectForKey:[self.draggedConnector endPointName]];
                    NSPoint endLocation =
                        NSMakePoint([endElement position].x + [endPoint relativePosition].x,
                                    [endElement position].y + [endPoint relativePosition].y);
                    unsigned numPoints;
                    NSPoint* route = [schematic makeRouteFrom:endLocation
                                                           to:dragPosition
                                               numberOfPoints:&numPoints
                                                previousRoute:[self.draggedConnector route]
                                       previousNumberOfPoints:[self.draggedConnector numberOfRoutePoints]];
                    [self.draggedConnector setRoute:route
                                numberOfPoints:numPoints];
                }
            }
            
            // Provide feedback about connectability to the current location
            MI_SchematicInfo* info = [schematic infoForLocation:dragPosition];
            if (info.element && info.connectionPoint && !info.isConnected)
            {
                [self.draggedConnector setHighlighted:YES];
                NSPoint p = [info.element position];
                p.x += [info.connectionPoint relativePosition].x;
                p.y += [info.connectionPoint relativePosition].y;
                [canvas highlightPoint:[canvas schematicPointToCanvasPoint:p]
                                  size:3.0f*[canvas scale]];
            }
            else
            {
                [canvas clearPointHighlight];
                [self.draggedConnector setHighlighted:NO];
            }
            
            [canvas setNeedsDisplay:YES];
        }
        // AT THIS POINT WE KNOW THE USER IS NOT DRAGGING A CONNECTOR
        else
        {
            // NOW WE KNOW THAT THE USER WANTS TO DRAG AN ELEMENT
            if (_selectionIsDragged)
            {
                // We are dragging the selected schematic elements
                if (_copyDragSelectedElements)
                {
                    // Copy the selected elements
                    NSArray* tmpArray = [schematic copyOfSelectedElements];
//MISSING: copy connection lines
                    // Deselect all currently selected elements
                    [schematic deselectAll];
                    
                    [[canvas controller] createSchematicUndoPointForModificationType:MI_SCHEMATIC_ADD_CHANGE];
                    
                    // Add the copies to the schematic and to the selection
                    MI_SchematicElement* tmpElement;
                    for (long i = [tmpArray count] - 1; i >= 0; i--)
                    {
                        tmpElement = (MI_SchematicElement*) [tmpArray objectAtIndex:i];
                        [schematic addElement:tmpElement];
                        [schematic selectElement:tmpElement];
                        // The new dragged element is the copy of the previous dragged element
                        if ([tmpElement position].x == [_draggedElement position].x &&
                            [tmpElement position].y == [_draggedElement position].y)
                            _draggedElement = tmpElement;
                    }
                    // update the element inspector
                    if ([tmpArray count] == 1)
                        [[MI_Inspector sharedInspector] inspectElement:[tmpArray objectAtIndex:0]];
                    else
                        [[MI_Inspector sharedInspector] inspectElement:nil];
                    
                    _copyDragSelectedElements = NO;
                }
                float xMotion = dragPosition.x - _dragStartPosition.x;
                float yMotion = dragPosition.y - _dragStartPosition.y;
                boundingBoxForElementDragging.origin.x += xMotion;
                boundingBoxForElementDragging.origin.y += yMotion;
                
                // Check if the drag motion is constrained to vertical or horizontal with the SHIFT key
                if (dragGestureJustStarted)
                {
                    if ([theEvent modifierFlags] & NSEventModifierFlagShift)
                    {
                        // constrain movement to vertical or horizontal only
                        moveIsConstrained = YES;
                        allowedMoveDirection = (fabs(yMotion) > fabs(xMotion)) ? MI_DirectionUp : MI_DirectionRight;
                    }
                    dragGestureJustStarted = NO;
                }
                if (moveIsConstrained)
                {
                    if (allowedMoveDirection != MI_DirectionRight)
                        xMotion = 0.0f; // drag vertical only
                    if (allowedMoveDirection != MI_DirectionUp)
                        yMotion = 0.0f; // drag horizontal only
                }

                // Check if the bounding box of the dragged elements is within the work area
                NSRect area = [canvas workArea];
                BOOL elementsHorizontallyInWorkArea = (boundingBoxForElementDragging.origin.x > area.origin.x)
                    && (boundingBoxForElementDragging.origin.x + boundingBoxForElementDragging.size.width < area.origin.x + area.size.width);
                BOOL elementsVerticallyInWorkArea = (boundingBoxForElementDragging.origin.y > area.origin.y)
                    && (boundingBoxForElementDragging.origin.y + boundingBoxForElementDragging.size.height < area.origin.y + area.size.height);
                elementsVirtuallyDraggedOutsideWorkArea = !elementsHorizontallyInWorkArea || !elementsVerticallyInWorkArea;
                
                // Are we outside the work area?
                if (elementsVirtuallyDraggedOutsideWorkArea)
                {
                    // Constrain the motion of the real dragged elements depending on where the virtually
                    // dragged elements are. Let the real elements slide along the border line unless they
                    // are dragged into a corner.
                    if ( !elementsHorizontallyInWorkArea && elementsVerticallyInWorkArea )
                        allowedMoveDirectionWhenVirtuallyDraggedOutsideWorkArea = (moveIsConstrained &&
                            allowedMoveDirection != MI_DirectionUp) ? MI_DirectionNone : MI_DirectionUp;
                    else if ( elementsHorizontallyInWorkArea && !elementsVerticallyInWorkArea )
                        allowedMoveDirectionWhenVirtuallyDraggedOutsideWorkArea = (moveIsConstrained &&
                            allowedMoveDirection != MI_DirectionRight) ? MI_DirectionNone : MI_DirectionRight;
                    else
                        allowedMoveDirectionWhenVirtuallyDraggedOutsideWorkArea = MI_DirectionNone;
                }
                
                [self moveSelectedElementsVertically:yMotion
                                        Horizontally:xMotion
                                      draggedElement:_draggedElement
                                              canvas:canvas
                                           schematic:schematic
                                       mousePosition:dragPosition]; // conversion to schematic space was already done
                _dragStartPosition = dragPosition;
            }
            else
            {
                // THE USER IS NOT DRAGGING ANYTHING
                // EITHER HE/SHE WANTS TO DRAG A SELECTION BOX OR PAN THE VIEW OR SCALE THE VIEW
                if (_panning)
                {
                    // Pan view
                    [canvas otherMouseDown:theEvent];
                }
                else
                {
                    _panning = _panningRequested = NO;
                    // Select region
                    NSPoint boxStart = [canvas selectionBoxStartPoint];
                    NSRect selectionBox =
                        NSMakeRect(fmin(boxStart.x, dragPosition.x),
                                   fmin(boxStart.y, dragPosition.y),
                                   fabs(boxStart.x - dragPosition.x),
                                   fabs(boxStart.y - dragPosition.y));
                    [canvas setSelectionBox:selectionBox];
                    [schematic selectAllElementsInRect:selectionBox];
                }
            }
                        
            [canvas clearPointHighlight];
            [canvas setNeedsDisplay:YES];
        } // end of drag element
    } // end of drag element or connector
}


- (void) mouseMoved:(MI_Schematic*) schematic
              event:(NSEvent*)theEvent
             canvas:(MI_SchematicsCanvas*) canvas
{
    NSPoint mouse = [canvas canvasPointToSchematicPoint:
        [canvas convertPoint:[theEvent locationInWindow]
                    fromView:nil]];
    // Highlight connection points
    MI_SchematicInfo* info = [schematic infoForLocation:mouse];

    if (info.element && info.connectionPoint)
    {
        NSPoint p = [info.element position];
        p.x += [info.connectionPoint relativePosition].x;
        p.y += [info.connectionPoint relativePosition].y;
        [canvas highlightPoint:[canvas schematicPointToCanvasPoint:p]
                          size:3.0f*[canvas scale]];
        wasHoveringOverConnectionPoint = YES;
        [canvas setNeedsDisplay:YES];
    }
    else if (wasHoveringOverConnectionPoint)
    {
        wasHoveringOverConnectionPoint = NO;
        [canvas clearPointHighlight];
        [canvas setNeedsDisplay:YES];
    }
    // else
        // do nothing
}


- (void) keyDown:(MI_Schematic*) schematic
           event:(NSEvent*)theEvent
          canvas:(MI_SchematicsCanvas*)canvas
{
    NSString* chars = [theEvent characters];
    if ([chars length] == 1)
    {
        unichar theChar = [chars characterAtIndex:0];
        
        if (theChar == 127 /* DEL key */)
        {
            [[canvas controller] createSchematicUndoPointForModificationType:MI_SCHEMATIC_DELETE_CHANGE];
            [schematic removeSelectedElements];
            [[MI_Inspector sharedInspector] inspectElement:nil];
        }
        else if ( (theChar == NSUpArrowFunctionKey) ||
                  (theChar == NSDownArrowFunctionKey) ||
                  (theChar == NSLeftArrowFunctionKey) ||
                  (theChar == NSRightArrowFunctionKey) )
        {
            float step = ([theEvent modifierFlags] & NSEventModifierFlagShift) ? 10.0f : 1.0f;
            NSRect box = [schematic boundingBoxOfSelectedElements];
            MI_SchematicElement* dElement = nil;
            if ([schematic numberOfSelectedElements] == 1)
                dElement = [schematic firstSelectedElement];
            if (theChar == NSUpArrowFunctionKey)
            {
                if ( !(box.origin.y + box.size.height + step > [canvas workArea].origin.y + [canvas workArea].size.height) )
                    [self moveSelectedElementsVertically:step
                                            Horizontally:0.0f
                                          draggedElement:dElement
                                                  canvas:canvas
                                               schematic:schematic
                                           mousePosition:NSMakePoint(0,0)];
            }
            else if (theChar == NSDownArrowFunctionKey)
            {
                if ( !(box.origin.y - step < [canvas workArea].origin.y) )
                    [self moveSelectedElementsVertically:-step
                                            Horizontally:0.0f
                                          draggedElement:dElement
                                                  canvas:canvas
                                               schematic:schematic
                                           mousePosition:NSMakePoint(0,0)];
            }
            else if (theChar == NSLeftArrowFunctionKey)
            {
                if ( !(box.origin.x - step < [canvas workArea].origin.x) )
                    [self moveSelectedElementsVertically:0.0f
                                            Horizontally:-step
                                          draggedElement:dElement
                                                  canvas:canvas
                                               schematic:schematic
                                           mousePosition:NSMakePoint(0,0)];
            }
            else if (theChar == NSRightArrowFunctionKey)
            {
                if ( !(box.origin.x + box.size.width + step > [canvas workArea].origin.x + [canvas workArea].size.width) )
                    [self moveSelectedElementsVertically:0.0f
                                            Horizontally:step
                                          draggedElement:dElement
                                                  canvas:canvas
                                               schematic:schematic
                                           mousePosition:NSMakePoint(0,0)];
            }
        }
        else if (theChar == 32 /* SPACE key */)
        {
            [[canvas controller] toggleDetailsView];
        }
        else if (theChar == ']' || theChar == 's' || theChar == 'S')
        {
            [[canvas controller] createSchematicUndoPointForModificationType:MI_SCHEMATIC_EDIT_PROPERTY_CHANGE];
            [schematic rotateSelectedElements:-90.0f];
        }
        else if (theChar == '[' || theChar == 'a' || theChar == 'A')
        {
            [[canvas controller] createSchematicUndoPointForModificationType:MI_SCHEMATIC_EDIT_PROPERTY_CHANGE];
            [schematic rotateSelectedElements:90.0f];
        }
        else if (theChar == '\t')
        {
            [[canvas controller] createSchematicUndoPointForModificationType:MI_SCHEMATIC_EDIT_PROPERTY_CHANGE];
            [schematic flipSelectedElements:YES];
        }
        [canvas setNeedsDisplay:YES];
    }
}


- (void) moveSelectedElementsVertically:(float)yOffset
                           Horizontally:(float)xOffset
                         draggedElement:(MI_SchematicElement*)theElement
                                 canvas:(MI_SchematicsCanvas*)canvas
                              schematic:(MI_Schematic*)schematic
                          mousePosition:(NSPoint)mouse  // used only when dragging with mouse
{
    if ([schematic numberOfSelectedElements] == 0)
        return;
    
    [[canvas controller] createSchematicUndoPointForModificationType:MI_SCHEMATIC_MOVE_CHANGE];

    float effectiveMoveX = xOffset;
    float effectiveMoveY = yOffset;
    NSEnumerator* connPointEnum;
    MI_ConnectionPoint* currentPoint;
    NSPoint currentPosition;
    NSPoint candidate;
    MI_Alignment alignment;
    BOOL hasSnappedHorizontally = NO;
    BOOL hasSnappedVertically = NO;
    if ([canvas showsGuides])
        [canvas clearAlignmentPoints];
    
    // First check if the dragged element aligns with other elements (if we use the mouse for moving elements)
    if (theElement && [canvas showsGuides])
    {
        currentPosition = [theElement position];
        // move the dragged element in response to mouse drag
        [theElement setPosition:NSMakePoint(currentPosition.x + xOffset, currentPosition.y + yOffset)];
        // for all connection points of the dragged element check alignment with other connection points
        connPointEnum = [[theElement alignableConnectionPoints] objectEnumerator];
        while (currentPoint = [connPointEnum nextObject])
        {
            if (_selectionIsDragged) // is this sufficient to discern move w/ mouse and move w/ arrow keys
                candidate = NSMakePoint(mouse.x + _elementPositionRelativeToMouseAtDragStart.x + [currentPoint relativePosition].x,
                                        mouse.y + _elementPositionRelativeToMouseAtDragStart.y + [currentPoint relativePosition].y);
            else
                candidate = NSMakePoint([theElement position].x + [currentPoint relativePosition].x,
                                        [theElement position].y + [currentPoint relativePosition].y);
            
            alignment = [schematic checkAlignmentWithOtherConnectionPoints:candidate
                                                      ofUnselectedElements:YES
                                                                 tolerance:(_selectionIsDragged ? 3.0f : 0.5f)];
            
            // Check for alignment with other connection points on the vertical and snap left/right.
            // But only if the movement is not constrained to up/down.
            BOOL constrainedMove = elementsVirtuallyDraggedOutsideWorkArea ? YES : moveIsConstrained;
            MI_Direction allowedDirection = elementsVirtuallyDraggedOutsideWorkArea ? allowedMoveDirectionWhenVirtuallyDraggedOutsideWorkArea : allowedMoveDirection;
            
            if ( (alignment.alignment & MI_alignsVertically) &&
                !(constrainedMove && (allowedDirection == MI_DirectionUp)) )
            {
                [canvas addAlignmentPoint:
                    [[MI_AlignmentPoint alloc] initWithPosition:[canvas schematicPointToCanvasPoint:alignment.verticalAlignmentPoint]
                                                alignsVertically:YES
                                              alignsHorizontally:NO]];
                if (_selectionIsDragged)
                {
                    if ( !hasSnappedVertically )
                    {
                        effectiveMoveX = alignment.verticalAlignmentPoint.x - [currentPoint relativePosition].x - currentPosition.x;
                        if (constrainedMove)
                            effectiveMoveY = 0.0f;
                    }
                    hasSnappedVertically = YES;
                }
            }
            // Check for alignment with other connection points on the horizontal and snap up/down.
            // But only if the movement is not constrained to left/right.
            if ( (alignment.alignment & MI_alignsHorizontally) &&
                 !(constrainedMove && (allowedDirection == MI_DirectionRight)) )
            {
                [canvas addAlignmentPoint:
                    [[MI_AlignmentPoint alloc] initWithPosition:[canvas schematicPointToCanvasPoint:alignment.horizontalAlignmentPoint]
                                                alignsVertically:NO
                                              alignsHorizontally:YES]];
                if (_selectionIsDragged)
                {
                    if (!hasSnappedHorizontally)
                    {
                        effectiveMoveY = alignment.horizontalAlignmentPoint.y - [currentPoint relativePosition].y - currentPosition.y;
                        if (constrainedMove)
                            effectiveMoveX = 0.0f;
                    }
                    hasSnappedHorizontally = YES;
                }
            }
            // Snap back if there is no alignment or the mouse drags the element out of the alignment region
            if (!hasSnappedVertically && !hasSnappedHorizontally && _selectionIsDragged) // Again, is selectionIsDragged enough of a criterium?
            {
                effectiveMoveX = mouse.x + _elementPositionRelativeToMouseAtDragStart.x - currentPosition.x;
                effectiveMoveY = mouse.y + _elementPositionRelativeToMouseAtDragStart.y - currentPosition.y;
                if (constrainedMove)
                {
                    if (allowedDirection != MI_DirectionRight)
                        effectiveMoveX = 0.0f;
                    if (allowedDirection != MI_DirectionUp)
                        effectiveMoveY = 0.0f;
                }
            }
        }
    }
    else
    {
        effectiveMoveX = xOffset;
        effectiveMoveY = yOffset;
    }
    
    // Now apply the calculated differential motion to all elements that were moved (= selected elements)
    NSEnumerator* selectionEnum = [schematic selectedElementEnumerator];
    MI_SchematicElement* currentElement;
    while (currentElement = [selectionEnum nextObject])
    {
        currentPosition = [currentElement position];
        if (currentElement == theElement && [canvas showsGuides])
            // the dragged element was already moved by (xOffset, yOffset) - subtract that
            [currentElement setPosition:NSMakePoint(currentPosition.x + effectiveMoveX - xOffset,
                                                    currentPosition.y + effectiveMoveY - yOffset)];
        else
            [currentElement setPosition:NSMakePoint(currentPosition.x + effectiveMoveX,
                                                    currentPosition.y + effectiveMoveY)];
        
        // request re-routing and alignment check
        connPointEnum = [[currentElement connectionPoints] objectEnumerator];
        while (currentPoint = [connPointEnum nextObject])
            [[schematic connectorForConnectionPoint:currentPoint
                                          ofElement:currentElement] setNeedsRouting:YES];
    }
    
    [schematic markAsModified:YES];
}


// Handles copy-paste of elements and select/deselect all.
// Care has to be taken to not block main menu shortcuts.
- (BOOL) performKeyEquivalent:(MI_Schematic*)schematic
                        event:(NSEvent*)theEvent
                       canvas:(MI_SchematicsCanvas*)canvas
{
    NSString* chars = [theEvent charactersIgnoringModifiers];
    if ([chars length] == 1)
    {
        if ( ([theEvent modifierFlags] & NSEventModifierFlagCommand) &&
             !([theEvent modifierFlags] & NSEventModifierFlagOption) &&
             [[chars lowercaseString] isEqualToString:@"c"])
        {
            NSArray* copiedElements = [schematic copyOfSelectedElements];
            NSMutableArray* copiedConnectors = [NSMutableArray arrayWithCapacity:[copiedElements count]];
            // Iterate over all connectors to find out which ones
            // have start and end points connected to elements that
            // are in the selection
            NSEnumerator* connectorEnum = [schematic connectorEnumerator];
            NSEnumerator* elementEnum;
            MI_ElementConnector *currentConnector;
            MI_SchematicElement *currentElement, *startElement, *endElement;
            while (currentConnector = [connectorEnum nextObject])
            {
                startElement = nil;
                endElement = nil;
                elementEnum = [schematic selectedElementEnumerator];
                while (currentElement = [elementEnum nextObject])
                {
                    if (startElement == nil &&
                        [[currentElement identifier] isEqualToString:[currentConnector startElementID]])
                        startElement = currentElement;
                    if (endElement == nil &&
                        [[currentElement identifier] isEqualToString:[currentConnector endElementID]])
                        endElement = currentElement;
                    if (endElement != nil && startElement != nil)
                    {
                        [copiedConnectors addObject:[currentConnector copy]];
                        // Copy this connector to the pasteboard
                        break;
                    }
                }
            }
            // Copy elements to pasteboard
            // Declare paste board type first
            NSArray* pbTypes = [NSArray arrayWithObject:MI_SchematicElementsPboardType];
            NSPasteboard *gPboard = [NSPasteboard generalPasteboard];
            [gPboard declareTypes:pbTypes
                            owner:canvas];
            [gPboard setData:[NSKeyedArchiver archivedDataWithRootObject:[NSArray arrayWithObjects:
                copiedElements, copiedConnectors, nil]]
                     forType:MI_SchematicElementsPboardType];
            return YES;
        }
        else if ( ([theEvent modifierFlags] & NSEventModifierFlagCommand) &&
                  !([theEvent modifierFlags] & NSEventModifierFlagOption) &&
                  [[chars lowercaseString] isEqualToString:@"v"])
        {
            // Paste elements from pasteboard
            NSPasteboard *gPboard = [NSPasteboard generalPasteboard];
            if ([[gPboard types] containsObject:MI_SchematicElementsPboardType])
            {
                [[canvas controller] createSchematicUndoPointForModificationType:MI_SCHEMATIC_ADD_CHANGE];
                NSArray* pastedSchematicObjects = [[NSArray alloc] initWithArray:
                    [NSKeyedUnarchiver unarchiveObjectWithData:
                        [gPboard dataForType:MI_SchematicElementsPboardType]]
                                                                       copyItems:YES];
                NSArray* pastedElements = [pastedSchematicObjects objectAtIndex:0];
                NSArray* pastedConnectors = [pastedSchematicObjects objectAtIndex:1];
                NSEnumerator* pastedEnum = [pastedElements objectEnumerator];
                MI_CircuitElement* element;
                while (element = [pastedEnum nextObject])
                {
                  [schematic addElement:element];
                }
                pastedEnum = [pastedConnectors objectEnumerator];
                MI_ElementConnector* connector;
                while (connector = [pastedEnum nextObject])
                {
                    MI_SchematicInfo* i = [schematic infoForLocation:*[connector route]];
                    [connector setStartElementID:[i.element identifier]];
                    i = [schematic infoForLocation:*([connector route] + [connector numberOfRoutePoints] - 1)];
                    [connector setEndElementID:[i.element identifier]];
                    [schematic addConnector:connector];
                }
                [canvas setNeedsDisplay:YES];
                return YES;
            }
            else
                return NO;
        }
        else if ( ([theEvent modifierFlags] & NSEventModifierFlagCommand) &&
                  !([theEvent modifierFlags] & NSEventModifierFlagOption) &&
                  [[chars lowercaseString] isEqualToString:@"a"])
        {
            // Select/deselect all elements
            if ([theEvent modifierFlags] & NSEventModifierFlagShift)
                [schematic deselectAll];
            else
                [schematic selectAllElements];
            [canvas setNeedsDisplay:YES];
            return YES;
        }
    }
    return NO;
}

- (NSImage*) _imageForCanvas:(MI_SchematicsCanvas*)canvas
{
  NSRect imageBox = [canvas frame];
  imageBox.origin = NSZeroPoint;
  NSImage *schematicImage = [[NSImage alloc] initWithSize:imageBox.size];
  [schematicImage lockFocus];
  [canvas drawRect:imageBox];
  [schematicImage unlockFocus];
  return schematicImage;
}

- (void) _startDraggingImageOfSchematicForDragEvent:(NSEvent*)event inCanvas:(MI_SchematicsCanvas*) canvas
{
  CGSize const canvasSize = [canvas frame].size;

  // Creating a semi-transparent drag image of the canvas
  NSImage* dragImage = [[NSImage alloc] initWithSize:canvasSize];
  [dragImage lockFocus];
  [[self _imageForCanvas:canvas] drawAtPoint:NSMakePoint(0,0) fromRect:NSZeroRect operation:NSCompositingOperationCopy fraction:0.8f];
  [dragImage unlockFocus];

  NSPasteboardItem* pbItem = [[NSPasteboardItem alloc] init];
  [pbItem setDataProvider:self forTypes:@[NSPasteboardTypeTIFF]];
  NSDraggingItem* draggingItem = [[NSDraggingItem alloc] initWithPasteboardWriter:pbItem];
  [draggingItem setDraggingFrame:NSMakeRect(0, 0, canvasSize.width, canvasSize.height) contents:dragImage];

  _draggedCanvas = canvas;
  [canvas beginDraggingSessionWithItems:@[draggingItem] event:event source:self];
}

@end


@implementation MI_SelectConnectTool (DragNDrop)

- (void) pasteboard:(nullable NSPasteboard *)pasteboard item:(NSPasteboardItem *)item provideDataForType:(NSPasteboardType)type
{
  if (_draggedCanvas != nil)
  {
    NSData* data = [[self _imageForCanvas:_draggedCanvas] TIFFRepresentation];
    [pasteboard setData:data forType:type];
  }
}

- (NSDragOperation) draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
  return NSDragOperationGeneric;
}

@end

