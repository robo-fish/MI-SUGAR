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
#import "MI_Window.h"

@implementation MI_Window

- (instancetype) init
{
  if (self = [super init])
  {
    _dropHandler = nil;
  }
  return self;
}


- (void) dealloc
{
  [self unregisterDraggedTypes];
}


- (void) awakeFromNib
{
  [self registerForDraggedTypes:@[NSURLPboardType]];
}


- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender
{
  NSPasteboard *pboard = [sender draggingPasteboard];
  if ([[pboard types] indexOfObject:NSURLPboardType] == NSNotFound)
      return NSDragOperationNone;
  else
      return NSDragOperationLink;
}


- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender
{
  return YES;
}


- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender
{
  [self.dropHandler processDrop:sender];
  return YES;
}


- (void) concludeDragOperation:(id <NSDraggingInfo>)sender
{
}


@end
