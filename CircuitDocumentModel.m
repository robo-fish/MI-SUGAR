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

@implementation CircuitDocumentModel

- (id) init
{
    if (self = [super init])
    {
        MI_version = MI_CIRCUIT_DOCUMENT_MODEL_VERSION;
        source = [[NSMutableString alloc] initWithCapacity:200];
        rawOutput = nil;
        output = nil;
        title = nil;
        circuitName = @"";
        circuitNamespace = @"";
        schematicScale = 1.0f;
        schematicViewportOffset = NSMakePoint(0, 0);
        analyses = [[NSMutableArray alloc] initWithCapacity:2];
        comment = [[NSMutableString alloc] initWithCapacity:25];
        revision = [[NSMutableString alloc] initWithCapacity:4];
        
        activeSchematicVariant = 0;
        schematicVariants = [[NSMutableArray alloc] initWithCapacity:4];
        // add 4 empty schematics
        [schematicVariants addObject:[[[MI_CircuitSchematic alloc] init] autorelease]];
        [schematicVariants addObject:[[[MI_CircuitSchematic alloc] init] autorelease]];
        [schematicVariants addObject:[[[MI_CircuitSchematic alloc] init] autorelease]];
        [schematicVariants addObject:[[[MI_CircuitSchematic alloc] init] autorelease]];
    }
    return self;
}


- (void) setSource:(NSString*)newSource
{
    unsigned lineStart = 0, nextLineStart, lineEnd;
    int limit = [newSource length];
    NSString *line, *uppercaseLine;
    BOOL gotTitle = NO;
    int tranCount = 0,
        acCount = 0,
        opCount = 0,
        tfCount = 0,
        dcCount = 0,
        distoCount = 0,
        noiseCount = 0;

    [source setString:newSource];
    [analyses removeAllObjects];
    // Scan line by line, extract commands
    while (lineStart < limit)
    {
           [source getLineStart:&lineStart
                            end:&nextLineStart
                    contentsEnd:&lineEnd
                       forRange:NSMakeRange(lineStart, 1)];
        line = [source substringWithRange:NSMakeRange(lineStart, lineEnd - lineStart)];
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
            [analyses addObject:
                (tranCount ? [@"Transient" stringByAppendingFormat:@" %d", tranCount + 1] : @"Transient")];
            tranCount++;
        }
        else if ([uppercaseLine hasPrefix:@".AC "] || [uppercaseLine isEqualToString:@".AC"])
        {
            [analyses addObject:
                (acCount ? [@"AC" stringByAppendingFormat:@" %d", acCount + 1] : @"AC")];
            acCount++;
        }
        else if ( [uppercaseLine isEqualToString:@".OP"] || [uppercaseLine hasPrefix:@".OP "])
        {
            [analyses addObject:
                (opCount ? [@"Operating Point" stringByAppendingFormat:@" %d", opCount + 1] : @"Operating Point")];
            opCount++;
        }
        else if ( [uppercaseLine hasPrefix:@".TF "] )
        {
            [analyses addObject:
                (tfCount ? [@"Small-Signal" stringByAppendingFormat:@" %d", tfCount + 1] : @"Small-Signal")];
            tfCount++;
        }
        else if ( [uppercaseLine hasPrefix:@".DC "] )
        {
            [analyses addObject:
                (dcCount ? [@"DC" stringByAppendingFormat:@" %d", dcCount + 1] : @"DC")];
            dcCount++;
        }
        else if ( [uppercaseLine hasPrefix:@".DISTO "] )
        {
            [analyses addObject:
                (distoCount ? [@"Distortion" stringByAppendingFormat:@" %d", distoCount + 1] : @"Distortion")];
            distoCount++;
        }
        else if ( [uppercaseLine hasPrefix:@".NOISE "] )
        {
            [analyses addObject:
                (noiseCount ? [@"Noise" stringByAppendingFormat:@" %d", noiseCount + 1] : @"Noise")];
            noiseCount++;
        }
    }
}


- (NSString*) source
{
    return [NSString stringWithString:source];
}


- (NSString*) gnucapFilteredSource
{
    // Look for commands or syntax which cause clutter or produce pitfalls for the postprocessor's parser
    unsigned lineStart = 0, nextLineStart, lineEnd;
    NSString* filteredSource = @"";
    NSString* line;
    BOOL firstLine = YES;
    unsigned limit = [source length];
    // Scan line by line
    while (lineStart < limit)
    {
        [source getLineStart:&lineStart
                         end:&nextLineStart
                 contentsEnd:&lineEnd
                    forRange:NSMakeRange(lineStart, 1)];
        line = [source substringWithRange:NSMakeRange(lineStart, nextLineStart - lineStart)];
        if (firstLine)
        {
            while ([line hasPrefix:@"#"])
                line = [line substringFromIndex:1];
            filteredSource = [filteredSource stringByAppendingString:line];
            firstLine = NO;
        }
        else if (![[line uppercaseString] hasPrefix:@".LIST"] &&
                 ![[line uppercaseString] hasPrefix:@".PLOT"] &&
                 ![[line uppercaseString] hasPrefix:@"*"] ||
                 [[line uppercaseString] hasPrefix:@"*>"])
            filteredSource = [filteredSource stringByAppendingString:line];
        lineStart = nextLineStart;
    }
    return filteredSource;
}


- (NSString*) spiceFilteredSource
{
    unsigned lineStart = 0, nextLineStart = 0, lineEnd = 0;
    NSString* filteredSource = @"";
    NSString* line;
    unsigned limit = [source length];
    BOOL firstLine = YES;
    // Filtering the .PLOT commands from the SPICE input
    while (nextLineStart < limit)
    {
        [source getLineStart:&lineStart
                         end:&nextLineStart
                 contentsEnd:&lineEnd
                    forRange:NSMakeRange(nextLineStart, 1)];
        line = [source substringWithRange:NSMakeRange(lineStart, nextLineStart - lineStart)];
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


- (void) setOutput:(NSString*)newOutput
{
    [newOutput retain];
    [output release];
    output = newOutput;
}


- (NSString*) output
{
    return output;
}


- (void) setRawOutput:(NSString*)newRawOutput
{
    [newRawOutput retain];
    [rawOutput release];
    rawOutput = newRawOutput;
}


- (NSString*) rawOutput
{
    return rawOutput;
}


- (NSString*) circuitTitle
{
    return title;
}


- (void) setCircuitTitle:(NSString*)newTitle
{
    [newTitle retain];
    [title release];
    title = newTitle;
}


- (NSString*) circuitName
{
    return [NSString stringWithString:circuitName];
}


- (void) setCircuitName:(NSString*)newName
{
    [newName retain];
    [circuitName release];
    circuitName = newName;
}


- (NSString*) circuitNamespace
{
    return [NSString stringWithString:circuitNamespace];
}


- (void) setCircuitNamespace:(NSString*)newNamespace
{
    [newNamespace retain];
    [circuitNamespace release];
    circuitNamespace = newNamespace;
}


- (NSString*) fullyQualifiedCircuitName;
{
    if (circuitNamespace && [circuitNamespace length])
        return [NSString stringWithFormat:@"%@.%@", circuitNamespace, circuitName];
    else
        return [NSString stringWithString:circuitName];
}


- (void) setSchematic:(MI_CircuitSchematic*)newSchematic
{
    if (newSchematic != nil)
        [schematicVariants replaceObjectAtIndex:activeSchematicVariant
                                     withObject:newSchematic];
}


- (MI_CircuitSchematic*) schematic
{
    return [schematicVariants objectAtIndex:activeSchematicVariant];
}


- (NSArray*) analyses
{
    return analyses;
}


- (NSArray*) circuitDeviceModels
{
    NSEnumerator* schematicEnum = [schematicVariants objectEnumerator];
    MI_Schematic* currentSchematic;
    NSEnumerator* modelEnum;
    NSEnumerator* elementEnum;
    MI_SchematicElement* currentElement;
    MI_CircuitElementDeviceModel *currentModel, *currentModel2;
    NSString* currentModelName;
    NSMutableArray* circuitModels = [NSMutableArray arrayWithCapacity:2];
    BOOL alreadyAdded;
    while (currentSchematic = [schematicEnum nextObject])
    {
        elementEnum = [currentSchematic elementEnumerator];
        // For all elements of the circuit do...
        while (currentElement = [elementEnum nextObject])
        {
            if (![currentElement isKindOfClass:[MI_CircuitElement class]])
                continue;
            // Does the current element have a "Model" parameter with non-default value?
            currentModelName = [[(MI_CircuitElement*)currentElement parameters] objectForKey:@"Model"];
            if (currentModelName != nil && ![currentModelName hasPrefix:@"Default"])
            {
                // Find the corresponding model object from the model repository
                currentModel = [[MI_DeviceModelManager sharedManager] modelForName:currentModelName];
                if (currentModel != nil)
                {
                    // Now check if the model object is already in our list
                    // We can re-use the variable modelEnum here
                    alreadyAdded = NO;
                    modelEnum = [circuitModels objectEnumerator];
                    while (currentModel2 = [modelEnum nextObject])
                    {
                        if ([[currentModel2 modelName] isEqualToString:[currentModel modelName]])
                        {
                            alreadyAdded = YES;
                            break;
                        }
                    }
                    if (!alreadyAdded)
                        [circuitModels addObject:currentModel];
                }
            }
        } // end iterate over elements
    } // end iterate over schematics
    return [NSArray arrayWithArray:circuitModels];
}


- (NSString*) comment
{
    return [NSString stringWithString:comment];
}


- (void) setComment:(NSString*)newComment
{
    if (newComment != nil)
        [comment setString:newComment];
}


- (NSString*) revision
{
    return [NSString stringWithString:revision];
}

- (void) setRevision:(NSString*)rev
{
    if (rev != nil)
        [revision setString:rev];
}

- (float) schematicScale
{
    return schematicScale;
}

- (void) setSchematicScale:(float)newScale
{
    schematicScale = newScale;
}

- (NSPoint) schematicViewportOffset
{
    return schematicViewportOffset;
}

- (void) setSchematicViewportOffset:(NSPoint)newOffset
{
    schematicViewportOffset = newOffset;
}

- (int) activeSchematicVariant
{
    return activeSchematicVariant;
}

- (void) setActiveSchematicVariant:(int)variantIndex
{
    activeSchematicVariant = variantIndex;
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
            activeSchematicVariant = 0;
            schematicVariants = [[NSMutableArray alloc] initWithCapacity:4];
            [schematicVariants addObject:[decoder decodeObjectForKey:@"Schematic"]];
            // add three empty schematics
            [schematicVariants addObject:[[[MI_CircuitSchematic alloc] init] autorelease]];
            [schematicVariants addObject:[[[MI_CircuitSchematic alloc] init] autorelease]];
            [schematicVariants addObject:[[[MI_CircuitSchematic alloc] init] autorelease]];
        }
        else
        {
            activeSchematicVariant = [decoder decodeIntForKey:@"ActiveSchematicVariant"];
            schematicVariants = [[decoder decodeObjectForKey:@"SchematicVariants"] retain];
        }
        schematic = nil; // legacy variable
        source = [[decoder decodeObjectForKey:@"Source"] retain];
        analyses = [[decoder decodeObjectForKey:@"Analyses"] retain];
        title = [[decoder decodeObjectForKey:@"Title"] retain];
        if (title == nil)
            title = [@"" retain];
        circuitName = [[decoder decodeObjectForKey:@"CircuitName"] retain]; // since 0.5.3
        if (circuitName == nil)
            circuitName = [@"" retain];
        circuitNamespace = [[decoder decodeObjectForKey:@"CircuitNamespace"] retain]; // since 0.5.3
        if (circuitNamespace == nil)
            circuitNamespace = [@"" retain];
        comment = [[decoder decodeObjectForKey:@"Comment"] retain];
        if (comment == nil)
            comment = [[NSMutableString alloc] initWithCapacity:25];
        revision = [[decoder decodeObjectForKey:@"Revision"] retain];
        if (revision == nil)
            revision = [[NSMutableString alloc] initWithCapacity:4];
        schematicScale = [decoder decodeFloatForKey:@"SchematicScale"];
        schematicViewportOffset = [decoder decodePointForKey:@"SchematicViewportOffset"];
        // Finally, set the version of this new document model
        MI_version = MI_CIRCUIT_DOCUMENT_MODEL_VERSION;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeInt:MI_version
                   forKey:@"Version"];
    [encoder encodeInt:activeSchematicVariant
                forKey:@"ActiveSchematicVariant"];
    [encoder encodeObject:schematicVariants
                   forKey:@"SchematicVariants"];
    [encoder encodeObject:source
                   forKey:@"Source"];
    [encoder encodeObject:analyses
                   forKey:@"Analyses"];
    [encoder encodeObject:title
                   forKey:@"Title"];
    [encoder encodeObject:circuitName
                   forKey:@"CircuitName"];
    [encoder encodeObject:circuitNamespace
                   forKey:@"CircuitNamespace"];
    [encoder encodeObject:comment
                   forKey:@"Comment"];
    [encoder encodeObject:revision
                forKey:@"Revision"];
    [encoder encodeFloat:schematicScale
                  forKey:@"SchematicScale"];
    [encoder encodePoint:schematicViewportOffset
                  forKey:@"SchematicViewportOffset"];
}

/******************************************************************/

- (void) dealloc
{
    [schematicVariants release];
    [source release];
    [rawOutput release];
    [output release];
    [title release];
    [analyses release];
    [circuitName release];
    [circuitNamespace release];
    [comment release];
    [revision release];
    [super dealloc];
}

@end
