/* Copyright (c) 2013 Dropbox, Inc. All rights reserved. */


/** Information about a user's account. */
@interface DBAccountInfo : NSObject

/** The recommended string to display to identify an account.

 This is "userName" if `orgName` is `nil`, otherwise it's "userName (orgName)". */
@property (nonatomic, readonly) NSString *displayName;

/** The user's name. */
@property (nonatomic, readonly) NSString *userName;

/** The user's organization's name if available, or `nil` otherwise. */
@property (nonatomic, readonly) NSString *orgName;

@end
