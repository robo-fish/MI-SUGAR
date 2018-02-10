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
#import "ResultsTable.h"

@implementation ResultsTable

- (id) init
{
    if (self = [super init])
    {
        variables = [[NSMutableArray arrayWithCapacity:1] retain];
        name = nil;
        title = nil;
    }
    return self;
}


- (AnalysisVariable*) variableAtIndex:(int)index
{
    //if (index > -1 && index < [variables count])
        return [variables objectAtIndex:index];
    //else
    //    return nil;
}


- (void) addVariable:(AnalysisVariable*)var
{
    [variables addObject:var];
}


- (void) setName:(NSString*)plotName
{
    [plotName retain];
    [name release];
    name = plotName;
}


- (NSString*) name
{
    return name;
}


- (void) setTitle:(NSString*)circuitTitle
{
    [circuitTitle retain];
    [title release];
    title = circuitTitle;
}


- (NSString*) title
{
    return title;
}

/*
- (int) numberOfPoints
{
    return [[[variables objectAtIndex:0] values] count];
}
*/

- (NSUInteger) numberOfVariables
{
    return [variables count];
}

/*
- (BOOL) needsSorting
{
    int i;
    BOOL unsorted = NO;
    NSArray* vals = [[variables objectAtIndex:0] values];
    int abscissaLength = [vals count];
    for (i = 1; i < abscissaLength; i++)
    {
        if ([[vals objectAtIndex:i] doubleValue] <
            [[vals objectAtIndex:(i - 1)] doubleValue])
        {
            unsorted = YES;
            break;
        }
    }
    return unsorted;
}


- (void) sort
{
    int i, j, arrayLength;
    int* indices;
    NSMutableArray* vals;
    double currentValue;
    
    if ([self numberOfPoints] <= 1) return;

    arrayLength = [[[variables objectAtIndex:0] values] count];
    // Construct an array of with the values to be sorted
    vals = [[NSMutableArray arrayWithCapacity:0] retain];
    [vals setArray:[[variables objectAtIndex:0] values]];
    // Construct an array that will keep track of the indices    
    indices = (int*) malloc(arrayLength * sizeof(int));
    for (i = 0; i < arrayLength; i++)
        indices[i] = i;

    // Sort using "insertion sort"
    for (i = 1; i < arrayLength; i++)
    {
        currentValue = [[vals objectAtIndex:i] doubleValue];
        j = i;
        while ([[vals objectAtIndex:(j - 1)] doubleValue] > currentValue)
        {
            indices[j] = indices[j - 1];
            [vals replaceObjectAtIndex:j
                            withObject:[vals objectAtIndex:(j - 1)]];
            j--;
            if (j <= 0) break;
        }
        indices[j] = i;
        [vals replaceObjectAtIndex:j
                        withObject:[NSNumber numberWithDouble:currentValue]];
    }
    [[variables objectAtIndex:0] setValues:vals];
    [vals release];

    // Now apply the sorting to the other variables by using the indices array
    for (i = 1; i < [variables count]; i++)
    {
        NSArray* valuesArray = [[variables objectAtIndex:i] values];
        int length = [valuesArray count];
        NSMutableArray* tmpArray = [[NSMutableArray arrayWithCapacity:length] retain];
        for (j = 0; j < length; j++)
            [tmpArray addObject:[valuesArray objectAtIndex:indices[j]]];
        [[variables objectAtIndex:i] setValues:tmpArray];        
        [tmpArray release];
    }
    
    free(indices);
}
*/

- (void) dealloc
{
    [variables release];
    [name release];
    [title release];
    [super dealloc];
}
@end
