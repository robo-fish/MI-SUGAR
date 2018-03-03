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

// Moves the lower left corner of the bounding box of the schematic to the
// origin before drawing. Uses the given scale instead of the canvas scale.
- (void) drawToBufferedImageWithRect:(NSRect)theRect scale:(float)theScale;

@property (weak) CircuitDocument* controller;

@property (nonatomic) NSColor* backgroundColor;

@property (nonatomic) float scale;

@property (nonatomic) float printScale; // the zoom factor used for printing

@property BOOL showsGuides; // whether to show placement guides

@property BOOL selectionBoxIsActive;
@property CGRect selectionBox;
@property NSPoint selectionBoxStartPoint;

// The next two methods set/unset the coordiantes required to draw alignment lines
- (void) clearAlignmentPoints;
- (void) addAlignmentPoint:(MI_AlignmentPoint*)point;

// The next two methods set/clear a point in the canvas which is highlighted.
// The canvas draws a red dot at that position
- (void) highlightPoint:(NSPoint)point size:(float)radius;
- (void) clearPointHighlight;

@property (nonatomic) NSPoint viewportOffset;

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

@property (readonly, nonatomic) NSRect workArea; // area in which schematic elements are allowed

@end

