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
#import "CircuitDocument.h"
#import "MI_ElementConnector.h"
#import "MI_SchematicElement.h"
#import "MI_AlignmentPoint.h"

@class CircuitDocument;

#define MI_SCHEMATIC_CANVAS_MAX_SCALE 3.5f
#define MI_SCHEMATIC_CANVAS_MIN_SCALE 0.5f

// Instances of this class are responsible for displaying MI_Schematic objects
// and for providing 'visual effects' like alignment lines, selection boxes,
// scaling and background coloring. Canvases also process dropped elements.
@interface MI_SchematicsCanvas : NSView
{
    // The extend of the working area. This is a constant.
    NSRect WorkArea;
    
    NSColor* backgroundColor;
    NSColor* gridColor;
    NSColor* highlightColor;
    NSColor* passiveColor;
    NSColor* placementGuideColor;
    NSColor* selectionBoxColor;
    NSColor* frameColor;            // set to highlightColor or passiveColor
    BOOL showGuides;                // to turn showing of placement guides on/off
    BOOL drawFrame;                 // to turn on/off drawing a frame at the view border
    float printScale;               // the zoom factor used for printing - no constraints
    
    // The zoom factor by which the schematic, seen through the viewport, is
    // magnified. Interactive zooming operations take the center of the canvas
    // as the center of the scaling transformation.
    float scale;

    CircuitDocument* controller;
    
    NSPoint selectionBoxStartPoint;
    NSRect selectionBox;
    BOOL selectionBoxIsActive;

    NSMutableArray* alignmentPoints; // the array of points where the alignments occur
    NSRect highlightedPoint;         // the area that is highlighted
    BOOL highlightPoint;             // indicates if point highlighting is enabled
    
    // Used to get the panning strip which the mouse is currently visiting.
    // Based on this info a panning strip is highlighted.
    MI_Direction visitedPanningStrip;

    /**
    * The translation from canvas mid point to schematic origin, in the schematic coordinate space.
    */
    NSPoint viewportOffset;
    
    // YES if the user is panning by ALT-clicking on an empty area and dragging
    BOOL panning;
    NSPoint panningStartPoint;
}
// Moves the lower left corner of the bounding box of the schematic to the
// origin before drawing. Uses the given scale instead of the canvas scale.
- (void) drawToBufferedImageWithRect:(NSRect)theRect
                               scale:(float)theScale;

- (void) drawGuides;

- (void) setController:(CircuitDocument*)newController;

- (CircuitDocument*) controller;

- (void) setBackgroundColor:(NSColor*)newBackground;

- (NSColor*) backgroundColor;

- (void) setScale:(float)newScale;
- (float) scale;

- (void) setPrintScale:(float)newScale;

- (void) showGuides:(BOOL)doShowGuides;
- (BOOL) showsGuides;

- (void) setSelectionBoxIsActive:(BOOL)active;
- (void) setSelectionBox:(NSRect)box;
- (void) setSelectionBoxStartPoint:(NSPoint)start;
- (NSPoint) selectionBoxStartPoint;

// The next two methods set/unset the coordiantes required to draw alignment lines
- (void) clearAlignmentPoints;
- (void) addAlignmentPoint:(MI_AlignmentPoint*)point;

// The next two methods set/clear a point in the canvas which is highlighted.
// The canvas draws a red dot at that position
- (void) highlightPoint:(NSPoint)point
                   size:(float)radius;
- (void) clearPointHighlight;

- (void) setViewportOffset:(NSPoint)newOffset;
- (NSPoint) viewportOffset;

// Moves the viewport center by the given distance relative to its current position.
- (void) relativeMoveViewportOffset:(NSPoint)relativeDistance;

// Converts a point from the coordinate space of the drawn view to schematic coordinate space
- (NSPoint) canvasPointToSchematicPoint:(NSPoint)canvasPoint;
// Converts a point from the schematic coordinate space to the coordinate space of the drawn view
- (NSPoint) schematicPointToCanvasPoint:(NSPoint)schematicPoint;
// Converts a rectangle from the coordinate space of the drawn view to schematic coordinate space
- (NSRect) canvasRectToSchematicRect:(NSRect)canvasRect;
// Converts a rectangle from the schematic coordinate space to the coordinate space of the drawn view
- (NSRect) schematicRectToCanvasRect:(NSRect)schematicRect;

- (void) setDrawsFrame:(BOOL)drawFrame;

// Returns the area in which schematic elements are allowed
- (NSRect) workArea;
@end

