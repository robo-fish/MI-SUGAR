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

/**
* This class implements a button which shows a rectangle and four arrow inside.
 The arrows point from the rectangle center to the corners.
 The arrows change color when the mouse enters the drawing area.
*/
@interface MI_FitToViewButton : NSView

@property SEL action; // the action to be executed when the button is pressed

@property NSObject* target; // the target object must implement the action above

@property (nonatomic, getter=isEnabled) BOOL enabled;

@property (nonatomic, getter=isHighlighted) BOOL highlighted;

@end
