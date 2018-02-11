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
#import "CircuitDocumentModel.h"
#import "common.h"
#import "MI_CircuitElement.h"
#import "MI_DeviceModelManager.h"

static NSUInteger const kNumVariants = 4;

@interface CircuitDocumentModel ()
@end

@implementation CircuitDocumentModel
{
  int MI_version;
  NSString* _source;
  MI_CircuitSchematic* _schematic;
  NSMutableArray<MI_CircuitSchematic*>* _schematicVariants; // array which holds all schematic variants since 0.5.6
  NSMutableArray<NSString*>* _analyses;
}

- (instancetype) init
{
  if (self = [super init])
  {
    MI_version = MI_CIRCUIT_DOCUMENT_MODEL_VERSION;
    self.source = [[NSMutableString alloc] initWithCapacity:200];
    self.rawOutput = nil;
    self.output = nil;
    self.circuitTitle = nil;
    self.circuitName = @"";
    self.circuitNamespace = @"";
    self.schematicScale = 1.0f;
    self.schematicViewportOffset = NSMakePoint(0, 0);
    _analyses = [[NSMutableArray alloc] initWithCapacity:2];
    self.comment = [[NSMutableString alloc] initWithCapacity:25];
    self.revision = [[NSMutableString alloc] initWithCapacity:4];

    self.activeSchematicVariant = 0;
    _schematicVariants = [[NSMutableArray alloc] initWithCapacity:kNumVariants];
    for (NSUInteger counter = 0; counter < kNumVariants; counter++)
    {
      [_schematicVariants addObject:[MI_CircuitSchematic new]];
    }
  }
  return self;
}

- (NSString*) source
{
  return _source;
}

- (void) setSource:(NSString*)newSource
{
    NSUInteger lineStart = 0, nextLineStart, lineEnd;
    NSUInteger const limit = [newSource length];
    NSString *line, *uppercaseLine;
    BOOL gotTitle = NO;
    int tranCount = 0,
        acCount = 0,
        opCount = 0,
        tfCount = 0,
        dcCount = 0,
        distoCount = 0,
        noiseCount = 0;

    _source = newSource;
    [_analyses removeAllObjects];
    // Scan line by line, extract commands
    while (lineStart < limit)
    {
           [_source getLineStart:&lineStart
                            end:&nextLineStart
                    contentsEnd:&lineEnd
                       forRange:NSMakeRange(lineStart, 1)];
        line = [_source substringWithRange:NSMakeRange(lineStart, lineEnd - lineStart)];
        lineStart = nextLineStart;
        
        if (!gotTitle)
        {
            // Extract the title of the circuit
            [self setCircuitTitle:line];
            gotTitle = YES;
            continue;
        }

        // Check for analysis commands
        // In Gnucap, a ">" following a "*" turns the comment line into a normal line again
        if ([line hasPrefix:@"*>"])
            line = [line substringFromIndex:2];
        uppercaseLine = [[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] uppercaseString];
        if ( [uppercaseLine hasPrefix:@".TRAN "] || [uppercaseLine isEqualToString:@".TRAN"])
        {
            [_analyses addObject:
                (tranCount ? [@"Transient" stringByAppendingFormat:@" %d", tranCount + 1] : @"Transient")];
            tranCount++;
        }
        else if ([uppercaseLine hasPrefix:@".AC "] || [uppercaseLine isEqualToString:@".AC"])
        {
            [_analyses addObject:
                (acCount ? [@"AC" stringByAppendingFormat:@" %d", acCount + 1] : @"AC")];
            acCount++;
        }
        else if ( [uppercaseLine isEqualToString:@".OP"] || [uppercaseLine hasPrefix:@".OP "])
        {
            [_analyses addObject:
                (opCount ? [@"Operating Point" stringByAppendingFormat:@" %d", opCount + 1] : @"Operating Point")];
            opCount++;
        }
        else if ( [uppercaseLine hasPrefix:@".TF "] )
        {
            [_analyses addObject:
                (tfCount ? [@"Small-Signal" stringByAppendingFormat:@" %d", tfCount + 1] : @"Small-Signal")];
            tfCount++;
        }
        else if ( [uppercaseLine hasPrefix:@".DC "] )
        {
            [_analyses addObject:
                (dcCount ? [@"DC" stringByAppendingFormat:@" %d", dcCount + 1] : @"DC")];
            dcCount++;
        }
        else if ( [uppercaseLine hasPrefix:@".DISTO "] )
        {
            [_analyses addObject:
                (distoCount ? [@"Distortion" stringByAppendingFormat:@" %d", distoCount + 1] : @"Distortion")];
            distoCount++;
        }
        else if ( [uppercaseLine hasPrefix:@".NOISE "] )
        {
            [_analyses addObject:
                (noiseCount ? [@"Noise" stringByAppendingFormat:@" %d", noiseCount + 1] : @"Noise")];
            noiseCount++;
        }
    }
}

- (NSString*) gnucapFilteredSource
{
    // Look for commands or syntax which cause clutter or produce pitfalls for the postprocessor's parser
    NSUInteger lineStart = 0, nextLineStart, lineEnd;
    NSString* filteredSource = @"";
    NSString* line;
    BOOL firstLine = YES;
    NSUInteger const limit = self.source.length;
    // Scan line by line
    while (lineStart < limit)
    {
        [self.source getLineStart:&lineStart
                         end:&nextLineStart
                 contentsEnd:&lineEnd
                    forRange:NSMakeRange(lineStart, 1)];
        line = [self.source substringWithRange:NSMakeRange(lineStart, nextLineStart - lineStart)];
        if (firstLine)
        {
            while ([line hasPrefix:@"#"])
                line = [line substringFromIndex:1];
            filteredSource = [filteredSource stringByAppendingString:line];
            firstLine = NO;
        }
        else if (![[line uppercaseString] hasPrefix:@".LIST"] &&
                 ![[line uppercaseString] hasPrefix:@".PLOT"] &&
                 !([[line uppercaseString] hasPrefix:@"*"] || [[line uppercaseString] hasPrefix:@"*>"])
                 )
            filteredSource = [filteredSource stringByAppendingString:line];
        lineStart = nextLineStart;
    }
    return filteredSource;
}


- (NSString*) spiceFilteredSource
{
    NSUInteger lineStart = 0, nextLineStart = 0, lineEnd = 0;
    NSString* filteredSource = @"";
    NSString* line;
    NSUInteger const limit = self.source.length;
    BOOL firstLine = YES;
    // Filtering the .PLOT commands from the SPICE input
    while (nextLineStart < limit)
    {
        [self.source getLineStart:&lineStart
                         end:&nextLineStart
                 contentsEnd:&lineEnd
                    forRange:NSMakeRange(nextLineStart, 1)];
        line = [self.source substringWithRange:NSMakeRange(lineStart, nextLineStart - lineStart)];
        if (firstLine)
        {
            filteredSource = [filteredSource stringByAppendingString:line];
            firstLine = NO;
        }
        else if (![[line uppercaseString] hasPrefix:@".PLOT"] &&
            ![[line uppercaseString] hasPrefix:@"*"])
            filteredSource = [filteredSource stringByAppendingString:line];
        lineStart = nextLineStart;
    }
    return filteredSource;
}


- (NSString*) fullyQualifiedCircuitName;
{
    if (self.circuitNamespace && (self.circuitNamespace.length > 0))
        return [NSString stringWithFormat:@"%@.%@", self.circuitNamespace, self.circuitName];
    else
        return [self.circuitName copy];
}


- (void) setSchematic:(MI_CircuitSchematic*)newSchematic
{
  if (newSchematic != nil)
  {
    [_schematicVariants replaceObjectAtIndex:self.activeSchematicVariant withObject:newSchematic];
  }
}


- (MI_CircuitSchematic*) schematic
{
  return [_schematicVariants objectAtIndex:self.activeSchematicVariant];
}


- (NSArray<NSString*>*) analyses
{
  return _analyses;
}


- (NSArray<MI_CircuitElementDeviceModel*>*) circuitDeviceModels
{
  NSMutableArray<MI_CircuitElementDeviceModel*>* circuitModels = [NSMutableArray arrayWithCapacity:2];
  for (MI_Schematic* currentSchematic in _schematicVariants)
  {
    MI_SchematicElement* currentElement;
    NSEnumerator* elementEnum = [currentSchematic elementEnumerator];
    while (currentElement = [elementEnum nextObject])
    {
      if (![currentElement isKindOfClass:[MI_CircuitElement class]]) continue;

      NSString* currentModelName = [[(MI_CircuitElement*)currentElement parameters] objectForKey:@"Model"];
      if (currentModelName != nil && ![currentModelName hasPrefix:@"Default"])
      {
        MI_CircuitElementDeviceModel* currentModel = [[MI_DeviceModelManager sharedManager] modelForName:currentModelName];
        if (currentModel != nil)
        {
          BOOL alreadyAdded = NO;
          for (MI_CircuitElementDeviceModel* addedModel in circuitModels)
          {
            if ([addedModel.modelName isEqualToString:currentModel.modelName])
            {
              alreadyAdded = YES;
              break;
            }
          }
          if (!alreadyAdded)
          {
            [circuitModels addObject:currentModel];
          }
        }
      }
    } // end iterate over elements
  } // end iterate over schematics
  return [NSArray arrayWithArray:circuitModels];
}


/******************************************* Archiving Methods *******/

- (id)initWithCoder:(NSCoder *)decoder
{
  if (self = [super init])
  {
    MI_version = [decoder decodeIntForKey:@"Version"];
    // Depending on version the rest may be decoded differently
    if (MI_version < 3)
    {
      // for old files from before schematic variants were introduced
      self.activeSchematicVariant = 0;
      _schematicVariants = [[NSMutableArray alloc] initWithCapacity:kNumVariants];
      [_schematicVariants addObject:[decoder decodeObjectForKey:@"Schematic"]];
      for (NSUInteger i = 0; i < kNumVariants - 1; i++)
      {
        [_schematicVariants addObject:[MI_CircuitSchematic new]];
      }
    }
    else
    {
      self.activeSchematicVariant = [decoder decodeIntForKey:@"ActiveSchematicVariant"];
      _schematicVariants = [decoder decodeObjectForKey:@"SchematicVariants"];
    }
    self.schematic = nil; // legacy variable
    self.source = [decoder decodeObjectForKey:@"Source"];
    _analyses = [decoder decodeObjectForKey:@"Analyses"];
    self.circuitTitle = [decoder decodeObjectForKey:@"Title"];
    if (self.circuitTitle == nil) { self.circuitTitle = @""; }
    self.circuitName = [decoder decodeObjectForKey:@"CircuitName"]; // since version 0.5.3
    if (self.circuitName == nil) { self.circuitName = @""; }
    self.circuitNamespace = [decoder decodeObjectForKey:@"CircuitNamespace"]; // since version 0.5.3
    if (self.circuitNamespace == nil) { self.circuitNamespace = @""; }
    self.comment = [decoder decodeObjectForKey:@"Comment"];
    if (self.comment == nil) { self.comment = [[NSMutableString alloc] initWithCapacity:25]; }
    self.revision = [decoder decodeObjectForKey:@"Revision"];
    if (self.revision == nil) { self.revision = [[NSMutableString alloc] initWithCapacity:4]; }
    self.schematicScale = [decoder decodeFloatForKey:@"SchematicScale"];
    self.schematicViewportOffset = [decoder decodePointForKey:@"SchematicViewportOffset"];
    // Finally, set the version of this new document model
    MI_version = MI_CIRCUIT_DOCUMENT_MODEL_VERSION;
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeInt:MI_version forKey:@"Version"];
  [encoder encodeInt:self.activeSchematicVariant forKey:@"ActiveSchematicVariant"];
  [encoder encodeObject:_schematicVariants forKey:@"SchematicVariants"];
  [encoder encodeObject:self.source forKey:@"Source"];
  [encoder encodeObject:_analyses forKey:@"Analyses"];
  [encoder encodeObject:self.circuitTitle forKey:@"Title"];
  [encoder encodeObject:self.circuitName forKey:@"CircuitName"];
  [encoder encodeObject:self.circuitNamespace forKey:@"CircuitNamespace"];
  [encoder encodeObject:self.comment forKey:@"Comment"];
  [encoder encodeObject:self.revision forKey:@"Revision"];
  [encoder encodeFloat:self.schematicScale forKey:@"SchematicScale"];
  [encoder encodePoint:self.schematicViewportOffset forKey:@"SchematicViewportOffset"];
}


@end
