/***************************************************************************
*
*   Copyright 2004, 2005 Berk Ozer (berk@kulfx.com)
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
#import "GnucapASCIIOutputReader.h"
#import "ResultsTable.h"

inline double gnucap2double(NSString* number);


@implementation GnucapASCIIOutputReader

+ (NSArray*) readFromModel:(CircuitDocumentModel*)model;
{
    NSMutableArray* resultsTables = [[NSMutableArray alloc] initWithCapacity:1];
    NSMutableArray* values = [[NSMutableArray alloc] initWithCapacity:1];
    NSMutableArray* lines = [[NSMutableArray alloc] initWithCapacity:1];
    NSMutableArray* variableNames = [[NSMutableArray alloc] initWithCapacity:1];
    unsigned lineStart = 0, nextLineStart = 0, lineEnd = 0;
    NSString* thisLine = nil;
    int i, // index of current processed line
        numLines = 0, // number of lines of the output
        setCounter = 0; // current set of the value (for parametric variables)
    BOOL success = YES;
    ResultsTable* table = nil;
    double sweepStartValue = 0.0;
    BOOL gotSweepStart = NO;
    NSString* input = [model output];
    unsigned j;

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

    for (i = 0; ;)
    {
        while ( (i < numLines) && ![[lines objectAtIndex:i] hasPrefix:@"#"] )
            i++;
        if (i >= numLines)
            break;
        // Read the variable names
        [variableNames removeAllObjects];
        thisLine = [[lines objectAtIndex:i] substringFromIndex:1];
        if ([thisLine hasPrefix:@" "])
        {
            [variableNames addObject:@" "];
            thisLine = [thisLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
        for (; [thisLine length] > 0;)
        {
            j = [thisLine rangeOfString:@" "].location;
            if (j == NSNotFound)
            {
                [variableNames addObject:thisLine];
                break;
            }
            else
            {
                [variableNames addObject:[thisLine substringToIndex:j]];
                thisLine = [[thisLine substringFromIndex:(j+1)] stringByTrimmingCharactersInSet:
                    [NSCharacterSet whitespaceCharacterSet]];
            }
        }
        if ([variableNames count] == 0)
        {
            i++;
            continue;
        }
        // Construct a new results table
        table = [[ResultsTable alloc] init];
        [table setName:[[model analyses] objectAtIndex:[resultsTables count]]];
        [table setTitle:[model circuitTitle]];
        [resultsTables addObject:[table autorelease]];
        // Add the variables to the table
        for (j = 0; j < [variableNames count]; j++)
            [table addVariable:[[AnalysisVariable alloc] initWithName:[variableNames objectAtIndex:j]]];
        // Prepare to read the values
        setCounter = 0;
        gotSweepStart = NO;
        // Go on to read the variables
        for (i++; i < numLines; i++)
        {
            thisLine = [[lines objectAtIndex:i] stringByTrimmingCharactersInSet:
                [NSCharacterSet whitespaceCharacterSet]];
            if ([thisLine hasPrefix:@"#"])
                break;
            // Extract values
            [values removeAllObjects];
            for (; [thisLine length] > 0;)
            {
                j = [thisLine rangeOfString:@" "].location;
                if (j == NSNotFound)
                {
                    [values addObject:thisLine];
                    break;
                }
                else
                {
                    [values addObject:[thisLine substringToIndex:j]];
                    thisLine = [[thisLine substringFromIndex:(j+1)] stringByTrimmingCharactersInSet:
                        [NSCharacterSet whitespaceCharacterSet]];
                }
            }
            // Check if this line is a valid table entry.
            if ([((NSString*)[values objectAtIndex:0]) length] == 0)
                break;
            else if ([[[values objectAtIndex:0] stringByTrimmingCharactersInSet:
                [NSCharacterSet characterSetWithCharactersInString:@"0123456789."]] length] > 1)
                break;

            /* Handle sweep value to recognize the beginning of a new set
                (which occurs when the analysis is repeated for a given sweep parameter) */
            if (!gotSweepStart)
            {
                sweepStartValue = gnucap2double([values objectAtIndex:0]);
                gotSweepStart = YES;
            }
            else if (sweepStartValue == gnucap2double([values objectAtIndex:0]))
                setCounter++;
            
            for (j = 0; j < [values count]; j++)
                if (![[values objectAtIndex:j] isEqualToString:@"??"])
                    [[table variableAtIndex:j] addValue:gnucap2double([values objectAtIndex:j])
                                                  toSet:setCounter];
        }
    }

    [values release];
    [lines release];
    [variableNames release];
    if ( success && ([resultsTables count] > 0) )
        return [resultsTables autorelease];
    else
    {
        [resultsTables release];
        return nil;
    }    
}

@end


inline double gnucap2double(NSString* number)
{
    NSString* upperNumber = [number uppercaseString];
    if ([upperNumber hasSuffix:@".U"])
        return [[number substringToIndex:([number length] - 2)] doubleValue] * 1e-6;
    else if ([upperNumber hasSuffix:@"U"])  // micro
        return [[number substringToIndex:([number length] - 1)] doubleValue] * 1e-6;
    else if ([upperNumber hasSuffix:@".N"])  // nano
        return [[number substringToIndex:([number length] - 2)] doubleValue] * 1e-9;
    else if ([upperNumber hasSuffix:@"N"])  // nano
        return [[number substringToIndex:([number length] - 1)] doubleValue] * 1e-9;
    else if ([upperNumber hasSuffix:@".P"])  // pico
        return [[number substringToIndex:([number length] - 2)] doubleValue] * 1e-12;
    else if ([upperNumber hasSuffix:@"P"])  // pico
        return [[number substringToIndex:([number length] - 1)] doubleValue] * 1e-12;
    else if ([upperNumber hasSuffix:@".K"])  // kilo
        return [[number substringToIndex:([number length] - 2)] doubleValue] * 1e+3;
    else if ([upperNumber hasSuffix:@"K"])  // kilo
        return [[number substringToIndex:([number length] - 1)] doubleValue] * 1e+3;
    else if ([upperNumber hasSuffix:@".MEG"])  // mega
        return [[number substringToIndex:([number length] - 2)] doubleValue] * 1e+6;
    else if ([upperNumber hasSuffix:@"MEG"])  // mega
        return [[number substringToIndex:([number length] - 1)] doubleValue] * 1e+6;
    else if ([upperNumber hasSuffix:@".M"])  // milli
        return [[number substringToIndex:([number length] - 2)] doubleValue] * 1e-3;
    else if ([upperNumber hasSuffix:@"M"])  // milli
        return [[number substringToIndex:([number length] - 1)] doubleValue] * 1e-3;
    else if ([upperNumber hasSuffix:@".G"])  // giga
        return [[number substringToIndex:([number length] - 2)] doubleValue] * 1e+9;
    else if ([upperNumber hasSuffix:@"G"])  // giga
        return [[number substringToIndex:([number length] - 1)] doubleValue] * 1e+9;
    else if ([upperNumber hasSuffix:@".T"])  // terra
        return [[number substringToIndex:([number length] - 2)] doubleValue] * 1e+12;
    else if ([upperNumber hasSuffix:@"T"])  // terra
        return [[number substringToIndex:([number length] - 1)] doubleValue] * 1e+12;
    else
        return [number doubleValue];
};
