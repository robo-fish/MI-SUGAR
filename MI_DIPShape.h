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
#import "MI_Shape.h"

/*

 Provides a Dual In-line Package (DIP) shape for use with subcircuits.
 In its initial orientation the pins of the DIP are at the bottom and the top
 where pin number 1 is nearer to the left. The name of the subcircuit type is
 drawn into its body. The length of the shape depends on the number of pins.
 The width is a constant 36.0 units (including pins).
 The pins are thin lines of length 5.0.
 The distance between two neighboring pins is 10.0 and the distance between
 the last pin in a line and the nearest edge is half of that.
 Important: Pin numbering in counter-clockwise.
 
   8  7  6  5 
   |  |  |  |
  ------------
 |            |
 |]  Example  |
 | *          |
  ------------
   |  |  |  |
   1  2  3  4 
 
*/
@interface MI_DIPShape : MI_Shape <NSCoding, NSCopying>
{
    int numberOfPins;
    NSString* name;
}
- (id) initWithNumberOfPins:(int)numPins;

- (void) setName:(NSString*)newName;

- (NSString*) name;
@end
