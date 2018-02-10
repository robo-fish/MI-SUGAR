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
#include "common.h"
#import "MI_SchematicElement.h"

/*
Displays the image of a schematics element and shows a context
menu filled with more elements. Selecting an element from the menu
makes that element's image replace the current image.
*/
@interface MI_SchematicElementChooser : NSView

/* Sets the list of schematics elements which will be shown in the
context menu. the first element is displayed by default. */
- (void) setSchematicElementList:(NSArray*)elements;

// For displaying a single element only
- (void) setSchematicElement:(MI_SchematicElement*)element;

/* Sets the active element, whose image will be displayed. */
- (void) setActiveElement:(MI_SchematicElement*)element;

/* Sets the active element, whose image will be displayed, from its menu item. */
- (void) setActiveElementFromMenu:(NSMenuItem*)menuItem;

- (MI_SchematicElement*) activeElement;

@end
