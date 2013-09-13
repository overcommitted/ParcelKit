/* Copyright (c) 2012 Dropbox, Inc. All rights reserved. */

/** Possible values for [DBFileStatus state]. */
typedef enum {
    DBFileStateDownloading,
    DBFileStateIdle,
    DBFileStateUploading,
} DBFileState;


/** The file status object exposes information about the file's current sync status,
 including whether it's cached, if it's uploading or downloading, and the progress
 of an upload or download. */

@interface DBFileStatus : NSObject

/** @name Basic information */

/** Whether the contents of the file are cached locally and can be read without making a network
 request. */
@property (nonatomic, readonly) BOOL cached;


/** @name Transfer information */

/** Whether the file is currently uploading, downloading, or neither (idle) */
@property (nonatomic, readonly) DBFileState state;

/** If the file is transferring, the progress of the transfer, between 0 and 1. */
@property (nonatomic, readonly) float progress;

/** If the file needs to be transferred, but can't for whatever reason (such as no internet
 connection), then this property is set to the last error that prevented the transfer. */
@property (nonatomic, readonly) DBError *error;

@end
