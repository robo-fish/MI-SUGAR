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
#import "MI_Tool.h"

@implementation MI_Tool
// Empty default implementations

- (void) activate:(MI_Schematic*) s
           canvas:(MI_SchematicsCanvas*) canvas
{}

- (void) deactivate:(MI_Schematic*) s
             canvas:(MI_SchematicsCanvas*) canvas
{}

- (void) reset
{}

- (void) mouseMoved:(MI_Schematic*) s
              event:(NSEvent*)theEvent
             canvas:(MI_SchematicsCanvas*) canvas
{}

- (void) mouseDown:(MI_Schematic*) s
             event:(NSEvent*)theEvent
            canvas:(MI_SchematicsCanvas*) canvas
{}

- (void) mouseUp:(MI_Schematic*) s
           event:(NSEvent*)theEvent
          canvas:(MI_SchematicsCanvas*) canvas
{}

- (void) mouseDragged:(MI_Schematic*) s
                event:(NSEvent*)theEvent
               canvas:(MI_SchematicsCanvas*) canvas
{}

- (void) rightMouseDragged:(MI_Schematic*) s
                     event:(NSEvent*)theEvent
                    canvas:(MI_SchematicsCanvas*) canvas
{}

- (void) rightMouseDown:(MI_Schematic*) s
                  event:(NSEvent*)theEvent
                 canvas:(MI_SchematicsCanvas*) canvas
{}

- (void) rightMouseUp:(MI_Schematic*) s
                event:(NSEvent*)theEvent
               canvas:(MI_SchematicsCanvas*) canvas
{}

- (void) keyDown:(MI_Schematic*) s
           event:(NSEvent*)theEvent
          canvas:(MI_SchematicsCanvas*) canvas
{}

- (BOOL) performKeyEquivalent:(MI_Schematic*)s
                        event:(NSEvent*)theEvent
                       canvas:(MI_SchematicsCanvas*) canvas
{
    return NO; // events are not processed by default
}


@end
