/* Copyright (c) 2012 Dropbox, Inc. All rights reserved. */


extern NSString * const DBErrorDomain;

#ifndef NS_ENUM
#define NS_ENUM(_type, _name) _type _name; enum
#endif

typedef NS_ENUM(NSInteger, DBErrorCode) {
    DBErrorUnknown = 0,

    DBErrorCoreSystem = 1, // System error, out of memory, etc

    DBErrorParams = 2000, // An error due to data passed into the API
    DBErrorParamsInvalid, // A parameter is invalid, such as a nil object
    DBErrorParamsNotFound, // A file corresponding to a provided path was not found
    DBErrorParamsExists, // File already exists and was opened exclusively
    DBErrorParamsAlreadyOpen, // File was already open
    DBErrorParamsParent, // Parent does not exist or is not a folder
    DBErrorParamsNotEmpty, // Directory is not empty
    DBErrorParamsNotCached, // File was not yet in cache
    DBErrorParamsDisallowed, // App is not allowed to perform this operation
    DBErrorParamsNoThumb, // No thumbnail is available
    DBErrorParamsIndex, // Index is out of bounds
    DBErrorParamsType, // Value is of the wrong type

    DBErrorSystem = 3000, // An error in the library occurred
    DBErrorSystemDiskSpace, // An error happened due to insufficient local disk space

    DBErrorNetwork = 4000, // An error occurred making a network request
    DBErrorNetworkTimeout, // A connection timed out
    DBErrorNetworkNoConnection, // No network connection available
    DBErrorNetworkSSL, // Unable to verify the server's SSL certificate. Often caused by an out-of-date clock
    DBErrorNetworkServer, // Unexpected server error

    DBErrorNetworkQuota = 4006, // The user's Dropbox space is full

    DBErrorAuth = 5000, // An authentication related problem occurred
    DBErrorAuthUnlinked, // The user is no longer linked
    DBErrorAuthInvalidApp, // An invalid app key or secret was provided
};


/** The DBError class is a subclass of NSError that always has `domain` set to `DBErrorDomain`.
 <p>
 Any method that can potentially fail will return a DBError object via the last parameter.
 Additionally, errors that happen in the background via syncing can also be retrieved, such
 as the error property on DBFileStatus.
 </p> */
@interface DBError : NSError

/** The code on a DBError object is always listed in the DBErrorCode enum. */
- (DBErrorCode)code;

@end
