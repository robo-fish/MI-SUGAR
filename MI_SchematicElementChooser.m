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
#import "MI_SchematicElementChooser.h"
#include "common.h"

@implementation MI_SchematicElementChooser
{
  NSArray* schematicElementList; // fixed array of MI_SchematicElement objects
  MI_SchematicElement* activeElement;
  NSMenu* myContextMenu; // lists all elements
}

- (id)initWithFrame:(NSRect)frame
{
  if (self = [super initWithFrame:frame])
  {
    /* NSButton properties
    [self setImage:nil];
    [self setTitle:nil];
    [self setBezelStyle:NSRegularSquareBezelStyle];
    [self setButtonType:NSMomentaryChangeButton]; */

    schematicElementList = nil;
    activeElement = nil;
    myContextMenu = nil;
  }
  return self;
}


/* NSView method, overwritten */
- (void) drawRect:(NSRect)rect
{
  //[[NSColor grayColor] set];
  //[NSBezierPath strokeRect:NSInsetRect(rect, 3, 3)];
  if (activeElement)
  {
      [activeElement setPosition:NSMakePoint([self frame].size.width/2.0f, [self frame].size.height/2.0f)];
      [activeElement draw];
  }
  /* List Indicator - LOOKS UGLY
  if ([schematicElementList count] > 1)
  {
      [[NSColor brownColor] set];
      // draw a small arrow to indicate a list
      NSBezierPath* bp = [NSBezierPath bezierPath];
      [bp moveToPoint:NSMakePoint(rect.origin.x + rect.size.width - 4.0f,
                                  rect.origin.y + 1)];
      [bp relativeLineToPoint:NSMakePoint(3.0f, 5.0f)];
      [bp relativeLineToPoint:NSMakePoint(-6.0f, 0.0f)];
      [bp closePath];
      [bp fill];
  }
  */
}


- (BOOL) acceptsFirstMouse:(NSEvent*)theEvent
{
  return YES; // for click-through behavior
}


- (void) setSchematicElementList:(NSArray*)elements
{
  if (elements != nil && [elements count] > 0)
  {
    NSEnumerator* elementEnum;
    NSMenuItem* tmpItem;
    MI_SchematicElement* tmpElement;
    BOOL showsImageInMenu = ([elements count] <= 8);

    myContextMenu = [[NSMenu alloc] initWithTitle:@""];
    schematicElementList = elements;
    [self setActiveElement:(MI_SchematicElement*)[schematicElementList objectAtIndex:0]];
    elementEnum = [schematicElementList objectEnumerator];
    while (tmpElement = (MI_SchematicElement*)[elementEnum nextObject])
    {
      [tmpElement setShowsLabel:NO]; // no annoying labels please

      tmpItem =
          [[NSMenuItem alloc] initWithTitle:[tmpElement name]
                                     action:@selector(setActiveElementFromMenu:)
                              keyEquivalent:@""];
      [tmpItem setTarget:self];
      [tmpItem setRepresentedObject:tmpElement];
      [tmpItem setImage:(showsImageInMenu ? [tmpElement image] : nil)];
      [myContextMenu addItem:tmpItem];
      [myContextMenu setAutoenablesItems:YES];
    }
    [self setMenu:myContextMenu];
    [self setNeedsDisplay:YES];
  }
  else
  {
    schematicElementList = nil;
    activeElement = nil;
    myContextMenu = nil;
  }
}


- (void) setSchematicElement:(MI_SchematicElement*)element
{
  [self setActiveElement:element];
  if (element == nil)
      return;
  myContextMenu = nil;
  schematicElementList = @[element];
  [element setShowsLabel:NO]; // no annoying labels please
}


- (void) setActiveElement:(MI_SchematicElement*)element
{
  /* Note: No release & retain because we are
  only pointing to another element in the fixed-size list. */
  activeElement = element;
  [self setToolTip: [activeElement name]];
  [self setNeedsDisplay:YES];
}


- (void) setActiveElementFromMenu:(NSMenuItem*)menuItem
{
  [self setActiveElement:[menuItem representedObject]];
}


- (MI_SchematicElement*) activeElement
{
  return activeElement;
}


/******************** drag & drop **********************/

- (NSDragOperation) draggingSourceOperationMaskForLocal:(BOOL)flag
{
  return NSDragOperationGeneric;
}

- (void) mouseDragged:(NSEvent*)theEvent
{
    NSPoint p;
    MI_SchematicElement* copiedElement = [activeElement mutableCopy];
    [copiedElement setShowsLabel:YES];
    // Put the active element into the drag pasteboard
    NSPasteboard *dragPboard = [NSPasteboard pasteboardWithName:NSPasteboardNameDrag];
    [dragPboard declareTypes:@[MI_SchematicElementPboardType] owner:self];
    [dragPboard setData:[NSKeyedArchiver archivedDataWithRootObject:copiedElement] forType:MI_SchematicElementPboardType];
    // Set the drag image and its location
    p = [self convertPoint:[self frame].origin
                  fromView:[self superview]];
    p.x = p.x + ([self frame].size.width - [activeElement size].width) / 2.0f;
    p.y = p.y + ([self frame].size.height - [activeElement size].height) / 2.0f;
    [NSApp preventWindowOrdering];
    [self dragImage:[activeElement image]
                 at:p
             offset:NSMakeSize(0,0)
              event:theEvent
         pasteboard:dragPboard
             source:self
          slideBack:YES];
}

@end
