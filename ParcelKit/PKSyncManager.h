//
//  PKSyncManager.h
//  ParcelKit
//
//  Copyright (c) 2013 Overcommitted, LLC. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <Dropbox/Dropbox.h>

extern NSString * const PKDefaultSyncAttributeName;

/**
 Notification that is posted when the DBDatastoreStatus changes.
 
 The userInfo of the notification will contain the DBDatastoreStatus in `PKSyncManagerDatastoreStatusKey`
 */
extern NSString * const PKSyncManagerDatastoreStatusDidChangeNotification;
extern NSString * const PKSyncManagerDatastoreStatusKey;


/** 
 The sync manager is responsible for listening to changes from a
 Core Data NSManagedObjectContext and a Dropbox DBDatastore and syncing the changes between them.
 */
@interface PKSyncManager : NSObject

/** 
 The Core Data managed object context to listen for changes from.
 
 The managed object context must have a persistent store coordinator set.
 */
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;

/** The Dropbox Datastore to read and write to. */
@property (nonatomic, strong, readonly) DBDatastore *datastore;

/**
 The Core Data entity attribute name to use for keeping managed objects in sync.
 
 The default value is “syncID”.
*/
@property (nonatomic, copy) NSString *syncAttributeName;

/**
 Returns a random string suitable for using as a sync identifer.
 @return A random string suitable for using as a sync identifer.
 */
+ (NSString *)syncID;

/** @name Creating and Configuring a Sync Manager */

/**
 The designated initializer used to specify the Core Data managed object context and the Dropbox data store that should be synchronized.
 
 The managed object context must have a persistent store coordinator set.

 @param managedObjectContext The Core Data managed object context the sync manager should listen for changes from. 
 @param datastore The Dropbox data store the sync manager should listen for changes from and write changes to.
 @return A newly initialized `PKSyncManager` object.
 */
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext datastore:(DBDatastore *)datastore;

/**
 Map multiple Core Data entity names to their corresponding Dropbox data store table name. Replaces all other existing relationships that may have been previously set.
 @param keyedTables Dictionary of key/value pairs where the key is the Core Data entity name and the value is the corresponding Dropbox data store table name.
 */
- (void)setTablesForEntityNamesWithDictionary:(NSDictionary *)keyedTables;

/**
 Maps a single Core Data entity name to the corresponding Dropbox data store table name.
 
 Replaces any existing relationship for the given entity name that may have been previously set.
 Will raise an NSInternalInconsistencyException if the entity does not contain a valid sync attribute.
 @param tableID The Dropbox data store tableID that the entity name should be mapped to.
 @param entityName The Core Data entity name that should map to the given tableID.
 */
- (void)setTable:(NSString *)tableID forEntityName:(NSString *)entityName;

/**
 Removes the Core Data <-> Dropbox mapping for the given entity name.
 @param entityName The Core Data entity name that should no longer be mapped to Dropbox.
 */
- (void)removeTableForEntityName:(NSString *)entityName;

/** @name Accessing Entity Names and Tables */

/** 
 Returns a dictionary of tables mapped to their corresponding entity names.
 @return A dictionary of tables mapped to their corresponding entity names.
 */
- (NSDictionary *)tablesByEntityName;

/**
 Returns an array of currently mapped Dropbox data store tableIDs.
 @return An array of currently mapped Dropbox data store tableIDs.
 */
- (NSArray *)tableIDs;

/**
 Returns an array of currently mapped Core Data entity names.
 @return An array of currently mapped Core Data entity names.
 */
- (NSArray *)entityNames;

/**
 Returns the tableID associated with a given entity name.
 @param entityName The entity name for which to return the corresponding tableID.
 @return The tableID associated with entityName, or nil if no tableID is associated with entityName.
 */
- (NSString *)tableForEntityName:(NSString *)entityName;

/**
 Returns the entity name associated with a given tableID.
 @param tableID The tableID for which to return the corresponding entity name.
 @return The entity name associated with tableID, or nil if no entity name is associated with tableID.
 */
- (NSString *)entityNameForTable:(NSString *)tableID;

/** @name Observing Changes */

/**
 Returns whether or not the sync manager is currently observing changes.
 
 The default value is `NO`.
 @return `NO` if the sync manager is not observing changes, `YES` if it is.
 */
- (BOOL)isObserving;

/**
 Starts observing changes to the Core Data managed object context and the Dropbox data store.
 */
- (void)startObserving;

/**
 Stops observing changes from the Core Data managed object context and the Dropbox data store.
 */
- (void)stopObserving;

@end
