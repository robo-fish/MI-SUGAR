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

#define MI_SCHEMATIC_VERSION 1

@interface MI_CircuitSchematic : MI_Schematic <NSCoding, NSCopying>

- (BOOL) isSubcircuit;
- (void) setIsSubcircuit:(BOOL)subcircuit;

/* Called during the schematic-to-netlist conversion */
- (void) setNodeAssignmentTable:(NSArray*)newAssignmentTable;

/* Returns YES if assigned node numbers are drawn next to the connection points
    of elements. */
- (BOOL) showsNodeNumbers;

/* Turns displaying of node numbers on or off. */
- (void) setShowsNodeNumbers:(BOOL)show;

// Creates a postfix (an integer number, the current count of elements of that
// type in the schematic) for the given type of element. Type should be the
// class name of the element. The number is incremented automatically.
- (NSString*) postfixForElementType:(NSString*)type;

@end
