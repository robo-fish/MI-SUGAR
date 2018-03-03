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
#import "MI_CircuitElement.h"


/* An electrical node element with 4 connection points,
which only serves as a connection hub. */
@interface MI_NodeElement : MI_CircuitElement
    <MI_ElectricallyTransparentElement, MI_InsertableSchematicElement>
{
}
@end

/* a node element with protruding elements for easier connecting to */
@interface MI_SpikyNodeElement : MI_CircuitElement
    <MI_ElectricallyTransparentElement, MI_InsertableSchematicElement>
{
}
@end

/* Ground element with 3 connection points. */
@interface MI_GroundElement : MI_CircuitElement <MI_ElectricallyGroundedElement>
{
}
@end

/* Ground element with single connection point */
@interface MI_PlainGroundElement : MI_CircuitElement <MI_ElectricallyGroundedElement>
{
}
@end

/* Switch with two control connections */
@interface MI_VoltageControlledSwitchElement : MI_CircuitElement
{
}
@end
