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

@interface MI_SchematicElementChooser (DragNDrop) <NSPasteboardItemDataProvider, NSDraggingSource>
@end


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


- (void) drawRect:(NSRect)rect
{
  if (activeElement)
  {
    [activeElement setPosition:NSMakePoint([self frame].size.width/2.0f, [self frame].size.height/2.0f)];
    [activeElement draw];
  }
}


- (BOOL) acceptsFirstMouse:(NSEvent*)theEvent
{
  return YES; // for click-through behavior
}


- (void) mouseDragged:(NSEvent*)theEvent
{
  CGPoint const p = [self convertPoint:[self frame].origin fromView:[self superview]];
  CGSize const size = activeElement.size;
  CGFloat originX = p.x + ([self frame].size.width - size.width) / 2.0;
  CGFloat originY = p.y + ([self frame].size.height - size.height) / 2.0;
  [NSApp preventWindowOrdering];
  NSPasteboardItem* pbItem = [[NSPasteboardItem alloc] init];
  [pbItem setDataProvider:self forTypes:@[MI_SchematicElementPboardType]];
  NSDraggingItem* draggingItem = [[NSDraggingItem alloc] initWithPasteboardWriter:pbItem];
  [draggingItem setDraggingFrame:NSMakeRect(originX, originY, size.width, size.height) contents: [activeElement image]];
  [self beginDraggingSessionWithItems:@[draggingItem] event:theEvent source:self];
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

@end


@implementation MI_SchematicElementChooser (DragNDrop)

- (void) pasteboard:(nullable NSPasteboard *)pasteboard item:(NSPasteboardItem *)item provideDataForType:(NSPasteboardType)type
{
  MI_SchematicElement* copiedElement = [activeElement mutableCopy];
  [copiedElement setShowsLabel:YES];
  NSData* data = [NSKeyedArchiver archivedDataWithRootObject:copiedElement];
  [pasteboard setData:data forType:type];
}

- (NSDragOperation) draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
  return NSDragOperationGeneric;
}

@end
