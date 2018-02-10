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
#include "common.h"
#import "MI_ConnectionPoint.h"

/* The protocol below is for schematic elements, which
can be inserted into a connection line. Such an element
must have at least 4 connection points of which 2 will
will be used to connect the open ends of the new connection
lines formed by splitting the line into which the element
is inserted. */
@protocol MI_InsertableSchematicElement
- (MI_ConnectionPoint*) topPoint;
- (MI_ConnectionPoint*) bottomPoint;
- (MI_ConnectionPoint*) leftPoint;
- (MI_ConnectionPoint*) rightPoint;
@end

@interface MI_SchematicElement : NSObject
    <NSCoding, NSCopying, MI_Inspectable>
{
    NSString* identifier;
    NSSize originalSize;            // size when rotation is 0 (see 'size' below)
    NSSize size;                    // size of the rectangle into which the element's graphical representation fits - depends on rotation
    NSPoint position;               // center of the rectangle into which the element's graphical representation fits
    NSMutableString* name;          // element name
    NSString* theNamespace;         // element namespace, used to differentiate elements with identical names - since 0.5.3
    float rotation;                 // the rotation of the graphical representation, in degrees
    BOOL flippedHorizontally;
    NSDictionary* connectionPoints; // keys = connection point name, values = MI_ConnectionPoint
    NSMutableString* label;
    BOOL showsLabel;
    int revision;                   // the version number of the element - since 0.5.3
    MI_Direction labelPosition;
    NSMutableString* comment;       // stores user comments about instances - since 0.5.3
}
- (NSString*) identifier;
- (NSSize) size;
- (NSPoint) position;
- (void) setPosition:(NSPoint)newPosition;
- (NSDictionary*) connectionPoints;
- (void) setConnectionPoints:(NSDictionary*)newConnectionPoints;
- (NSDictionary*) alignableConnectionPoints; // returns the connection points which can be used for checking alignment with other connection points
- (NSString*) label;
- (void) setLabel:(NSString*)newLabel;
- (NSImage*) image;
- (NSString*) name;
- (void) setName:(NSString*)newName;
- (NSString*) elementNamespace;
- (void) setElementNamespace:(NSString*)newNamespace;
- (NSString*) fullyQualifiedName;                           // convenience method which concatenates the namespace and the name, with a dot inbetween
- (MI_Direction) labelPosition;
- (void) setLabelPosition:(MI_Direction)newLabelPosition;
- (void) setShowsLabel:(BOOL)showLabel;
- (float) rotation;                                         // rotation in degrees, value between 0 and 360
- (void) setRotation:(float)newRotation;                    // newRotation must be in degrees
- (void) flip:(BOOL)horizontally;
- (BOOL) flippedHorizontally;                               // returns YES if the element's graphical representation is flipped horizontally
- (int) revision;                                           // returns the revision number - there must be no setter method
- (NSString*) comment;
- (void) setComment:(NSString*)newComment;

- (NSRect) totalRect;                                       // calculates the area occupied by this elements together with its label - needed for printing

/* Returns a short character string for quickly seeing important information about the element. */
- (NSString*) quickInfo;

/* Draws the graphical representation of the element */
- (void) draw;

/* Must be called by subclasses after drawing finishes
in order to reset transformations that may have been applied. */
- (void) endDraw;

+ (NSString*) newIdentifier; // creates and returns a new identifier

+ (NSDictionary*) labelFontAttributes; // returns the application-wide label font attributes

// Next two methods are used for exporting the schematic to SVG (Scalable Vector Graphics)
// Returns the part that is common to all elements. That is, rotation and mirroring.
- (NSString*) shapeToSVG;
// Finishes the transformation that were applied in shapeToSVG:
- (NSString*) endSVG;

@end
