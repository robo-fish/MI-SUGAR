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
#import "MI_TextViewLineNumbering.h"


@implementation MI_TextViewLineNumbering

- (id) init
{
    if (self = [super init])
    {
        lineNumberStringAttributes = [[NSMutableDictionary dictionaryWithCapacity:2] retain];
     /*   [lineNumberStringAttributes setObject:[NSFont systemFontOfSize:11.0f]
                                       forKey:NSFontAttributeName];*/
        [lineNumberStringAttributes setObject:[NSColor colorWithDeviceRed:0.5f
                                                                    green:0.5f
                                                                     blue:0.5f
                                                                    alpha:1.0f]
                                       forKey:NSForegroundColorAttributeName];
    }
    return self;
}


/*
 Thanks to
 Koen van der Drift <kvddrift@earthlink.net> for the code
   and to
 James S. Derry (http://www.balthisar.com) for compiling it into a demo.
*/
- (void) drawRect:(NSRect)rect
{
    NSRange	aRange;						// a range for counting lines
    NSString* currentLineNumberString;	// the string for drawing the line numbers
    int i = 0;							// glyph counter
    int j = 1; 							// line counter
    float lnWidth;						// width of the string that is the current line number
    float lnHeight;						// height of the string that is the current line number
    NSRect r;						    // rectangle holder
    NSLayoutManager* lMngr = [textView layoutManager];

    // Draw background
    [[NSColor colorWithDeviceWhite:0.92f
                             alpha:1.0f] set];
    //[[NSColor windowBackgroundColor] set];
    [NSBezierPath fillRect:rect];

    while ( i < [lMngr numberOfGlyphs] )
    {
        // get the coordinates for the current glyph's entire-line rectangle, and convert to local coordinates.
        r = [self convertRect:[lMngr lineFragmentRectForGlyphAtIndex:i
                                                      effectiveRange:&aRange]
                     fromView:textView];
        // we don't care about x -- just force it into the rect
        r.origin.x = rect.origin.x;

        /*
        if ([scroller hasHorizontalScroller])
        {
            float offset = [[scroller horizontalScroller] bounds].size.height;
            r2 = NSMakeRect(rect.origin.x, rect.origin.y + offset, rect.size.width, rect.size.height - offset);
        }
        else
            r2 = rect;
        */
        
        if (NSPointInRect(r.origin, rect))
        {
            currentLineNumberString = [NSString stringWithFormat:@"%d", j];
            // the width required to draw the string.
            lnWidth = [currentLineNumberString sizeWithAttributes:lineNumberStringAttributes].width + 5;
            lnHeight = [currentLineNumberString sizeWithAttributes:lineNumberStringAttributes].height;
            [currentLineNumberString drawAtPoint:NSMakePoint([self frame].size.width - lnWidth,
                                                             r.origin.y + (r.size.height - lnHeight)/2.0f)
                                  withAttributes:lineNumberStringAttributes];
        }
        i += [[[textView string] substringWithRange:aRange] length]; // advance glyph counter to EOL
        j++; // increment the line number
    }

    // Draw a frame - in Mac OS X the desktop light shines from the top
    [[NSColor blackColor] set];
    NSBezierPath* bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(0, rect.size.height)];
    [bp relativeLineToPoint:NSMakePoint(rect.size.width, 0)];
    [bp stroke];
    [[NSColor grayColor] set];
    bp = [NSBezierPath bezierPath];
    [bp moveToPoint:NSMakePoint(rect.size.width, rect.size.height)];
    [bp relativeLineToPoint:NSMakePoint(0, -rect.size.height)];
    [bp relativeLineToPoint:NSMakePoint(-rect.size.width, 0)];
    [bp relativeLineToPoint:NSMakePoint(0, rect.size.height)];
    [bp stroke];
}


- (void) dealloc
{
    [lineNumberStringAttributes release];
    [super dealloc];
}

@end
