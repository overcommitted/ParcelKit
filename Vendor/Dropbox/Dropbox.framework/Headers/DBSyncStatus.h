/* Copyright (c) 2014 Dropbox, Inc. All rights reserved. */

#import "DBError.h"

/** The current status of one type of background synchronization operation
 in a <DBFilesystem>. */
@interface DBSyncOperationStatus : NSObject

/** Indicates that operations are in progress or queued for retry. */
@property (nonatomic, readonly) BOOL inProgress;

/** If the most recent operation failed, the failure is represented here.
 Otherwise this field is `nil`. */
@property (nonatomic, readonly) DBError *error;

@end


/** The current status of background synchronization for a <DBFilesystem>. */
@interface DBSyncStatus : NSObject

/** Background synchronization is actively processing or waiting for
 changes. Syncing is active when a <DBFilesystem> is first created until
 it completes its first file info sync.  After that point it is active
 whenever there are changes to download or upload, or when there are any files
 open or path observers registered. */
@property (nonatomic, readonly) BOOL active;

/** Status of synchronizing info about files and folders. Metadata sync is
 only considered in progress when it is actively processing new changes,
 not when it is simply watching for changes. */
@property (nonatomic, readonly) DBSyncOperationStatus *metadata;

/** Status of downloading file contents into the cache. */
@property (nonatomic, readonly) DBSyncOperationStatus *download;

/** Status of uploading changes to the server. This includes changes to file
 contents, as well as creation, deletion, and renames. */
@property (nonatomic, readonly) DBSyncOperationStatus *upload;

/** Convenience property for checking whether any type of operation is in
 progress. */
@property (nonatomic, readonly) BOOL anyInProgress;

/** Convenience property for determining whether any operation failed, and
 getting an appropriate <DBError>. If there are multiple failures, the
 <DBError> returned will be taken from metadata, download, or upload status in
 that order. */
@property (nonatomic, readonly) DBSyncOperationStatus *anyError;

@end
