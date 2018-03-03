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
#import <Foundation/Foundation.h>
#import "MI_ComplexNumber.h"
#import "MI_ViewArea.h"

/* Default policy when representing a complex number as a single floating point number */
enum floatRepresentation { MAGNITUDE = 0, REAL, IMAGINARY };

/*
 This class defines the objects that represent an analysis variable
 and are constructed before the results are plotted.
 Analysis variables may hold multiple arrays of values and, therefore,
 can also be used when the circuit analysis type is DC and there is
 a second sweep variable;
 */
@interface AnalysisVariable : NSObject

- (instancetype) initWithName:(NSString*)varName;

- (long) numberOfSets; // typically this is one (1)

- (long) numberOfValuesPerSet; // the length of the equally-large value arrays

- (NSString*) name;

- (double) scaleFactor;

- (void) setScaleFactor:(double)factor;

/* the returned value depends on the float representation mode if
    the variable is made of complex numbers. */
- (double) averageValue;

- (void) calculateAverageValue;	// call only after all values are set

- (void) findMinMax;	// find the maximum and minimum of all values of all sets. call only after all values are set.

- (double) maximum; // return maximum of all values of all sets

- (double) minimum; // return minimum of all values of all sets

- (double) realMinimum; // return minimum of real part

- (double) realMaximum; // return maximum of real part

- (double) imaginaryMinimum; // return minimum of imaginary part

- (double) imaginaryMaximum; // return maximum of imaginary part

- (BOOL) isScalingAroundAverage;

- (void) setScalingAroundAverage:(BOOL)aroundAverage;

- (int) type;

- (BOOL) isComplex; // returns YES if the values are complex numbers

- (enum floatRepresentation) floatRepresentation;

- (void) setFloatRepresentation:(enum floatRepresentation)floatRep;

/* Automatically creates a new set of values when the given setIndex is larger
   than the largest index of all created sets */
- (void) addValue:(double)value
            toSet:(int)setIndex;

/* Same as above but for complex numbers. */
- (void) addComplexValue:(MI_ComplexNumber*)value
                   toSet:(int)setIndex;

/* Sets the values of a complete set
- (void) setValues:(NSArray*)newValues
            forSet:(int)setIndex;
*/

/* Returns the value of the given set at the given index.
    If the value is a complex number, the float representation is used. */
- (double) valueAtIndex:(int)valueIndex
                 forSet:(int)setIndex;

/* Returns nil if the value is not a complex number. */
- (MI_ComplexNumber*) complexValueAtIndex:(int)numberIndex
                                forSet:(int)setIndex;

/* Returns an array of NSNumber objects of double value.
    The returned array is not a copy. Do not release it! */
- (NSArray*) valuesOfSet:(int)setIndex;

@end
