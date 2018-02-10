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
#import "MI_TextView.h"

@implementation MI_TextView

- (id) init
{
    if (self = [super init])
        dropHandler = nil;
    return self;
}


- (void) awakeFromNib
{
    [self registerForDraggedTypes:
        [NSArray arrayWithObjects:NSStringPboardType, NSURLPboardType,
            NSFilenamesPboardType, nil]];
    //NSLog([[self readablePasteboardTypes] description]);
}


- (MI_TextViewLineNumbering*) lineNumberingView
{
    return lineNumberingView;
}


- (void) drawRect:(NSRect)rect
{
    // Notify the line numbering view if it exists
    if (lineNumberingView)
        [lineNumberingView setNeedsDisplay:YES];
    [super drawRect:rect];
}


- (void) setDropHandler:(NSObject <MI_DropHandler>*)handler
{
    [handler retain];
    [dropHandler release];
    dropHandler = handler;
}


- (NSObject <MI_DropHandler>*) dropHandler
{
    return dropHandler;
}


- (NSArray*) readablePasteboardTypes
{
    return [NSArray arrayWithObjects:NSStringPboardType, NSURLPboardType,
        NSFilenamesPboardType, nil];
}


- (NSDragOperation) dragOperationForDraggingInfo:(id <NSDraggingInfo>)dragInfo
                                            type:(NSString*)type
{
    //NSLog(@"dragOperationForDraggingInfo");
    NSPasteboard *pboard = [dragInfo draggingPasteboard];
    if ([[pboard types] indexOfObject:NSURLPboardType] == NSNotFound)
        return NSDragOperationNone;
    else
        return NSDragOperationCopy;
}


- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender
{
    //NSLog(@"dragging entered");
    NSPasteboard *pboard = [sender draggingPasteboard];
    if (([[pboard types] indexOfObject:NSURLPboardType] == NSNotFound) &&
        ([[pboard types] indexOfObject:NSFilenamesPboardType] == NSNotFound))
        return NSDragOperationNone;
    else
        return NSDragOperationLink;
}


- (void) draggingExited:(id <NSDraggingInfo>)sender
{
    //NSLog(@"dragging exited");
}


- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    //NSLog(@"prepare for drag");
    return YES;
}


- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender
{
    //NSLog(@"perform drag op");
    [dropHandler processDrop:sender];
    return YES;
}


- (void) concludeDragOperation:(id <NSDraggingInfo>)sender
{
    //NSLog(@"conclude");
}


- (void) mouseDown:(NSEvent*)theEvent
{
    [[self window] makeFirstResponder:self];
    [super mouseDown:theEvent];
}    


- (void) dealloc
{
    [dropHandler release];
    [self unregisterDraggedTypes];
    [super dealloc];
}


@end
