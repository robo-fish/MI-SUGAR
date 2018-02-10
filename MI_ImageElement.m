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
#import "MI_ImageElement.h"


@implementation MI_ImageElement

- (id) initWithImage:(NSImage*)theImage
{
    if (self = [super init])
    {
        image = theImage;
        [image retain];
    }
    return self;
}


- (void) draw
{
    [super draw];

    [image drawAtPoint:NSMakePoint(position.x - [image size].width / 2,
                                   position.y - [image size].height / 2)
              fromRect:NSMakeRect(0, 0, [image size].width, [image size].height)
             operation:NSCompositeSourceOver
              fraction:1.0f];
        
    [super endDraw];
}


- (void) dealloc
{
    [image release];
    [super dealloc];
}

@end
