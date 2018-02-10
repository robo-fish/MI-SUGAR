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
#import "AnalysisVariable.h"

@implementation AnalysisVariable
{
  NSString* name;
  double scaleFactor;     // the scale factor for presentation purposes - does not alter the stored values
  double averageValue;  // the average of all values, also valid for magnitude of complex numbers
  double averageValueReal; // average value of real part
  double averageValueImaginary; // average value of imaginary part
  BOOL scalingAroundAverage;  // YES if scaling is performed around the average value
  BOOL foundAverage;  // indicates that the average is already calculated
  double maximum; // maximum of magnitude, if complex
  double maximumReal; // maximum of real part
  double maximumImaginary; // maximum of imaginary part
  double minimum; // minimum of magnitude, if complex
  double minimumReal; // minimum of real part
  double minimumImaginary; // minimum of imaginary part
  BOOL foundMinMax;  // indicates that the maximum and minimum values were already found
  enum VariableType {Voltage = 0, Current, Time} type;
  NSMutableArray* values; // an array of arrays of double numbers
  BOOL complex;
  enum floatRepresentation float_representation;
}

- (id) initWithName:(NSString*)varName
{
    if (self = [super init])
    {
        values = [[NSMutableArray arrayWithCapacity:1] retain];
        name = [varName retain];
        scaleFactor = 1.0;
        averageValue = 0.0;
        scalingAroundAverage = NO;
        foundMinMax = NO;
        foundAverage = NO;
        complex = NO;
        float_representation = MAGNITUDE;
    }
    return self;
}


- (long) numberOfSets
{
    return [values count];
}


- (long) numberOfValuesPerSet
{
    if ([values count] > 0)
        return [[values objectAtIndex:0] count];
    else
        return 0;
}


- (NSString*) name { return name; }
- (int) type { return type; }
- (double) scaleFactor { return scaleFactor; }
- (void) setScaleFactor:(double)factor { scaleFactor = factor; }


- (double) averageValue
{
    if (!complex)
        return averageValue;
    else
    {
        switch (float_representation)
        {
            case MAGNITUDE:
                return averageValue;
            case REAL:
                return averageValueReal;
            case IMAGINARY:
                return averageValueImaginary;
            default:
                return averageValue;
        }
    }
}


- (void) calculateAverageValue
{
    double average, averageReal, averageImaginary;
    long i, j;
    NSMutableArray* tmpSet;
    double totalNumValues = (double)([self numberOfSets] * [self numberOfValuesPerSet]);

    average = averageReal = averageImaginary = 0.0;

    if (complex)
    {
        MI_ComplexNumber* cn;
        for (i = [self numberOfSets] - 1; i >= 0; i--)
        {
            tmpSet = [values objectAtIndex:i];
            for (j = [self numberOfValuesPerSet] - 1; j >= 0; j--)
            {
                cn = [tmpSet objectAtIndex:j];
                average += [cn magnitude];
                averageReal += [cn real];
                averageImaginary += [cn imaginary];
            }
        }
        averageReal /= totalNumValues;
        averageImaginary /= totalNumValues;
        averageValueReal = averageReal;
        averageValueImaginary = averageImaginary;
    }
    else
    {
        for (i = [self numberOfSets] - 1; i >= 0; i--)
        {
            tmpSet = [values objectAtIndex:i];
            for (j = [self numberOfValuesPerSet] - 1; j >= 0; j--)
                average += [[tmpSet objectAtIndex:j] doubleValue];
        }
    }
    average /= totalNumValues;
    
    averageValue = average;
    foundAverage = YES;
}


- (BOOL) isScalingAroundAverage
{
    return scalingAroundAverage;
}


- (void) setScalingAroundAverage:(BOOL)aroundAverage
{
    scalingAroundAverage = aroundAverage;
}


- (void) findMinMax
{
    if ([values count] == 0)
        maximum = maximumReal = maximumImaginary =
        minimum = minimumReal = minimumImaginary = 0.0;
    else
    {
        long i, j;
        double tmpMax, tmpMaxReal, tmpMaxImag, tmpMin,
            tmpMinReal, tmpMinImag, current;
        NSMutableArray* tmpSet;
        
        tmpMax = tmpMin =
            [[[values objectAtIndex:0] objectAtIndex:0] doubleValue];
        if (complex)
        {
            tmpMaxReal = tmpMinReal = [[[values objectAtIndex:0] objectAtIndex:0] real];
            tmpMaxImag = tmpMinImag = [[[values objectAtIndex:0] objectAtIndex:0] imaginary];
        }
        else
            tmpMaxReal = tmpMinReal = tmpMaxImag = tmpMinImag = 0.0;
        
        for (i = [self numberOfSets] - 1; i >= 0; i--)
        {
            tmpSet = [values objectAtIndex:i];

            // This block also processes the magnitude values if the numbers are complex
            for (j = [self numberOfValuesPerSet] - 1; j >= 0; j--)
            {
                current = [[tmpSet objectAtIndex:j] doubleValue];
                if (tmpMax < current)
                    tmpMax = current;
                else if (tmpMin > current)
                    tmpMin = current;
                if (complex)
                {
                    // real and imaginary part max/min values of complex numbers
                    current = [[tmpSet objectAtIndex:j] real];
                    if (tmpMaxReal < current)
                        tmpMaxReal = current;
                    else if (tmpMinReal > current)
                        tmpMinReal = current;
                    current = [[tmpSet objectAtIndex:j] imaginary];
                    if (tmpMaxImag < current)
                        tmpMaxImag = current;
                    else if (tmpMinImag > current)
                        tmpMinImag = current;
                }
                
            }
        }

        maximum = tmpMax;
        minimum = tmpMin;
        if (complex)
        {
            maximumReal = tmpMaxReal;
            maximumImaginary = tmpMaxImag;
            minimumReal = tmpMinReal;
            minimumImaginary = tmpMinImag;
        }
        foundMinMax = YES;
    }
}


- (double) maximum
{
    if (!complex)
        return maximum;
    else
    {
        switch (float_representation)
        {
            case MAGNITUDE:
                return maximum;
            case REAL:
                return maximumReal;
            case IMAGINARY:
                return maximumImaginary;
            default:
                return maximum;
        }
    }
}


- (double) minimum
{
    if (!complex)
        return minimum;
    else
    {
        switch (float_representation)
        {
            case MAGNITUDE:
                return minimum;
            case REAL:
                return minimumReal;
            case IMAGINARY:
                return minimumImaginary;
            default:
                return minimum;
        }
    }
}


- (double) realMinimum { return complex ? minimumReal : minimum; }
- (double) realMaximum { return complex ? maximumReal : maximum; }
- (double) imaginaryMinimum { return complex ? minimumImaginary : minimum; }
- (double) imaginaryMaximum { return complex ? maximumImaginary: maximum; }


- (void) setValues:(NSArray*)newValues
            forSet:(int)setIndex
{
    if (setIndex < [self numberOfSets])
        [values replaceObjectAtIndex:setIndex
                          withObject:newValues];
    else
        [values addObject:newValues];
}


- (void) addValue:(double)value
            toSet:(int)setIndex
{
    if (setIndex < [values count])
        [[values objectAtIndex:setIndex] addObject:[NSNumber numberWithDouble:value]];
    else
    {
        NSMutableArray* newSet = [NSMutableArray arrayWithCapacity:1];
        [newSet addObject:[NSNumber numberWithDouble:value]];
        [values addObject:newSet];
    }
}


- (void) addComplexValue:(MI_ComplexNumber*)value
                   toSet:(int)setIndex
{
    complex = YES;
    if (setIndex < [values count])
        [[values objectAtIndex:setIndex] addObject:value];
    else
    {
        NSMutableArray* newSet = [NSMutableArray arrayWithCapacity:1];
        [newSet addObject:value];
        [values addObject:newSet];
    }
}



- (double) valueAtIndex:(int)valueIndex
                 forSet:(int)setIndex
{
/*    if ((setIndex < 0) || (setIndex >= [values count]))
        [[NSException exceptionWithName:@"MISUGARIndexException"
                                 reason:@"Invalid index"
                               userInfo:nil] raise];
*/
    if (!complex)
        return [[[values objectAtIndex:setIndex] objectAtIndex:valueIndex] doubleValue];
    else
    {
        if (float_representation == REAL)
            return [[[values objectAtIndex:setIndex] objectAtIndex:valueIndex] real];
        else if (float_representation == IMAGINARY)
            return [[[values objectAtIndex:setIndex] objectAtIndex:valueIndex] imaginary];
        else
            return [[[values objectAtIndex:setIndex] objectAtIndex:valueIndex] magnitude];
    }
}


- (MI_ComplexNumber*) complexValueAtIndex:(int)numberIndex
                                   forSet:(int)setIndex
{
/*    if ((setIndex < 0) || (setIndex >= [values count]))
        [[NSException exceptionWithName:@"MISUGARIndexException"
                                 reason:@"Invalid index"
                               userInfo:nil] raise];
*/
    if (!complex)
        return nil;
    else
        return [[values objectAtIndex:setIndex] objectAtIndex:numberIndex];    
}



- (NSArray*) valuesOfSet:(int)setIndex;
{
    if ((setIndex < 0) || (setIndex >= [values count]))
        [[NSException exceptionWithName:@"MISUGARIndexException"
                                reason:@"Invalid index"
                              userInfo:nil]
        raise];

    return [values objectAtIndex:setIndex];
}


- (BOOL) isComplex { return complex; }


- (enum floatRepresentation) floatRepresentation
{
    return float_representation;
}


- (void) setFloatRepresentation:(enum floatRepresentation)floatRep
{
    float_representation = floatRep;
}


- (void) dealloc
{
    [name release];
    [values release];
    [super dealloc];
}
    
@end
