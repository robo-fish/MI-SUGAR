/***************************************************************************
*
*   This file is part of MI-SUGAR.
*
*   Copyright 2004-2011 Berk Ozer (berk@kulfx.com)
*
****************************************************************************/
#import "SpiceASCIIRawOutputReader.h"
#import "ResultsTable.h"
#import "AnalysisVariable.h"

@implementation SpiceASCIIRawOutputReader

+ (NSArray*) readFromFile:(NSString*)filePath
{
  NSError* fileError = nil;
  NSString* fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSASCIIStringEncoding error:&fileError];
  if ( fileContents == nil )
  {
    if ( fileError != nil )
    {
      NSLog(@"MI-SUGAR: Error while trying to parse SPICE output. %@", [fileError localizedDescription]);
    }
    return [NSArray array];
  }
  return [SpiceASCIIRawOutputReader readFromString:fileContents];
}


+ (NSArray*) readFromString:(NSString*)input
{
  NSUInteger lineStart, nextLineStart, lineEnd;
  NSString* nextLine = nil;
  NSString* plotName = nil;
  NSString* circuitName = nil;
  int numVars = 0, numPoints = 0;
  NSArray* variables = nil;
  ResultsTable* table = nil;
  NSMutableArray* resultsTables = [NSMutableArray arrayWithCapacity:1];
  lineStart = 0;
  // Scanning the string line by line
  while (lineStart < ([input length] - 1))
  {
    [input getLineStart:&lineStart end:&nextLineStart contentsEnd:&lineEnd forRange:NSMakeRange(lineStart, 1)];
    nextLine = [input substringWithRange:NSMakeRange(lineStart, lineEnd - lineStart)];
    lineStart = nextLineStart;

    if ([nextLine hasPrefix:@"Title: "])
    {
      circuitName = [nextLine substringFromIndex:7];
      table = [[ResultsTable alloc] init];
      [table setTitle:circuitName];
    }
    if ([nextLine hasPrefix:@"Plotname: "])
    {
      plotName = [nextLine substringFromIndex:10];
      [table setName:plotName];
    }
    else if ([nextLine hasPrefix:@"No. Variables: "])
    {
      numVars = [[nextLine substringFromIndex:15] intValue];
      variables = nil;
    }
    else if ([nextLine hasPrefix:@"No. Points: "])
    {
      numPoints = [[nextLine substringFromIndex:12] intValue];
    }
    else if ([nextLine isEqualToString:@"Variables:"])
    {
      for (int j = 0; j < numVars; j++)
      {
        [input getLineStart:&lineStart
                        end:&nextLineStart
                contentsEnd:&lineEnd
                   forRange:NSMakeRange(lineStart, 1)];
        nextLine = [input substringWithRange:NSMakeRange(lineStart, lineEnd - lineStart)];
        lineStart = nextLineStart;
        NSArray* variableTypeData = [nextLine componentsSeparatedByString:@"\t"];
        [table addVariable: [[AnalysisVariable alloc] initWithName:[variableTypeData objectAtIndex:2]]];
      }
    }
    else if ([nextLine isEqualToString:@"Values:"])
    {
      double value;
      double real;
      double imaginary;
      double firstSweepValue = 0.0; // used to detect the start of a new set
      int set = 0;
      NSString* valueCandidate;

      for (int n = 0; n < numPoints; n++)
      {
        for (int m = 0; m < numVars; m++)
        {
          [input getLineStart:&lineStart
                          end:&nextLineStart
                  contentsEnd:&lineEnd
                     forRange:NSMakeRange(lineStart, 1)];
          nextLine = [input substringWithRange:NSMakeRange(lineStart, lineEnd - lineStart)];
          lineStart = nextLineStart;
          // for m == 0 the line starts with the index number of the point
          if (m == 0)
          {
            // Parse the value of the sweep variable
            NSArray* comps = [nextLine componentsSeparatedByString:@"\t"];
            valueCandidate = [comps lastObject];
            if ([valueCandidate rangeOfString:@","].location == NSNotFound)
            {
              value = [valueCandidate doubleValue];
            }
            else
            {
                // Sweep variable values are not allowed to be complex
                value = [[valueCandidate substringToIndex:[valueCandidate rangeOfString:@","].location] doubleValue];
            }
            // Checking if a new set has started
            if (n == 0)
            {
              firstSweepValue = value;
              [[table variableAtIndex:0] addValue:value toSet:set];
            }
            else
            {
              [[table variableAtIndex:0] addValue:value toSet:((value == firstSweepValue) ? ++set : set)];
            }
          }
          else
          {
            valueCandidate = [nextLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSUInteger const separatorLocation = [valueCandidate rangeOfString:@","].location;
            if (separatorLocation == NSNotFound)
            {
              value = [valueCandidate doubleValue];
              [[table variableAtIndex:m] addValue:value toSet:set];
            }
            else // complex number
            {
              real = [[valueCandidate substringToIndex:separatorLocation] doubleValue];
              imaginary = [[valueCandidate substringFromIndex:(separatorLocation + 1)] doubleValue];
              [[table variableAtIndex:m] addComplexValue:
                  [[MI_ComplexNumber alloc] initWithReal:real imaginary:imaginary] toSet:set];
            }
          }
        }
      }
      /* Sort the table
      if ([table needsSorting])
          [table sort]; */
      // Add the constructed table to the array of tables
      [resultsTables addObject:table];
    }
  }
  return resultsTables;
}

@end
