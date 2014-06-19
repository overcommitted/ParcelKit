/* Copyright (c) 2014 Dropbox, Inc. All rights reserved. */

#import "DBError.h"

/** Sync status for a <DBDatastore>, including any errors that are preventing
 syncing. */
@interface DBDatastoreStatus : NSObject

/** Whether the API is in active communication with the server so that remote changes are likely to be
 visible quickly, and local changes can be uploaded soon. The API will attempt to connect when datastores
 are open, but may fail if offline. */
@property (nonatomic, readonly) BOOL connected;

/** Whether there are remote changes that need to be downloaded from the server.
 Always set when a `DBDatastore` is opened until the first successful check for updates. */
@property (nonatomic, readonly) BOOL downloading;

/** Whether there are local changes that need to be uploaded to the server. */
@property (nonatomic, readonly) BOOL uploading;

/** Whether there are remote changes that will be incorporated by the next
 * call to `-[DBDatastore sync:]`. */
@property (nonatomic, readonly) BOOL incoming;

/** Whether there are local changes that haven't yet been committed by a
 * call to `-[DBDatastore sync:]`. */
@property (nonatomic, readonly) BOOL outgoing;

/** Whether the local datastore needs to be reset with a call to
 * `-[DBDatastore close:]` followed by `-[DBDatastoreManager uncacheDatastore:]`. */
@property (nonatomic, readonly) BOOL needsReset;

/** The latest error preventing local datastore state from being uploaded, or nil if there is no error */
@property (nonatomic, readonly) DBError *uploadError;

/** The latest error preventing remote datastore state from being downloaded, or nil if there is no error */
@property (nonatomic, readonly) DBError *downloadError;

/** An error (downloadError or uploadError) affecting this datastore, or nil if there is no error.
 This is a convenience for determining whether any operations are failing. */
@property (nonatomic, readonly) DBError *anyError;

@end
