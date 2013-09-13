/* Copyright (c) 2012 Dropbox, Inc. All rights reserved. */


/** The path object represents a valid Dropbox path, and knows how to do correct path comparisons.
 It also has convenience methods for constructing new paths. */

@interface DBPath : NSObject <NSCopying>

/** The top-most folder in your app's view of the user's Dropbox. */
+ (DBPath *)root;

/** Create a new path object from a string.  Some special characters, names, or encodings a
 are not allowed in a Dropbox path.  For more details see this
 [article](http://www.dropbox.com/help/145).

 @return A new path object if the contents of `pathStr` are a valid Dropbox path, `nil` otherwise.
 */
- (id)initWithString:(NSString *)pathStr;

/** The unqualified name of the file or folder at this path.
  For the root, this will return the same as `stringValue`. */
- (NSString *)name;

/** Create a new path by treating the current path as a path to a folder, and `childName` as the
 name of an item in that folder.

 @return A new path, or `nil` if `childName` is invalid.
 */
- (DBPath *)childPath:(NSString *)childName;

/** Create a new path that is the folder containing the current path.
 For the root, this will return the same as `stringValue`.

 @return A new path, or `nil` if path is already at the root.
 */
- (DBPath *)parent;

/** The fully qualified path (relative to the root) as a string, with original casing. */
- (NSString *)stringValue;

@end
