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
#import "SpiceASCIIOutputReader.h"
#import "ResultsTable.h"
#import "MI_ComplexNumber.h"

#define DASHES @"------------------"

@implementation SpiceASCIIOutputReader


// The output of the SPICE PRINT command produces text data in table form.
// The table for an analysis type starts with a line containing the name of the analysis.
// This line is followed by a line with dashes.
// Then comes the table header with the names of the columns.
// The first column is the "Index" column with the running index of the current data set.
// Then comes the names of the X-axis (abscissa) variable ->
//     "time" for transient analysis, "frequency" for AC analysis, "sweep" or "v-sweep" for DC analysis.
// The table header line is followed by a line of dashes.
// Then the data starts with index = 0.
// The table does not run uninterrupted until the end, though. For better orientation
//     SPICE inserts empty rows at about every 50th data set and repeats the table header
//     plus the following line of dashes before continuing.
+ (NSArray*) readFromModel:(CircuitDocumentModel*)model
{
    NSMutableArray* resultsTables = [[NSMutableArray alloc] initWithCapacity:1];
    NSMutableArray* lines = [[NSMutableArray alloc] initWithCapacity:1];
    NSMutableArray* variableNames = [[NSMutableArray alloc] initWithCapacity:1];
    NSMutableArray* values = [[NSMutableArray alloc] initWithCapacity:5];
    NSUInteger lineStart = 0, nextLineStart = 0, lineEnd = 0, numLines = 0;
    NSString* thisLine = nil;
    int i, // index of current processed line
        indexCounter = 0, // index of the sample point
        setCounter = 0; // current set of the value (for parametric variables)
    BOOL success = YES;
    BOOL analysisAlreadyExists = NO;
    BOOL sweepIsComplex = NO; // indicates whether the sweep variable is complex-valued
    ResultsTable* table = nil;
    NSString* circuitName = nil;
    int variableIndexOffset = 0;
    double sweepStartValue = 0.0;
    NSString* input = [model output];

    // put the lines into an array
    while (lineStart < [input length])
    {
        [input getLineStart:&lineStart
                        end:&nextLineStart
                contentsEnd:&lineEnd
                   forRange:NSMakeRange(lineStart, 1)];
        [lines addObject:[input substringWithRange:NSMakeRange(lineStart, lineEnd - lineStart)]];
        lineStart = nextLineStart;
    }
    numLines = [lines count];

    // Extract circuit name
    for (i = 0; i < numLines; i++)
        if ([[lines objectAtIndex:i] hasPrefix:@"Circuit: "])
        {
            circuitName = [[lines objectAtIndex:i] substringFromIndex:[@"Circuit: " length]];
            break;
        }
    if (i == numLines)
        success = NO;

    while (success)
    {
        // Find the (next) line with all dashes
        for (; i < numLines; i++)
            if ([[lines objectAtIndex:i] hasPrefix:DASHES])
                break;
        if (i >= numLines)
            break;

        if ([[lines objectAtIndex:(i-1)] hasPrefix:@"Index "] && table)
        {
            NSString* sweepValueString;
            double sweepValue; // the final value assigned to the sweep variable at the current sample point
            NSString *realPart; // the real part of the complex-values sweep variable
            int varIndex; // used to iterate over all sample values of the variables
            int k;

            [values removeAllObjects];
            if (indexCounter == 0)
            {
                // This is the first time we get a list of variable names
                // Constructing the AnalysisVariable objects...
                NSString* names;
                NSUInteger endIndex;
                // read the names of the variables
                names = [[[lines objectAtIndex:(i-1)] substringFromIndex:[@"Index " length]]
                    stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                for (;;)
                {
                  endIndex = [names rangeOfString:@" "].location;
                  if (endIndex == NSNotFound)
                  {
                    [variableNames addObject:[NSString stringWithString:names]];
                    break;
                  }
                  [variableNames addObject:[names substringToIndex:endIndex]];
                  names = [[names substringFromIndex:(endIndex + 1)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                }
                // Check if the results table already has some variables.
                variableIndexOffset = analysisAlreadyExists ? ([table numberOfVariables] - 1) : 0;
                // Add the variables to the results table. Skip the sweep variable if analysis already exists.
                for (endIndex = analysisAlreadyExists ? 1 : 0; endIndex < [variableNames count]; endIndex++)
                {
                    [table addVariable:[[AnalysisVariable alloc] initWithName:
                        [variableNames objectAtIndex:endIndex]]];
                }
                [variableNames removeAllObjects];
            }
            for(i++; i < numLines; i++) // Go on scanning the values
            {
                // Check if the end of this value block is reached
                if ([[[lines objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0)
                    break;

                // Put all table entries for the current sample point into one array.
                // Note that an entry may span multiple lines.
                [values removeAllObjects];
                thisLine = [lines objectAtIndex:i];
                while ( ([[thisLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] > 0) &&
                        (![thisLine isEqualToString:@"\f"]) && // Mac OS X 10.3 somehow inserts Form Feed ('\f') characters
                        (![thisLine hasPrefix:[NSString stringWithFormat:@"%d", indexCounter + 1]]) )
                {
                    [values addObjectsFromArray:[[thisLine stringByTrimmingCharactersInSet:
                        [NSCharacterSet whitespaceCharacterSet]] componentsSeparatedByString:@"\t"]];
                    thisLine = (NSString*) [lines objectAtIndex:++i];
                }
                i--;
                if (![values count])
                    break;
                // Add the sweep variable's value only if it wasn't added before.
                if (!analysisAlreadyExists)
                {
                    // If the sweep value is complex number, we take the real part only.
                    sweepValueString = (NSString*) [values objectAtIndex:1];
                sweepIsComplex = [sweepValueString hasSuffix:@","];
                    if (sweepIsComplex)
                    {
                      sweepValueString = [sweepValueString substringToIndex:([sweepValueString length] - 1)];
                    }
                    sweepValue = [sweepValueString doubleValue];
                    // Check if a new set has started
                    if (!indexCounter && !setCounter)
                        sweepStartValue = sweepValue;
                    else if (sweepStartValue == sweepValue)
                        setCounter++;
                    // Add the value of the sweep variable - must not be complex
                    [[table variableAtIndex:0] addValue:sweepValue
                                                  toSet:setCounter];
                }
                //
                for (varIndex = sweepIsComplex ? 3 : 2, k = 1; varIndex < [values count]; varIndex++, k++)
                {
                    if ([[values objectAtIndex:varIndex] hasSuffix:@","])
                    {
                        realPart = (NSString*) [values objectAtIndex:varIndex];
                        realPart = [realPart substringToIndex:([realPart length] - 1)];
                        [[table variableAtIndex:(variableIndexOffset + k)] addComplexValue:
                            [[MI_ComplexNumber alloc] initWithReal:[realPart doubleValue]
                                                         imaginary:[[values objectAtIndex:(varIndex+1)] doubleValue]]
                                                                                     toSet:setCounter];
                        varIndex++;
                    }
                    else
                        [[table variableAtIndex:(variableIndexOffset + k)]
                            addValue:[[values objectAtIndex:varIndex] doubleValue]
                               toSet:setCounter];
                }
                //fprintf(stderr, "%d ", indexCounter); 
                indexCounter++;
            }
        }
        else if ([[lines objectAtIndex:(i+1)] hasPrefix:@"Index "])
        {
            // Parse the previous line to extract the analysis type
            long t = 0;
            BOOL analysisNameExists = NO;

            if (i + 3 >= numLines) break; // corrupt SPICE output
            // Extract analysis name, getting rid of the date string
            /* Note: We cannot use the analysis names from the CircuitDocumentModel since SPICE output
                may contain separator lines within the list of values pertaining to the same analysis
                and we have to check that. */
            NSString* analysisName = [[lines objectAtIndex:(i-1)] stringByTrimmingCharactersInSet:
                [NSCharacterSet whitespaceCharacterSet]];
         /* analysisName = [analysisName substringToIndex:[analysisName rangeOfString:@"Analysis"].location]; */
            // Reset index count
            indexCounter = 0;
            // Reset the set count
            setCounter = 0;
            // Is this a new analysis type or do we merely add new variables?
            // Important: Search the tables in reverse order
            for (t = [resultsTables count] - 1; t >= 0; t--)
                if ([[[resultsTables objectAtIndex:t] name] hasPrefix:analysisName])
                {
                    analysisNameExists = YES;
                    table = (ResultsTable*) [resultsTables objectAtIndex:t];
                    break;
                }
            /* If this analysis type was used before is it the continuation of the
                previous output or is it a new analysis of the same kind?
                We have to check if the first index number of the values is zero. */
            analysisAlreadyExists = analysisNameExists /* && ![[lines objectAtIndex:(i+3)] hasPrefix:@"0"] */;
            
            if (!analysisAlreadyExists)
            {
                // Create a new ResultsTable if the analysis type is new
                table = [[ResultsTable alloc] init];
                if (analysisNameExists)
                    [table setName:[[[resultsTables objectAtIndex:t] name] stringByAppendingString:@"|"]];
                else
                    [table setName:analysisName];
                [table setTitle:(circuitName ? circuitName : @"")];
                [resultsTables addObject:table];
            }
            i++; // continue to next line
        }
        else
            i++; // continue to next line
    }
    
    if (success)
    {
      return resultsTables;
    }
    else
    {
      return nil;
    }
}

@end
