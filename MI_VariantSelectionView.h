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

typedef enum MI_VariantChoice_
{
    MI_SCHEMATIC_VARIANT_NONE   = -1,
    MI_SCHEMATIC_VARIANT_1      = 0,
    MI_SCHEMATIC_VARIANT_2      = 1,
    MI_SCHEMATIC_VARIANT_3      = 2,
    MI_SCHEMATIC_VARIANT_4      = 3,
    MI_SCHEMATIC_VARIANT_LAST   = 3
} MI_VariantChoice;

// Displays 4 dots, representing the 4 available schematic variants.
// Empty slots are greyed out, used ones are bluish grey, current selection
// is dark red.
@interface MI_VariantSelectionView : NSView

// There can only be one selected variant.
// Only an occupied variant can be selected.
@property (nonatomic) MI_VariantChoice selectedVariant;

// Initatiates a flashing animation of an unselected variant.
- (void) flashVariant:(MI_VariantChoice)variant;
// This method is called by the timer which drives the flashing animation.
- (void) handleFlashingTimer:(NSTimer*)timer;

@property NSObject* target;
@property SEL action; // must have a single argument, the selected variant as an NSNumber object, i.e., targetMethod:(NSNumber*)variant

@end
