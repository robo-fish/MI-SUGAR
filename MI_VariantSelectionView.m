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
#import "MI_VariantSelectionView.h"

static const float mi_drawing_unit_fraction = 0.05f;


@implementation MI_VariantSelectionView
{
@private
  MI_VariantChoice _selectedVariant;
  int flashingCounter; // needed for flashing animation - counts the animation steps
  MI_VariantChoice flashedVariant; // the variant which is flashed
  NSColor* flashColor; // the color used for flashing
}


- (id)initWithFrame:(NSRect)frame
{
  if (self = [super initWithFrame:frame])
  {
    _selectedVariant = MI_SCHEMATIC_VARIANT_NONE;
    flashedVariant = MI_SCHEMATIC_VARIANT_NONE;
    flashColor = [NSColor redColor];
  }
  return self;
}


- (void) setSelectedVariant:(MI_VariantChoice)variant
{
  _selectedVariant = variant;
  [self setNeedsDisplay:YES];
}


- (MI_VariantChoice) selectedVariant
{
  return _selectedVariant;
}


- (void) flashVariant:(MI_VariantChoice)variant
{
  if (variant != _selectedVariant)
  {
    flashingCounter = 0;
    flashedVariant = variant;
    [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(handleFlashingTimer:) userInfo:nil repeats:YES];
  }
}


- (void) handleFlashingTimer:(NSTimer*)timer
{
  if (flashingCounter >= 0 && flashingCounter < 2)
  {
    flashColor = [NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.9f alpha:1.0f];
  }
  else if (flashingCounter >= 2 && flashingCounter < 7)
  {
    flashColor = [NSColor colorWithDeviceRed:0.15f * (flashingCounter - 1) green:0.15f * (flashingCounter - 1) blue:0.9f alpha:1.0f];
  }
  else if (flashingCounter >= 7)
  {
    [timer invalidate];
    flashedVariant = MI_SCHEMATIC_VARIANT_NONE;
  }
  flashingCounter++;
  [self setNeedsDisplay:YES];
}


// Draw 4 dots in one row
//
//    []  []  []  []
//     1   2   3   4
//
// A unit is one twentieth of the width of the view.
// Margins between dots and border are 1 unit.
// Margins between dots are 2 units
// Dot diameters are three units.
// The position of the dots is vertically centered.
- (void) drawRect:(NSRect)rect
{
    int i;
    float unit = mi_drawing_unit_fraction;
    for (i = 0; i < 4; i++)
    {
        if (i == [self selectedVariant])
            [[NSColor colorWithDeviceRed:0.35f green:0.1f blue:0.1f alpha:1.0f] set];
        else if (i == flashedVariant)
            [flashColor set];
        else
            [[NSColor colorWithDeviceRed:0.75f green:0.75f blue:0.9f alpha:1.0f] set];
        [[NSBezierPath bezierPathWithOvalInRect:
            NSMakeRect( (1 + i*5) * unit * rect.size.width,
                        rect.size.height/2.0f - 1.5f * unit * rect.size.width,
                        3 * unit * rect.size.width,
                        3 * unit * rect.size.width)
            ] fill];
    }
}


- (BOOL) isOpaque
{
    return NO;
}

// Needed for putting this item into toolbars.
- (BOOL) isEnabled
{
    return YES;
}


- (void) mouseDown:(NSEvent*)theEvent
{
  NSPoint currentPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  int const theVariant = (int) floor(currentPoint.x/(5 * [self frame].size.width * mi_drawing_unit_fraction));
  [self.target performSelector:self.action withObject:[NSNumber numberWithInt:theVariant] afterDelay:0.0];
}

@end
