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
#import "MI_SchematicElement.h"
#import "MI_CircuitElementDeviceModel.h"

/* Class of schematics elements, which represent electrical circuit
elements. */
@interface MI_CircuitElement : MI_SchematicElement
    <NSCoding, NSCopying, NSMutableCopying, MI_Inspectable>
{
    NSMutableDictionary* parameters;
}
/* Returns a key-value pair collection of the parameters of the
    circuit element. The keys are the names of the parameters. */
- (NSMutableDictionary*) parameters;

/* Sets the parameters of the circuit element. Returns NO if there
    was an error (invalid parameter type) and YES otherwise. */
- (void) setParameters:(NSMutableDictionary*)newParameters;

// since 0.5.4
// Returns 'no device'. Should be overriden by subclasses that represent
// devices which do use models.
- (MI_DeviceModelType) usedDeviceModelType;

@end

/* protocol for all elements that behave like a node, i.e.,
having no electrical porperties. */
@protocol MI_ElectricallyTransparentElement
@end

/* protocol for all elements that represent electrical ground. */
@protocol MI_ElectricallyGroundedElement
@end
