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
#import "MI_Schematic.h"
#import "MI_SchematicsCanvas.h"

/*
 MI_Tool subclass objects are used to
 process user input on a schematic in a special ways.
 The main control object maintains a palette of tool objects
 but only one of them is active at a time. The active tool
 is set by the user. When a schematic canvas has to process
 user input it delegates input events to the current selected
 tool.
*/
@interface MI_Tool :NSObject
{
}
// Has to be called before when switching from another tool to this one.
- (void) activate:(MI_Schematic*) s
           canvas:(MI_SchematicsCanvas*) canvas;

// Has to be called before switching to another tool.
- (void) deactivate:(MI_Schematic*) s
             canvas:(MI_SchematicsCanvas*) canvas;

// Tool-specific state-reset method.
- (void) reset;

- (void) mouseMoved:(MI_Schematic*) s
              event:(NSEvent*)theEvent
             canvas:(MI_SchematicsCanvas*) canvas;

- (void) mouseDown:(MI_Schematic*) s
             event:(NSEvent*) theEvent
            canvas:(MI_SchematicsCanvas*) canvas;

- (void) mouseUp:(MI_Schematic*) s
           event:(NSEvent*) theEvent
          canvas:(MI_SchematicsCanvas*) canvas;

- (void) mouseDragged:(MI_Schematic*) s
                event:(NSEvent*) theEvent
               canvas:(MI_SchematicsCanvas*) canvas;

- (void) rightMouseDragged:(MI_Schematic*) s
                     event:(NSEvent*) theEvent
                    canvas:(MI_SchematicsCanvas*) canvas;

- (void) rightMouseDown:(MI_Schematic*) s
                  event:(NSEvent*) theEvent
                 canvas:(MI_SchematicsCanvas*) canvas;

- (void) rightMouseUp:(MI_Schematic*) s
                event:(NSEvent*) theEvent
               canvas:(MI_SchematicsCanvas*) canvas;

- (void) keyDown:(MI_Schematic*) s
           event:(NSEvent*) theEvent
          canvas:(MI_SchematicsCanvas*) canvas;

- (BOOL) performKeyEquivalent:(MI_Schematic*) s
                        event:(NSEvent*) theEvent
                       canvas:(MI_SchematicsCanvas*) canvas;

@end
