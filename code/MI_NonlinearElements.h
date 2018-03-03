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

// Diodes
@interface MI_DiodeElement : MI_CircuitElement
@end
@interface MI_ZenerDiodeElement : MI_CircuitElement
@end
@interface MI_LightEmittingDiodeElement : MI_CircuitElement
@end
@interface MI_PhotoDiodeElement : MI_CircuitElement
@end

// Transistors
@interface MI_NPNTransistorElement : MI_CircuitElement
@end
@interface MI_PNPTransistorElement : MI_CircuitElement
@end
@interface MI_NJFETTransistorElement : MI_CircuitElement
@end
@interface MI_PJFETTransistorElement : MI_CircuitElement
@end
@protocol MI_MOSFET_Element
@end
@protocol MI_NMOS_Element <MI_MOSFET_Element>
@end
@protocol MI_PMOS_Element <MI_MOSFET_Element>
@end
@interface MI_EnhancementNMOSTransistorElement : MI_CircuitElement <MI_NMOS_Element>
@end
@interface MI_EnhancementPMOSTransistorElement : MI_CircuitElement <MI_PMOS_Element>
@end
@interface MI_DepletionNMOSTransistorElement : MI_CircuitElement <MI_NMOS_Element>
@end
@interface MI_DepletionPMOSTransistorElement : MI_CircuitElement <MI_PMOS_Element>
@end
@protocol MI_MOSFETWithBulkConnector
@end
@protocol MI_NMOSWithBulkConnector <MI_NMOS_Element, MI_MOSFETWithBulkConnector>
@end
@protocol MI_PMOSWithBulkConnector <MI_PMOS_Element, MI_MOSFETWithBulkConnector>
@end
@interface MI_EnhancementNMOSwBulkTransistorElement : MI_CircuitElement <MI_NMOSWithBulkConnector>
@end
@interface MI_EnhancementPMOSwBulkTransistorElement : MI_CircuitElement <MI_PMOSWithBulkConnector>
@end
@interface MI_DepletionNMOSwBulkTransistorElement : MI_CircuitElement <MI_NMOSWithBulkConnector>
@end
@interface MI_DepletionPMOSwBulkTransistorElement : MI_CircuitElement <MI_PMOSWithBulkConnector>
@end
