/* Copyright (c) 2012 Dropbox, Inc. All rights reserved. */

/** Value set for the `domain` property of a <DBError>. */
extern NSString * const DBErrorDomain;

/** Value set for the `name` property of a <DBException>. */
extern NSString * const DBExceptionName;

#ifndef NS_ENUM
#define NS_ENUM(_type, _name) _type _name; enum
#endif

/** Error codes for the `DBErrorDomain` domain.  The numeric values of these
 codes are subject to change between releases, and shouldn't be relied on. */
typedef NS_ENUM(NSInteger, DBErrorCode) {
    DBErrorUnknown = 0,

    // These errors are usually considered fatal, raising exceptions,
    // rather than returning a DBError.  The codes may be used for
    // background sync status.
    DBErrorInternal             = -1000,
    DBErrorCache                = -1001,
    DBErrorShutdown             = -1002,
    DBErrorClosed               = -1003,
    DBErrorDeleted              = -1004,
    DBErrorBadType              = -1007,
    DBErrorSizeLimit            = -1008,
    DBErrorBadIndex             = -1009,
    DBErrorIllegalArgument      = -1010,
    DBErrorBadState             = -1011,
    DBErrorMemory               = -1900,
    DBErrorSystem               = -1901,
    DBErrorNotCached            = -2000,

    // These errors indicate local errors with the API.
    DBErrorInvalidOperation     = -10000,
    DBErrorNotFound             = -10001,
    DBErrorExists               = -10002,
    DBErrorAlreadyOpen          = -10003,
    DBErrorParent               = -10004,
    DBErrorDiskSpace            = -10006,
    DBErrorDisallowed           = -10007,
    DBErrorFileIO               = -10008,

    // Errors with network communication.
    DBErrorNetwork              = -11000,
    DBErrorTimeout              = -11001,
    DBErrorConnection           = -11002,
    DBErrorSsl                  = -11003,

    // Errors during the processing of a server request.
    DBErrorServer               = -11004,
    DBErrorAuth                 = -11005,
    DBErrorQuota                = -11006,
    DBErrorRequest              = -11008,
    DBErrorReesponse            = -11009,

    // Errors specific to DBFilesystem functionality.
    DBErrorParamsNoThumb        = -12000,
};


/** The `DBError` class is a subclass of `NSError` that always has `domain` set to `DBErrorDomain`.
 <!-- paragraph separator in class docs for appledoc bug -->
 Any method expected to fail will return a `DBError` object via the last parameter.
 Additionally, errors that happen in the background via syncing can also be retrieved, such
 as the error property on <DBFileStatus>.
 <!-- paragraph separator in class docs for appledoc bug -->
 Some failures (those which represent bugs or internal errors) will instead raise a <DBException>
 when they occur in an API method. A `DBError` will still be used if such a failure occurs
 on a background thread. */
@interface DBError : NSError

/** The code on a DBError object is always listed in the DBErrorCode enum. */
- (DBErrorCode)code;

@end


/** The `DBException` class is a subclass of `NSException` that always has `name` set to
 `DBExceptionName`.  A `DBException` is raised by a failure in an API method which indicates
 programming errors or internal SDK problems.
 <!-- paragraph separator in class docs for appledoc bug -->
 You should generally not have to catch a `DBException`, but the `error` property will allow you
 to classify or translate one if you need to. */
@interface DBException : NSException

/** Information about the error which caused this exception to be raised. */
@property (nonatomic, readonly) DBError *error;

@end
