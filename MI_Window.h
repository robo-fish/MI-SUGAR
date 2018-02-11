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
#include "common.h"
/*
  Extends the NSWindow class by adding support for being a drop target.
  Sends keyboard events to its delegate.
*/
@interface MI_Window : NSWindow

@property NSObject<MI_DropHandler>* dropHandler;
- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender;
- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender;
- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender;
- (void) concludeDragOperation:(id <NSDraggingInfo>)sender;

@end
