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
#import "MI_Shape.h"

@interface MI_SubcircuitDocumentModel : CircuitDocumentModel <NSCoding>
{
    // Maps external port names to node names in the schematic.
    // If the port is not bound to a node the node name is an
    // empty string (length = 0). In older versions only DIP shaped
    // subcircuits were considered and the mapping was from pin
    // numbers (NSNumber objects) to node names. Hence the naming.
    NSDictionary* pinToNodeNameMap;

    // Set of names of other subcircuits used in this subcircuit.
    // Used in conversion to netlist.
    NSMutableSet* subcircuitsUsed;

    // Mapping of used device models to the model type name
    // Used in conversion to netlist.
    NSMutableDictionary* deviceModelsUsed;

    // the shape of the subcircuit
    MI_Shape* shape;
}
// Initializes the subcircuit model based on a plain circuit model
// and mapping info for the pins. The pinMap should map external
// port names to the node names within the subcircuit to which they
// have been assigned.
- (id) initWithCircuitDocumentModel:(CircuitDocumentModel*)model
                             pinMap:(NSDictionary*)pinMap;


- (int) numberOfPins;

// returns the name of the node element in the schematic
// which is connected to the external port given by name.
- (NSString*) nodeNameForPin:(NSString*)portName;

// autoreleased copy of the pin map
- (NSDictionary*) pinMap;

- (NSSet*) subcircuitsUsed;

- (void) setUsedSubcircuits:(NSSet*)newUsedSubcircuits;

- (NSDictionary*) deviceModelsUsed;

- (void) setUsedDeviceModels:(NSDictionary*)newUsedDeviceModels;

- (MI_Shape*) shape;

- (void) setShape:(MI_Shape*)newShape;

@end
