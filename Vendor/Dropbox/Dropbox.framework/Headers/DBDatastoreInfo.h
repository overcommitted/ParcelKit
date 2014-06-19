/* Copyright (c) 2013 Dropbox, Inc. All rights reserved. */

/** The datastore info class contains basic information about a datastore. */

@interface DBDatastoreInfo : NSObject

/** The ID for this datastore. */
@property (nonatomic, readonly) NSString *datastoreId;

/** The title for this datastore, or nil if none is set. */
@property (nonatomic, readonly) NSString *title;

/** The last modified time for this datastore, or nil if none is set. The last modified
 time is automatically updated on each call to `-[DBDatastore sync:]` which commits local
 changes, or incorporates remote changes. The timestamp is based on the local clock of the
 device where the change is made.*/
@property (nonatomic, readonly) NSDate *mtime;

@end
