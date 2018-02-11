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
#import "MI_ConnectionPoint.h"

// the maximum extent of a shape, in any direction.
extern const float MI_SHAPE_MAX_EXTENT;

// Objects of this class can be used to define the shape of subcircuits.
// Connection points are also defined. This is the base class which
// does little else than to provide the connection points and the size.
// Concrete subclasses provide various ways of drawing the shape.
@interface MI_Shape : NSObject <NSCoding, NSCopying>

- (instancetype) initWithSize:(NSSize)size;

// Maps connection point names to connection point objects
@property NSDictionary<NSString*,MI_ConnectionPoint*>* connectionPoints;

@property (readonly) NSSize size;

// Does nothing - subclasses must override this to draw the shape
- (void) drawAtPoint:(NSPoint)position;

// Does nothing - subclasses should override this method to return the
// SVG equivalent of the shape.
- (NSString*) shapeToSVG;

@end
