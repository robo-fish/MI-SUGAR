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
#import "MI_CircuitElementDeviceModel.h"

#define MI_CIRCUIT_DOCUMENT_MODEL_VERSION 3

// version 3 -> MI_SUGAR 0.5.6,  introduction of schematic variants
// version 2 -> MI-SUGAR 0.5.3,  introduction of circuit name and namespace
// version 1 -> MI-SUGAR 0.5.2


@interface CircuitDocumentModel : NSObject <NSCoding>

@property (nonatomic) NSString* source; // the netlist
- (NSString*) gnucapFilteredSource;                         // returns the source after filtering certain Gnucap-specific parsing pitfalls
- (NSString*) spiceFilteredSource;                          // removes PLOT commands from the source
@property NSString* rawOutput;
@property NSString* output;

@property NSString* circuitTitle;
@property NSString* circuitName;
@property NSString* circuitNamespace; // Used to differentiate circuits with identical names. The default namespace is an empty string. Since version 0.5.3
- (NSString*) fullyQualifiedCircuitName;                    // convenience method

@property (nonatomic) MI_CircuitSchematic* schematic;
@property NSString* comment; // User comments. Since version 0.5.3
@property NSString* revision; // A short string for use in versioning. Usually a number. Since version 0.5.3
@property float schematicScale; // stores the drawing scale of the schematic. Since version 0.5.4
@property NSPoint schematicViewportOffset; // stores the location of the origin of the viewport coordinate system relative to the schematic coordinate system. Since version 0.5.5
@property int activeSchematicVariant; // index of the currently used schematic variant

@property (nonatomic, readonly) NSArray<NSString*>* analyses; // The circuit analysis commands. In the order they were issued.

// Convenience method which returns the list of used, non-default device models.
// For internal use when saving to file.
@property (nonatomic, readonly) NSArray<MI_CircuitElementDeviceModel*>* circuitDeviceModels;

@end
