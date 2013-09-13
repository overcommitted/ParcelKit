/* Copyright (c) 2013 Dropbox, Inc. All rights reserved. */

#import "DBAccountManager.h"
#import "DBError.h"
#import "DBTable.h"
#import "DBUtil.h"

@class DBDatastoreManager;

enum DBDatastoreStatusFlags {
    DBDatastoreConnected = 1 << 0, // The API is connected with the server
    DBDatastoreDownloading = 1 << 1, // Changes are currently downloading
    DBDatastoreUploading = 1 << 2, // Changes are currently uploading
    DBDatastoreIncoming = 1 << 3, // There are remote changes waiting to be synced
    DBDatastoreOutgoing = 1 << 4 // There are local changes waiting to be synced
};

/** A bitset indicating the current sync status of the datastore. */
typedef NSUInteger DBDatastoreStatus;


/** A datastore is a simple, syncable database for app data. You can open the default datastore
 using <openDefaultStoreForAccount:error:> and open or create other datastores using a
 <DBDatastoreManager>.

 You interact with data in the datastore using tables. You can call <getTable:> to get a table,
 or <getTables:> to list all tables in a datastore containing records.

 Changes you make to the datastore will be visible immediately, and calling <sync:> will persist
 outgoing changes and queue them to be uploaded to the server. While a datastore is open, it will
 monitor for remote changes and download them when possible. When there are remote changes waiting
 to be incorporated, the `DBDatastoreIncoming` flag will be set in the <status> bitset, and calling
 <sync:> will also apply those changes to your view of the datastore, resolving any conflicts along
 the way.

 To find out when there are changes ready to be synced, add an observer using <addObserver:block:>
 to register a block that will be called every time <status> changes.
 */
@interface DBDatastore : NSObject

/** Opens the default datastore for this account. */
+ (DBDatastore *)openDefaultStoreForAccount:(DBAccount *)account error:(DBError **)error;

/** Close a datastore when you're done using it to indicate that you are no longer
 interested in receiving updates for this datastore.

 Any changes made since the last call to <sync:> will be discarded on close. If the account is
 unlinked remotely, the datastore will close automatically.
 */
- (void)close;

/** Get all the tables in this datastore that contain records. */
- (NSArray *)getTables:(DBError **)error;

/** Get a table with the specified ID, which can be used to insert or query records. If this is a
 new table ID, the table will not be visible until a record is inserted. */
- (DBTable *)getTable:(NSString *)tableId;

/** Apply all outstanding changes to the datastore, and also incorporate remote changes in.

 @returns A dictionary mapping of `tableId` to a set of <DBRecord> objects if the call was
 successful, or `nil` if an error occurred. The table IDs and records in the dictionary correspond
 to the tables and records that changed due to remote changes applied during this sync. You can
 detect records that have been deleted using the `deleted` property on the records. */
- (NSDictionary *)sync:(DBError **)error;

/** Whether the datastore is currently open. */
@property (nonatomic, readonly, getter=isOpen) BOOL open;

/** The current sync status of the datastore. */
@property (nonatomic, readonly) DBDatastoreStatus status;

/** Add `block` as an observer when the status of the datastore changes. */
- (void)addObserver:(id)observer block:(DBObserver)block;

/** Remove all blocks registered for the given `observer`. */
- (void)removeObserver:(id)observer;

/** The ID for this datastore. */
@property (nonatomic, readonly) NSString *datastoreId;

/** The datastore manager for this datastore. */
@property (nonatomic, readonly) DBDatastoreManager *manager;

@end
