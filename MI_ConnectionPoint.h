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
#import "common.h"

#define MI_CONNECTION_POINT_VERSION 1
/*
 Version | Note
 -----------------------------------------------------------
    0    | MI-SUGAR 0.5 and 0.5.1
    1    | MI-SUGAR 0.5.2, adds support for node number placement
*/

/* These are points at which MI_ElementConnector and MI_SchematicElement
objects can be connected with each other. A connection point can only
be connected to by an element connector. The connection point itself
knows nothing about a connection. Connection information is managed by
the schematic. */
@interface MI_ConnectionPoint : NSObject <NSCoding, NSCopying>
{
    NSPoint relativePosition; // position of the center of the point, relative to the center of parent
    NSSize size; // size is needed although the point is invisible
    NSString* name;
    MI_Direction preferredNodeNumberPlacement;
    int MI_version; // see version note above
}
- (instancetype) initWithPosition:(NSPoint)relativePos
                   size:(NSSize)theSize
                   name:(NSString*)name
    nodeNumberPlacement:(MI_Direction)nodePlacement;

/* for compatibility */
- (instancetype) initWithPosition:(NSPoint)myRelativePos
                   size:(NSSize)theSize
                   name:(NSString*)myName;

- (NSPoint) relativePosition; // center position relative to parent

- (void) setRelativePosition:(NSPoint)newPosition; // needs to be called when the parent element is transformed

- (NSString*) name; // name of this connection point

- (NSSize) size;

- (MI_Direction) preferredNodeNumberPlacement; 

@end
