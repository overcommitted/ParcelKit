/* Copyright (c) 2013 Dropbox, Inc. All rights reserved. */

#import "DBDatastore.h"

/** The datastore info class contains basic information about a datastore. */

@interface DBDatastoreInfo : NSObject

/** The ID for this datastore. */
@property (nonatomic, readonly) NSString *datastoreId;

/** The title for this datastore, or nil if none is set. */
@property (nonatomic, readonly) NSString *title;

/** The last modified time for this datastore, or nil if none is set. The last modified
 time is automatically updated on each call to `-[DBDatastore sync:]` which commits local
 changes, or incorporates remote changes. The timestamp is based on the local clock of the
 device where the change is made. */
@property (nonatomic, readonly) NSDate *mtime;

/** The role the current user has for this datastore. */
@property (nonatomic, readonly) DBRole role;

/** Whether this datastore is shareable. (== whether datastoreId starts with '.') */
@property (nonatomic, readonly) BOOL isShareable;

/** Whether this datastore can be written (i.e., role is owner or editor). */
@property (nonatomic, readonly) BOOL isWritable;

@end
