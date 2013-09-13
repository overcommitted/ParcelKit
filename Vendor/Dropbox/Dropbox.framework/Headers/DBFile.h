/* Copyright (c) 2012 Dropbox, Inc. All rights reserved. */


#import "DBError.h"
#import "DBFileInfo.h"
#import "DBFileStatus.h"

/** The file object represents a particular file at a particular version. It has basic file
 operations such as reading and writing the file's contents and getting info about the
 file. It can also tell you the current sync status, whether there's a newer version
 available, and allows you to update to the newer version. */

@interface DBFile : NSObject

/** @name Basic operations */

/** Returns a read-only file handle for the file. If the file is not cached then the method will
 block until the file is downloaded.

 @return A file handle if the file can be read, or `nil` if an error occurred.
 */
- (NSFileHandle *)readHandle:(DBError **)error;

/** A wrapper for <readHandle:> that reads the entire file contents into an NSData object.

 @return The file's contents if the file can be read, or `nil` if an error occurred. */
- (NSData *)readData:(DBError **)error;

/** A wrapper for <readHandle:> that reads the entire file contents as a UTF8 encoded string.

 @return The file's contents decoded as UTF8 if the file can be read, or `nil` if an error occurred.
 */
- (NSString *)readString:(DBError **)error;

/** Updates the file's contents with the contents of the file at `localPath`.

 @param shouldSteal whether the file at `localPath` should be moved from its
 current location (i.e. "stolen") into management by the Sync SDK, or if it must
 be copied. If you are done with the file at `localPath`, then stealing is more
 efficient, but the behavior of writing to the file after stealing is undefined.
 @return YES if the file was written successfully, or NO if an error occurred.
 */
- (BOOL)writeContentsOfFile:(NSString *)localPath shouldSteal:(BOOL)shouldSteal error:(DBError **)error;

/** Updates the contents of the file to be the bytes stored in `data`.

 @return YES if the file was written successfully, or NO if an error occurred.
 */
- (BOOL)writeData:(NSData *)data error:(DBError **)error;

/** Updates the contents of the file with the parameter `string` encoded in UTF8.

 @return YES if the file was written successfully, or NO if an error occurred.
 */
- (BOOL)writeString:(NSString *)string error:(DBError **)error;

/** Apppends the data supplied to the end of the file. If the file is not cached, then the method will
 block until the file is downloaded.

 @return YES if the data was appended to the file successfully, or NO if an error occurred.
 */
- (BOOL)appendData:(NSData *)data error:(DBError **)error;

/** Appends the UTF8 encoded string to the file. If the file is not cached, then the method will
 block until the file is downloaded.

 @return YES if the string was appended to the file successfully, or NO if an error occured.
 */
- (BOOL)appendString:(NSString *)string error:(DBError **)error;

/** If there is a newer version of the file available, and it's cached (determined by the cached
 property on <newerStatus>), then this method will update the file object to reference the newer
 version so it can be read from or written to.

 @return YES if the file was written successfully, or NO if an error occurred.
 */
- (BOOL)update:(DBError **)error;

/** Closes the file, preventing any further operations to occur and allowing the file to be opened
 again. This happens automatically when the object is deallocated.
 */
- (void)close;


/** @name Getting the current state */

/** The DBFileInfo for the file.

 Note that the path of a file can change if a conflict occurs, so the value of
 `file.info.path` is not always equal to the path the file was opened at.

 If this DBFile represents a thumbnail, the info still reflects the full file
 contents.
 */
@property (nonatomic, readonly) DBFileInfo *info;

/** Whether the file is currently open. */
@property (nonatomic, readonly, getter=isOpen) BOOL open;

/** The current sync status for the file or thumbnail version represented by
 this DBFile. */
@property (nonatomic, readonly) DBFileStatus *status;

/** The current sync status for the newer version of the file. If the file is the newest version,
 then this property is `nil`. */
@property (nonatomic, readonly) DBFileStatus *newerStatus;

/** Whether this DBFile represents a thumbnail, rather than the file contents. */
@property (nonatomic, readonly) BOOL isThumb;


/** @name Watching for changes */

/** Add `block` as an observer when a property of the file changes. */
- (void)addObserver:(id)observer block:(DBObserver)block;

/** Remove all blocks registered for the given `observer`. */
- (void)removeObserver:(id)observer;

@end
