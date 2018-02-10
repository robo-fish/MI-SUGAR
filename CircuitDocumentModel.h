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
#import <Cocoa/Cocoa.h>
#import "MI_CircuitSchematic.h"

#define MI_CIRCUIT_DOCUMENT_MODEL_VERSION 3

// version 3 -> MI_SUGAR 0.5.6,  introduction of schematic variants
// version 2 -> MI-SUGAR 0.5.3,  introduction of circuit name and namespace
// version 1 -> MI-SUGAR 0.5.2


@interface CircuitDocumentModel : NSObject <NSCoding>
{
    int MI_version;
    NSMutableString* source;    // = netlist
    NSString* output;
    NSString* rawOutput;
    NSMutableArray* analyses;   // stores all lines with analysis commands in an array
    NSString* title;            // legacy variable - used in pure netlist editing mode
    NSString* circuitName;      // since 0.5.3
    NSMutableString* comment;   // user comments - since 0.5.3
    MI_CircuitSchematic* schematic;
    float schematicScale;       // stores the drawing scale of the schematic - since 0.5.4
    NSPoint schematicViewportOffset; // stores the location of the origin of the viewport coordinate system relative to the schematic coordinate system - since 0.5.5
    
    NSMutableArray* schematicVariants; // array which holds all schematic variants since 0.5.6
    int activeSchematicVariant; // index of the currently used schematic variant

    // The namespace used to differentiate circuits with identical names.
    // The default namespace is an empty string.
    NSString* circuitNamespace; // since 0.5.3
    
    // A short string for use in versioning - normally a number - since 0.5.3
    NSMutableString* revision;
}
- (void) setSource:(NSString*)newSource;
- (NSString*) source;
- (NSString*) gnucapFilteredSource;                         // returns the source after filtering certain Gnucap-specific parsing pitfalls
- (NSString*) spiceFilteredSource;                          // removes PLOT commands from the source
- (void) setRawOutput:(NSString*)newRawOutput;
- (NSString*) rawOutput;
- (void) setOutput:(NSString*)newOutput;
- (NSString*) output;
- (NSString*) circuitTitle;                                 // returns the title of the circuit
- (void) setCircuitTitle:(NSString*)newTitle;               // forget this, you should use setCircuitName:
- (NSString*) circuitName;
- (void) setCircuitName:(NSString*)newName;
- (void) setCircuitNamespace:(NSString*)newNamespace;
- (NSString*) circuitNamespace;
- (NSString*) fullyQualifiedCircuitName;                    // convenience method
- (void) setSchematic:(MI_CircuitSchematic*)newSchematic;
- (MI_CircuitSchematic*) schematic;
- (NSString*) comment;
- (void) setComment:(NSString*)newComment;
- (NSString*) revision;
- (void) setRevision:(NSString*)rev;
- (float) schematicScale;
- (void) setSchematicScale:(float)newScale;
- (NSPoint) schematicViewportOffset;
- (void) setSchematicViewportOffset:(NSPoint)newOffset;
- (int) activeSchematicVariant;
- (void) setActiveSchematicVariant:(int)variantIndex;


// Returns an array of strings, which contain the analysis
// commands in the order they were issued.
- (NSArray*) analyses;

// Convenience method which returns the list of used, non-default device models.
// For internal use when saving to file.
- (NSArray*) circuitDeviceModels;

@end
