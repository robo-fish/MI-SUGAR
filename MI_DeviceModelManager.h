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
#import "MI_CircuitElementDeviceModel.h"

// The application uses only one instance of this class.
// The instance is responsible for managing the device model collection
// and for providing related services.
@interface MI_DeviceModelManager : NSObject
{
    // The keys are NSNumber objects constructed from the type of the contained models.
    // The values are NSMutableArray instances that contain MI_CircuitElementDeviceModel
    // instances for one type. Device models with names starting with "Default" are 
    // reserved by MI-SUGAR.
    NSMutableDictionary* deviceModels;

    IBOutlet NSTextView* modelParametersArea;
    
    // The items of the tree view can be NSNumber instances (for the
    // the expandable items the correspond to arrays of device models
    // of a specific type), or device models (trivial).
    IBOutlet NSOutlineView* modelTree;
    
    IBOutlet NSWindow* deviceModelPanel;
    NSToolbarItem* deleteButton;
    NSToolbarItem* copyButton;
    NSToolbarItem* importButton;
    NSToolbarItem* exportButton;
}
// Returns the singleton instance.
+ (MI_DeviceModelManager*) sharedManager;

// Removes the selected device model from the repository.
- (IBAction) deleteSelectedDeviceModels:(id)sender;

// Makes a copy of the selected device model and adds it to the repository.
- (IBAction) copySelectedDeviceModels:(id)sender;

// Prompts user for a file then unarchives device models from given file
// and adds them to the original repository
- (IBAction) importDeviceModelsFromFile:(id)sender;

// Prompts user for a file then archives all device models in the
// repository to the given file.
- (IBAction) exportSelectedDeviceModelsToFile:(id)sender;

// Constructs the GUI, if necessary, and makes it visible.
- (void) showPanel;
- (void) hidePanel;
- (void) togglePanel;

// Convenience method for internal use
- (void) saveModels;

// Finds the first model with a matching name and returns its parameters
- (NSString*) deviceParametersForModelName:(NSString*)name;

// Compares names of the device models in the given list with
// the names of the local models and adds the new ones.
- (void) importDeviceModels:(NSArray*)models;

// Adds the given model to the library. For internal use.
- (void) addModel:(MI_CircuitElementDeviceModel*)newModel;

// Returns NO if there was an error
- (BOOL) addModelsFromFile:(NSString*)filePath;

// Returns NO if there was an error
- (BOOL) dumpModels:(NSArray*)models
             toFile:(NSString*)filePath;

// Returns the complete list of models which are of the given type.
- (NSArray*) modelsForType:(MI_DeviceModelType)modeltype;

// Returns the first model which has the given name, or nil if nothing was found.
- (MI_CircuitElementDeviceModel*) modelForName:(NSString*)modelName;

@end
