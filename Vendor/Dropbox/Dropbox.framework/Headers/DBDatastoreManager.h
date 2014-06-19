/* Copyright (c) 2013 Dropbox, Inc. All rights reserved. */

#import "DBAccount.h"
#import "DBAccountManager.h"
#import "DBDatastore.h"
#import "DBError.h"


/** The datastore manager lets you list, create, open, and delete datastores. You can
 also add an observer to find out when the list of datastores changes.
*/
@interface DBDatastoreManager : NSObject

/** Gets the datastore manager for an account that has been linked via the account manager.

 The returned object will be the only datastore manager for this account until you release
 it, call <shutDown>, or the account is unlinked.  Calling this method again in the
 mean time will return the same object. */
+ (DBDatastoreManager *)managerForAccount:(DBAccount *)account;

/** Gets the local datastore manager for the accountManager.

 __Local datastores and migration are a preview feature for testing only, and should not
 be used in production apps.__
 */
+ (DBDatastoreManager *)localManagerForAccountManager:(DBAccountManager *)accountManager;

/** Opens the default datastore for this account, or creates it if it doesn't exist.

 @return The default datastore if successful, or `nil` if an error occurred. */
- (DBDatastore *)openDefaultDatastore:(DBError **)error;

/** Lists the <DBDatastoreInfo> for each of the user's datastores, including
 the default datastore if it has been created.

 @return A list of datastore <DBDatastoreInfo> objects if successful, or `nil` if an error occurred. */
- (NSArray *)listDatastores:(DBError **)error;

/** Gets a map of ID to the <DBDatastoreInfo> for each of the user's datastores, including the
 default datastore if it has been created. This method returns the most recent information
 from the server, but is overridden with the local version any time a local datastore has been changed
 and `-[DBDatastore sync:]` has been called (i.e. the changes have not yet been uploaded to the server).

 @return A map of ID to the datastore <DBDatastoreInfo> objects if successful, or `nil` if an error occurred. */
- (NSDictionary *)listDatastoreInfo:(DBError **)error;

/** Returns a new `DBDatastoreManager` created by migrating a local `DBDatastoreManager` to
 the given account.

 This will move all datastores and data from the local `DbxDatastoreManager`
 to the new `DbxDatastoreManager`. This call doesn't immediately start
 uploading the data the server. A `DbxDatastore` and all of its changes will
 begin uploading the first time you open of that `DbxDatastore`. At that point
 they will also be merged with any existing changes on the server.

 The data is moved not copied, so the local datastore manager will no longer contain the
 data which is migrated.  This should be done with a freshly linked account which contains
 no local datastore changes.  If that isn't the case, any datastore changes in the target
 account which have not uploaded will be overwritten by the migrated data.

 This must be called on a local `DbxDatastoreManager`, and all of its datastores must
 be closed. If the account provided ever had a `DbxDatastoreManager` it must be
 shut down.  After this call, the current local `DbxDatastoreManager` will be shut
 down and emptied.

 __Local datastores and migration are a preview feature for testing only, and should not
 be used in production apps.__

 @return The new datastore manager linked to the account, or `nil` if an error occurred. */
- (DBDatastoreManager *)migrateToAccount:(DBAccount *)account error:(DBError **)error;

/** Open an existing datastore by its ID.

 The same datastore can't be opened more than once.

 @return The datastore with the given ID if successful, or `nil` if an error occurred. */
- (DBDatastore *)openDatastore:(NSString *)datastoreId error:(DBError **)error;

/** Creates and opens a new datastore with a unique ID.

 @return The newly created datastore, or `nil` if an error occcurred. */
- (DBDatastore *)createDatastore:(DBError **)error;

/** Opens the datastore with the given ID, creating it if it does not already exist.

 Datastores can be created offline with this method, and their contents will be
 merged with any datastore of the same name when the app is online again.

 The same datastore can't be opened more than once.
 
 Call `-[DBDatastore isValidId:]` to check input strings before using them as a
 datastore ID.

 @return The datastore with the given ID if successful, or `nil` if an error occurred. */
- (DBDatastore *)openOrCreateDatastore:(NSString *)datastoreId error:(DBError **)error;

/** Deletes a datastore with the given ID.

 You must close open datastores before deleting them.

 @return YES if the datastore was deleted, or NO if an error occurrred. */
- (BOOL)deleteDatastore:(NSString *)datastoreId error:(DBError **)error;

/** Removes a datastore from the local cache.

 You must close open datastores before uncaching them.

 Any changes not yet uploaded to the server are discarded on uncache. If the datastore
 has such changes its <DBDatastoreStatus> has its `incoming` property set to `YES`.
 The next time a datastore is opened its entire snapshot is downloaded from the server.

 @return YES if the datastore was uncached, or NO if an error occurred. */
- (BOOL)uncacheDatastore:(NSString *)datastoreId error:(DBError **)error;

/** Add a block to be called when a datastore is added or removed.

 Observers will always be called in the main thread. */
- (void)addObserver:(id)obj block:(DBObserver)block;

/** Remove all blocks associated with the given observer. */
- (void)removeObserver:(id)obj;

/** Shuts down the datastore manager, which stops all syncing.

 All associated `DBDatastore`s will be closed.  Unsynced changes to unclosed
 datastores will be lost. Changes that were synced before shutdown but not yet
 uploaded will be uploaded the next time that particular datastore is opened.
 
 After this call, the `DBDatastoreManager` and its `DBDatastore`s can no longer be used.
 You should get a new `DBDatastoreManager` via <managerForAccount:>.

 The datastore manager will be automatically shut down if the app is unlinked remotely. */
- (void)shutDown;

/** Whether the datastore manager is currently shut down. */
@property (nonatomic, readonly, getter=isShutDown) BOOL shutDown;

@end
