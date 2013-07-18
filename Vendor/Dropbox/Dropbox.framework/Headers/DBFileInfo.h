/* Copyright (c) 2012 Dropbox, Inc. All rights reserved. */

@class DBPath;


/** The file info class contains basic information about a file or folder. */

@interface DBFileInfo : NSObject <NSCopying>

/** The path of the file or folder. */
@property (nonatomic, readonly) DBPath *path;

/** Whether the item at `path` is a folder or a file. */
@property (nonatomic, readonly) BOOL isFolder;

/** The last time the file or folder was modified. */
@property (nonatomic, readonly) NSDate *modifiedTime;

/** The file's size. This property is always 0 for folders. */
@property (nonatomic, readonly) long long size;

/** Whether a thumbnail for this file can be requested from the server, based
 on the file format. Since thumbnails are generated only by the server, this
 value will be false on a locally-modified file until it finishes uploading. */
@property (nonatomic, readonly) BOOL thumbExists;

/** The name of an appropriate icon to display for the file, taken
 from the Dropbox icon library.  Will be `nil` if no suggested icon
 is available.  For more information see the
 [metadata](https://www.dropbox.com/developers/core/docs#metadata)
 documentation. */
@property (nonatomic, readonly) NSString *iconName;

@end
