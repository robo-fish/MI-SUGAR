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
#import "MI_SubcircuitDocumentModel.h"
#import "MI_SubcircuitElement.h"

extern NSString* MISUGAR_SUBCIRCUIT_LIBRARY_FOLDER;

/*
 Acts as a data source for the subcircuit elements table.
 There is only a single library manager for one session.
 When the application starts the files in the directory
 ~/Library/Application Support/MI-SUGAR/Subcircuits/
 are read and MI_SubcircuitElement objects are created.
 The element names populate the table in the elements
 panel. The graphical representation of the selected
 element is shown in the drag source for subcircuits. 
 
 The library manager also makes sure that there is only
 a single system-wide definition (document model) for
 each type of subcircuit. The definitions are stored
 in a dictionary which uses the name of the subcircuit
 schematic element as key.
*/
@interface MI_SubcircuitLibraryManager : NSObject <NSOutlineViewDataSource, NSOutlineViewDelegate>
{
    // widget which holds the draggable representation of a subcircuit element
    MI_SchematicElementChooser* chooser;

    // widget which holds the list of subcircuits
    NSOutlineView* table;
    
    // namespace display field
    NSTextField* namespaceField;
}
// The view element shows the graphical representation of the selected subcircuit
- (id) initWithChooserView:(MI_SchematicElementChooser*)chooser
                 tableView:(NSOutlineView*)table
             namespaceView:(NSTextField*)nsField;

// Saves the model in a file in the subcircuit library directory.
// Optionally opens the newly created subcircuit document.
- (BOOL) addSubcircuitToLibrary:(MI_SubcircuitDocumentModel*)definition
                           show:(BOOL)openDocument;

// Refreshes the list of available subcircuits in the repository.
- (void) refreshList;

// Calls refreshList and sets the shape of the top item in the display.
- (void) refreshAll;

// Connects to the MacInit site and downloads new subcircuits
- (void) synchronizeWithOnlineLibrary;

// Returns the document model (the definition) of a subcircuit given the
// fully qualified name of the subcircuit element
- (MI_SubcircuitDocumentModel*) modelForSubcircuitName:(NSString*)name;

// Opens the definition of the selected subcircuit in a document window
- (IBAction) showDefinitionOfSelectedSubcircuit:(id)sender;

// returns the file path of the default subcircuit library
+ (NSString*) defaultSubcircuitLibraryPath;

// Checks if the given folder exists and optionally notifies the user if not
- (BOOL) validateLibraryFolder:(NSString*)folderPath
                      warnUser:(BOOL)warn;

// Performs all necessary tasks to display the given element
- (void) displaySubcircuitElement:(MI_SubcircuitElement*)element;

@end
