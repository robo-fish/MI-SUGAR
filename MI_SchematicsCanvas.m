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
#import "MI_SchematicsCanvas.h"
#import "SugarManager.h"

static const float LEFT_PANNING_STRIP_WIDTH = 20.0f;
static const float RIGHT_PANNING_STRIP_WIDTH = 20.0f;
static const float TOP_PANNING_STRIP_HEIGHT = 20.0f;
static const float BOTTOM_PANNING_STRIP_HEIGHT = 20.0f;

// Indicates whether the following draw commands will
// use the canvas view transformation or move the lower
// left corner of the schematic to the origin of drawn rectangle.
// When it's YES, the mode is suitable for drawing to buffered images.
BOOL drawToBufferedImage = NO;


@implementation MI_SchematicsCanvas

- (instancetype) initWithFrame:(NSRect)rect
{
    if (self = [super initWithFrame:rect])
    {
        WorkArea = NSMakeRect(-1000, -1000, 2000, 2000);
        backgroundColor = [NSColor whiteColor];
        passiveColor = [NSColor blackColor];
        highlightColor = [NSColor redColor];
        gridColor = [NSColor grayColor];
        frameColor = passiveColor;
        scale = 1.0f;
        printScale = 1.0f;
        showGuides = YES;
        drawFrame = YES;
        selectionBoxIsActive = NO;
        controller = nil;
        alignmentPoints = [[NSMutableArray alloc] initWithCapacity:3];
        placementGuideColor = [NSColor colorWithDeviceRed:0.4f green:1.0f blue:0.4f alpha:1.0f];
        selectionBoxColor = [NSColor orangeColor];
        highlightPoint = NO;
        highlightedPoint = NSMakeRect(0,0,0,0);
        visitedPanningStrip = MI_DIRECTION_NONE;
        panning = NO;
        viewportOffset = NSMakePoint(0, 0);
    }
    return self;
}

- (void) dealloc
{
  [self unregisterDraggedTypes];
}


- (void) awakeFromNib
{
    [self registerForDraggedTypes:
        [NSArray arrayWithObjects:
            NSURLPboardType, NSFilenamesPboardType,
            MI_SchematicElementPboardType, nil]];
    //[[self window] useOptimizedDrawing:YES];
    [[self window] setAcceptsMouseMovedEvents:YES];
    [self showGuides:[[[NSUserDefaults standardUserDefaults] objectForKey:MISUGAR_SHOW_PLACEMENT_GUIDES] boolValue]];
}

/* As of April 2004 Cocoa still has a bug in the NSString drawing method.
The clipping rectangle for strings does not get updated when transformations
are applied to the view content and the strings disappear when outside of
the original clipping rectangle.
- (BOOL) wantsDefaultClipping
{
    return NO;
}
*/

- (void) drawToBufferedImageWithRect:(NSRect)theRect
                               scale:(float)theScale
{
    drawToBufferedImage = YES;
    float tmp = printScale;
    printScale = theScale; // abusing the printScale variable
    [self drawRect:theRect];
    drawToBufferedImage = NO;
    printScale = tmp;
}


- (void) drawRect:(NSRect)rect
{
    NSBezierPath* bp;
    
    // Draw background
    [backgroundColor set];
    [NSBezierPath fillRect:rect];
            
    if (showGuides)
        [self drawGuides];

    MI_Schematic* schematic = [[controller model] schematic];
    if (schematic)
    {
        // Adjust scale factor and draw schematic
/* I TRIED TO MOVE THE ZOOM ORIGIN INTO THE CENTER OF THE VIEW - MESSES UP THE POSITION DETECTIONS
        NSAffineTransform* transform1 = [NSAffineTransform transform];
        NSAffineTransform* transform2 = [NSAffineTransform transform];
        NSAffineTransform* transform3 = [NSAffineTransform transform];
        NSGraphicsContext* currentContext = [NSGraphicsContext currentContext];
        [currentContext saveGraphicsState];
        [transform1 translateXBy:-[self frame].size.width / 2.0f
                             yBy:-[self frame].size.height / 2.0f];
        [transform2 scaleBy:scale];
        [transform3 translateXBy:[self frame].size.width / 2.0f
                             yBy:[self frame].size.height / 2.0f];
        [transform1 appendTransform:transform2];
        [transform1 appendTransform:transform3];
        [transform1 concat];
*/
        NSGraphicsContext* currentContext = [NSGraphicsContext currentContext];
        [currentContext saveGraphicsState];

        if ([NSGraphicsContext currentContextDrawingToScreen] && !drawToBufferedImage)
        {
            NSAffineTransform* scaleCenterPointTransform = [NSAffineTransform transform];
            NSAffineTransform* scaleTransform = [NSAffineTransform transform];
            NSAffineTransform* scaleCenterPointBackTransform = [NSAffineTransform transform];
            NSAffineTransform* viewportTransform = [NSAffineTransform transform];
            [scaleCenterPointTransform translateXBy:-rect.size.width/2
                                                yBy:-rect.size.height/2];
            [scaleCenterPointBackTransform translateXBy:rect.size.width/2
                                                    yBy:rect.size.height/2];
            [scaleTransform scaleBy:scale];
            [viewportTransform translateXBy:viewportOffset.x
                                        yBy:viewportOffset.y];
            [viewportTransform appendTransform:scaleCenterPointTransform];
            [viewportTransform appendTransform:scaleTransform];
            [viewportTransform appendTransform:scaleCenterPointBackTransform];
            [viewportTransform concat];
            
            // Draw working area limits
            [[NSColor orangeColor] set];
            bp = [NSBezierPath bezierPath];
            [bp setLineWidth:2.0f];
            [bp appendBezierPathWithRect:WorkArea];
            [bp stroke];
        }
        else
        {
            // No viewport translation and scaling around viewport center is used
            // when drawing the image for printing or into a buffer.
            NSRect boxRect = [schematic boundingBox];
            NSAffineTransform* lowerLeftCornerTransform = [NSAffineTransform transform];
            [lowerLeftCornerTransform translateXBy:-boxRect.origin.x + 5.0f
                                               yBy:-boxRect.origin.y + 5.0f];
            NSAffineTransform* scaleTransform = [NSAffineTransform transform];
            [scaleTransform scaleBy:printScale];
            [lowerLeftCornerTransform appendTransform:scaleTransform];
            [lowerLeftCornerTransform concat];
        }
        
        [schematic draw];

        // Draw bounding box
//        [[NSColor blackColor] set];
//        [[NSBezierPath bezierPathWithRect:[schematic boundingBox]] stroke];
        
        if (selectionBoxIsActive)
        {
            bp = [NSBezierPath bezierPath];
            CGFloat pattern[2];
            pattern[0] = 4.0f; //segment painted with stroke color
            pattern[1] = 3.0f; //segment not painted with a color
            [bp setLineDash:pattern
                      count:2
                      phase:0.0];
            [selectionBoxColor set];
            [bp appendBezierPathWithRect:selectionBox];
            [bp stroke];
        }
        
        [currentContext restoreGraphicsState];
    }
    
    if (highlightPoint)
    {
        [[NSColor colorWithDeviceRed:1.0f green:0.0f blue:0.0f alpha:0.65f] set];
        [[NSBezierPath bezierPathWithOvalInRect:highlightedPoint] fill];
    }
    
    // Highlight visited panning strip
    // Use semi_transparent yellowish color
    [[NSColor colorWithDeviceRed:223.0f/255.0f
                           green:215.0f/255.0f
                            blue:164.0f/255.0f
                           alpha:0.5f] set];
    switch (visitedPanningStrip)
    {
        case MI_DIRECTION_LEFT:
            [NSBezierPath fillRect:NSMakeRect(1, 1, LEFT_PANNING_STRIP_WIDTH - 1, rect.size.height - 2)]; break;
        case MI_DIRECTION_RIGHT:
            [NSBezierPath fillRect:NSMakeRect(rect.size.width - RIGHT_PANNING_STRIP_WIDTH - 1, 1, RIGHT_PANNING_STRIP_WIDTH, rect.size.height - 2)]; break;
        case MI_DIRECTION_UP:
            [NSBezierPath fillRect:NSMakeRect(1, rect.size.height - TOP_PANNING_STRIP_HEIGHT - 1, rect.size.width - 2, TOP_PANNING_STRIP_HEIGHT)]; break;
        case MI_DIRECTION_DOWN:
            [NSBezierPath fillRect:NSMakeRect(1, 1, rect.size.width - 2, BOTTOM_PANNING_STRIP_HEIGHT - 1)]; break;
        default: /*do nothing*/;
    }

    // Draw border - in Mac OS X the desktop light shines from the top
    if ([NSGraphicsContext currentContextDrawingToScreen]
        && !drawToBufferedImage && drawFrame)
    {
        [[NSColor blackColor] set];
        bp = [NSBezierPath bezierPath];
        [bp moveToPoint:NSMakePoint(0, rect.size.height)];
        [bp relativeLineToPoint:NSMakePoint(rect.size.width, 0)];
        [bp stroke];
        [[NSColor grayColor] set];
        bp = [NSBezierPath bezierPath];
        [bp moveToPoint:NSMakePoint(rect.size.width, rect.size.height)];
        [bp relativeLineToPoint:NSMakePoint(0, -rect.size.height)];
        [bp relativeLineToPoint:NSMakePoint(-rect.size.width, 0)];
        [bp relativeLineToPoint:NSMakePoint(0, rect.size.height)];
        [bp stroke];
    }
}


- (void) drawGuides
{
    if ([alignmentPoints count])
    {
        NSEnumerator* alignmentEnum = [alignmentPoints objectEnumerator];
        MI_AlignmentPoint* currentPoint;
        NSBezierPath* bp = [NSBezierPath bezierPath];
        [bp setLineWidth:(scale > 1.0f) ? scale : 1.0f];
        NSPoint pos;
        [placementGuideColor set];
        while (currentPoint = [alignmentEnum nextObject])
        {
            pos = [currentPoint position];
            if ([currentPoint alignsVertically])
            {
                [bp moveToPoint:NSMakePoint(pos.x, 0)];
                [bp lineToPoint:NSMakePoint(pos.x, [self frame].size.height)];
            }
            if ([currentPoint alignsHorizontally])
            {
                [bp moveToPoint:NSMakePoint(0, pos.y)];
                [bp lineToPoint:NSMakePoint([self frame].size.width, pos.y)];
            }
        }
        [bp stroke];
    }
}


- (void) setController:(CircuitDocument*)newController
{
    controller = newController; // Note: No retaining. Just keep the pointer.
}


- (CircuitDocument*) controller
{
    return controller;
}


- (void) setBackgroundColor:(NSColor*)newBackground
{
    backgroundColor = newBackground;
    [self setNeedsDisplay:YES];
}


- (NSColor*) backgroundColor
{
    return [backgroundColor copy];
}


- (void) setScale:(float)newScale
{
    if (newScale >= MI_SCHEMATIC_CANVAS_MAX_SCALE)
        scale = MI_SCHEMATIC_CANVAS_MAX_SCALE;
    else if (newScale <= MI_SCHEMATIC_CANVAS_MIN_SCALE)
        scale = MI_SCHEMATIC_CANVAS_MIN_SCALE;
    else
        scale = newScale;
    //NSLog(@"scale = %f", scale);
    [self setNeedsDisplay:YES];
}


- (float) scale
{
    return scale;
}


- (void) setPrintScale:(float)newScale
{
    printScale = newScale;
}


- (void) setViewportOffset:(NSPoint)newOffset
{
    viewportOffset = newOffset;
    [self clearAlignmentPoints];
    [self clearPointHighlight];
}


- (NSPoint) viewportOffset
{
    return viewportOffset;
}


- (NSPoint) canvasPointToSchematicPoint:(NSPoint)point
{
    NSSize s = [self frame].size;
    return NSMakePoint((point.x - s.width/2)/scale + s.width/2 - viewportOffset.x,
                       (point.y - s.height/2)/scale + s.height/2 - viewportOffset.y);
}


- (NSPoint) schematicPointToCanvasPoint:(NSPoint)point
{
    NSSize s = [self frame].size;
    return NSMakePoint((point.x + viewportOffset.x - s.width/2) * scale + s.width/2,
                       (point.y + viewportOffset.y - s.height/2) * scale + s.height/2);
}


- (NSRect) canvasRectToSchematicRect:(NSRect)canvasRect
{
    NSPoint newOrigin = [self canvasPointToSchematicPoint:canvasRect.origin];
    return NSMakeRect(newOrigin.x, newOrigin.y, canvasRect.size.width * scale, canvasRect.size.height * scale);
}


- (NSRect) schematicRectToCanvasRect:(NSRect)schematicRect
{
    NSPoint newOrigin = [self schematicPointToCanvasPoint:schematicRect.origin];
    return NSMakeRect(newOrigin.x, newOrigin.y, schematicRect.size.width * scale, schematicRect.size.height * scale);
}


- (void) relativeMoveViewportOffset:(NSPoint)relativeDistance
{
    NSPoint offset = [self viewportOffset];
    offset.x += relativeDistance.x;
    offset.y += relativeDistance.y;
    [self setViewportOffset:offset];
}


- (void) showGuides:(BOOL)doShowGuides
{
    showGuides = doShowGuides;
}


- (BOOL) showsGuides
{
    return showGuides;
}


- (void) setSelectionBoxIsActive:(BOOL)active
{
    selectionBoxIsActive = active;
}


- (void) setSelectionBox:(NSRect)box
{
    selectionBox = box;
}

- (void) setSelectionBoxStartPoint:(NSPoint)start
{
    selectionBoxStartPoint = start;
}

- (NSPoint) selectionBoxStartPoint
{
    return selectionBoxStartPoint;
}

- (void) clearAlignmentPoints
{
    [alignmentPoints removeAllObjects];
}

- (void) addAlignmentPoint:(MI_AlignmentPoint*)point
{
    [alignmentPoints addObject:point];
}

- (void) highlightPoint:(NSPoint)point
                   size:(float)radius;
{
    highlightedPoint = NSMakeRect(point.x - radius, point.y - radius, 2*radius, 2* radius);
    highlightPoint = YES;
}

- (void) clearPointHighlight
{
    highlightPoint = NO;
}

- (void) setDrawsFrame:(BOOL)draw
{
    drawFrame = draw;
}

// Overrides NSView method to provide click-through behavior
- (BOOL)acceptsFirstMouse:(NSEvent*)theEvent
{
    return YES;
}


- (NSRect) workArea
{
    return WorkArea;
}


/******************** Mouse methods **********************/

- (NSDragOperation) draggingSourceOperationMaskForLocal:(BOOL)flag
{
    return NSDragOperationGeneric;
}


- (void) mouseUp:(NSEvent*)theEvent
{
    panning = NO;
    [[NSCursor arrowCursor] set];
    
    [[[SugarManager sharedManager] currentTool]
        mouseUp:[[controller model] schematic]
          event:theEvent
         canvas:self];
}


- (void) mouseDragged:(NSEvent*)theEvent
{
    if (panning)
        [self otherMouseDragged:theEvent];
    else
    {
        NSPoint currentPoint = [self convertPoint:[theEvent locationInWindow]
                                         fromView:nil];
        
        // auto panning
        if (!NSPointInRect(currentPoint, [self frame]))
        {
            // Find out which edge is closest
            NSRect f = [self frame];            
            float distanceToLeftEdge = currentPoint.x - f.origin.x;
            float distanceToRightEdge = currentPoint.x - f.origin.x - f.size.width;
            float distanceToTopEdge = currentPoint.y - f.origin.y - f.size.height;
            float distanceToBottomEdge = currentPoint.y - f.origin.y;
            float offsetX = 0.0f;
            float offsetY = 0.0f;
            if ((distanceToLeftEdge * distanceToRightEdge) > 0) // same signs
            {
                // left or right edge
                offsetX = 8.0f * ((fabs(distanceToLeftEdge) > fabs(distanceToRightEdge)) ? -1.0f : 1.0f);
            }
            else
            {
                // top or bottom
                offsetY = 8.0f * ((fabs(distanceToBottomEdge) > fabs(distanceToTopEdge)) ? -1.0f : 1.0f);
            }
            [self relativeMoveViewportOffset:NSMakePoint(offsetX, offsetY)];            
        }
        
        [[[SugarManager sharedManager] currentTool]
            mouseDragged:[[controller model] schematic]
                   event:theEvent
                  canvas:self];
    }
}


- (void) scrollWheel:(NSEvent*)theEvent
{
    [controller scaleShouldChange:([self scale] + [theEvent deltaY]/20.0f)];
}


- (void) mouseDown:(NSEvent*)theEvent
{
    if (!NSPointInRect([self convertPoint:[theEvent locationInWindow] fromView:nil],
                       [self schematicRectToCanvasRect:WorkArea]))
        return;

    const float stepSize = 100.0f/scale;
    switch (visitedPanningStrip)
    {
        // Move the canvas in the opposite direction of the clicked panning strip
        case MI_DIRECTION_LEFT:
            [self relativeMoveViewportOffset:NSMakePoint( stepSize,    0.0f)]; break;
        case MI_DIRECTION_RIGHT:
            [self relativeMoveViewportOffset:NSMakePoint( -stepSize,    0.0f)]; break;
        case MI_DIRECTION_UP:
            [self relativeMoveViewportOffset:NSMakePoint(   0.0f, -stepSize)]; break;
        case MI_DIRECTION_DOWN:
            [self relativeMoveViewportOffset:NSMakePoint(   0.0f, stepSize)]; break;
        default: ;
    }
    
    if (visitedPanningStrip != MI_DIRECTION_NONE)
        [self setNeedsDisplay:YES];
    else
    {
        [[self window] makeFirstResponder:self];
        // The tool is responsible for panning the view
        // if the Option key was pressed.
        [[[SugarManager sharedManager] currentTool]
            mouseDown:[[controller model] schematic]
                event:theEvent
               canvas:self];
    }
}


- (void) rightMouseDown:(NSEvent*)theEvent
{
    [[[SugarManager sharedManager] currentTool]
        rightMouseDown:[[controller model] schematic]
                 event:theEvent
                canvas:self];
}


- (void) rightMouseDragged:(NSEvent*)theEvent
{
    [[[SugarManager sharedManager] currentTool]
        rightMouseDragged:[[controller model] schematic]
                    event:theEvent
                   canvas:self];
}


- (void) rightMouseUp:(NSEvent*)theEvent
{
    [[[SugarManager sharedManager] currentTool]
        rightMouseUp:[[controller model] schematic]
               event:theEvent
              canvas:self];
}


- (void) mouseMoved:(NSEvent*)theEvent
{    
    NSPoint mousePosition =
        [self convertPoint:[theEvent locationInWindow]
                    fromView:nil];
    if (!NSPointInRect(mousePosition, [self schematicRectToCanvasRect:WorkArea]))
        return;

    MI_Direction previouslyVisitedPanningStrip = visitedPanningStrip;
    NSSize s = [self frame].size;
    if (NSPointInRect(mousePosition, NSMakeRect(0, 0, LEFT_PANNING_STRIP_WIDTH, s.height)))
        visitedPanningStrip = MI_DIRECTION_LEFT;
    else if (NSPointInRect(mousePosition, NSMakeRect(s.width - RIGHT_PANNING_STRIP_WIDTH, 0, RIGHT_PANNING_STRIP_WIDTH, s.height)))
        visitedPanningStrip = MI_DIRECTION_RIGHT;
    else if (NSPointInRect(mousePosition, NSMakeRect(0, s.height - TOP_PANNING_STRIP_HEIGHT, s.width, TOP_PANNING_STRIP_HEIGHT)))
        visitedPanningStrip = MI_DIRECTION_UP;
    else if (NSPointInRect(mousePosition, NSMakeRect(0, 0, s.width, BOTTOM_PANNING_STRIP_HEIGHT)))
        visitedPanningStrip = MI_DIRECTION_DOWN;
    else
        visitedPanningStrip = MI_DIRECTION_NONE;
    
    [[[SugarManager sharedManager] currentTool]
          mouseMoved:[[controller model] schematic]
               event:theEvent
              canvas:self];

    if (previouslyVisitedPanningStrip != visitedPanningStrip)
        [self setNeedsDisplay:YES];
}

/****************************** The middle button is used for panning *******/

- (void) otherMouseDown:(NSEvent*)theEvent
{
    // prepare for panning
    panning = YES;
    highlightPoint = NO;
    [self clearAlignmentPoints];
    panningStartPoint = [self convertPoint:[theEvent locationInWindow]
                                  fromView:nil];
    [[NSCursor closedHandCursor] set];
}


- (void) otherMouseDragged:(NSEvent*)theEvent
{
    // Pan view
    NSPoint currentPoint = [self convertPoint:[theEvent locationInWindow]
                                     fromView:nil];

    NSPoint diff = NSMakePoint((currentPoint.x - panningStartPoint.x)/scale,
                               (currentPoint.y - panningStartPoint.y)/scale);
    [self relativeMoveViewportOffset:diff];
    panningStartPoint = currentPoint;
    
    [self setNeedsDisplay:YES];

    [[[controller model] schematic] markAsModified:YES];
}


- (void) otherMouseUp:(NSEvent*)theEvent
{
    panning = NO;
    [[NSCursor arrowCursor] set];
}

/************************************************************************************/

- (void) keyDown:(NSEvent*)theEvent
{
    //[controller keyDown:theEvent];
    // Check for various canvas operations before delegating to the current tool

    // Check if the user wants to zoom in/out with Command +/-
    NSString* chars = [theEvent characters];
    BOOL consumed = YES;
    if ([chars isEqualToString:@"="] || [chars isEqualToString:@"-"] || [chars isEqualToString:@"+"])
    {
        if ([chars isEqualToString:@"-"])
            [controller scaleShouldChange:([self scale] / 1.2f)];
        else
            [controller scaleShouldChange:([self scale] * 1.2f)];
    }
    else if ( [chars isEqualToString:@"1"] ||
                [chars isEqualToString:@"2"] ||
                [chars isEqualToString:@"3"] ||
                [chars isEqualToString:@"4"] )
    {
        int variant = [chars intValue] - 1;
        [controller switchToSchematicVariant:[NSNumber numberWithInt:variant]];
    }
    else if ([theEvent modifierFlags] & NSEventModifierFlagOption)
    {
        // Check if the user wants to pan the view
        const float stepSize = 100.0f/scale;
        if ([chars characterAtIndex:0] == NSUpArrowFunctionKey)
            [self relativeMoveViewportOffset:NSMakePoint(0.0f, -stepSize)];
        else if ([chars characterAtIndex:0] == NSDownArrowFunctionKey)
            [self relativeMoveViewportOffset:NSMakePoint(0.0f,  stepSize)];
        else if ([chars characterAtIndex:0] == NSLeftArrowFunctionKey)
            [self relativeMoveViewportOffset:NSMakePoint( stepSize, 0.0f)];
        else if ([chars characterAtIndex:0] == NSRightArrowFunctionKey)
            [self relativeMoveViewportOffset:NSMakePoint(-stepSize, 0.0f)];
        else consumed = NO;
    }
    else
        consumed = NO;

    if (!consumed)
        [[[SugarManager sharedManager] currentTool]
                keyDown:[[controller model] schematic]
                  event:theEvent
                 canvas:self];
    else
        [self setNeedsDisplay:YES];
}


- (BOOL) performKeyEquivalent:(NSEvent*)theEvent
{
    NSString* character = [theEvent characters];
    if ( ([character length] == 1) &&
         ([theEvent modifierFlags] & NSEventModifierFlagCommand) &&
         ( [character isEqualToString:@"1"] ||
           [character isEqualToString:@"2"] ||
           [character isEqualToString:@"3"] ||
           [character isEqualToString:@"4"] ) )
    {
            int variant = [character intValue] - 1;
            [controller copySchematicToVariant:[NSArray arrayWithObjects:
                    [[controller model] schematic], [NSNumber numberWithInt:variant], nil]];
            return YES;
    }
    else if ( ([[self window] firstResponder] == self) &&
        [[[SugarManager sharedManager] currentTool]
            performKeyEquivalent:[[controller model] schematic]
                           event:theEvent
                          canvas:self])
        return YES;
    else
        return [super performKeyEquivalent:theEvent];
}


/******************** NSDraggingDestination methods *******************/

//- (void) concludeDragOperation:(id <NSDraggingInfo>)sender{}
//- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender{}
//- (void) draggingEnded:(id <NSDraggingInfo>)sender{}

- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([[pboard types] containsObject:NSURLPboardType] ||
    	[[pboard types] containsObject:MI_SchematicElementPboardType])
    {
        //frameColor = highlightColor;
        //[self setNeedsDisplay:YES];
        return NSDragOperationCopy;
    }
    else
        return NSDragOperationNone;
}


- (void) draggingExited:(id <NSDraggingInfo>)sender
{
    //frameColor = passiveColor;
    //[self setNeedsDisplay:YES];
}


/*
- (NSDragOperation) draggingUpdated:(id <NSDraggingInfo>)sender
{
    return NSDragOperationCopy;
}
*/

- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPoint destination = [self convertPoint:[sender draggedImageLocation]
                                    fromView:nil];
    destination = [self canvasPointToSchematicPoint:destination];
    
    MI_Schematic* schematic = [[controller model] schematic];

    if ([[[sender draggingPasteboard] types] containsObject:MI_SchematicElementPboardType])
    {
        NSEnumerator* elementEnum;
        MI_SchematicElement* tmpElement;
        BOOL alreadyInSchematic = NO;
        
        MI_SchematicElement* droppedElement =
            [NSKeyedUnarchiver unarchiveObjectWithData:
                [[sender draggingPasteboard] dataForType:MI_SchematicElementPboardType]];
    
        destination = NSMakePoint(destination.x + [droppedElement size].width/2.0f,
                                  destination.y + [droppedElement size].height/2.0f);

        // Checking if an object with the same identifier string already exists in the schematic.
        elementEnum = [schematic elementEnumerator];
        while (tmpElement = [elementEnum nextObject])
            if ([tmpElement isEqual:droppedElement])
            {
                // Same element found! Setting its position...
                [tmpElement setPosition:destination];
                alreadyInSchematic = YES;
                break;
            }
    
        if (!alreadyInSchematic)
        {
            [[self controller] createSchematicUndoPointForModificationType:MI_SCHEMATIC_ADD_CHANGE];
            //WARNING: the identifier string must be changed if the dragged element was in another schematic. 
            [droppedElement setPosition:destination];
            if (![schematic addElement:droppedElement])
            {
                NSBeep();
                // MISSING: Show error message.
            }
            else
            {
                // Check if this is a node element that was dropped on a connector line
                if ( [droppedElement conformsToProtocol:@protocol(MI_InsertableSchematicElement)] )
                {
                    // Are we supposed to insert the node into a connection line?
                    if ( [[[NSUserDefaults standardUserDefaults] objectForKey:MISUGAR_AUTOINSERT_NODE_ELEMENT] boolValue] )
                    {
                        MI_ElementConnector* conn = [schematic connectorForPoint:destination radius:2.0f];
                        if (conn != nil)
                        {
                          [schematic splitConnector:conn withElement:(MI_SchematicElement<MI_InsertableSchematicElement>*)droppedElement];
                        }
                    }
                }
                // Automatically select and inspect the new element
                [[[controller model] schematic] deselectAll];
                [[[controller model] schematic] selectElement:droppedElement];
                [[MI_Inspector sharedInspector] inspectElement:droppedElement];
            }
        }
    }
    else
    {
        // The dropped object is a file
        NSPasteboard *pboard = [sender draggingPasteboard];
        if ( [[pboard types] containsObject:NSURLPboardType] )
            [controller processDrop:sender];
    }
    //frameColor = passiveColor;
    [self setNeedsDisplay:YES];
    return YES;
}

/************************************************************* PRINTING *********/

// This method signals that this view performs its own pagination calculations.
// The canvas declares that the whole schematic will be printed on a single page.
- (BOOL) knowsPageRange:(NSRangePointer)range
{
    range->location = 1;
    range->length = 1;
    return YES;
}


- (NSRect) rectForPage:(NSInteger)pageNumber
{
    NSRect printRect = NSInsetRect([[[controller model] schematic] boundingBox], -5.0f, -5.0f);
    printRect.origin = NSMakePoint(0,0);//[self schematicPointToCanvasPoint:printRect.origin];
    printRect.size.width *= printScale;
    printRect.size.height *= printScale;
    return printRect;
}


- (NSString*) printJobTitle
{
    return @"MI-SUGAR schematic";
}


@end
