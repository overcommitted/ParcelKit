/* Copyright (c) 2012 Dropbox, Inc. All rights reserved. */

#import "DBAccountManager.h"
#import "DBAccountInfo.h"
#import "DBUtil.h"

/** The account represents a particular user who has linked his account to your app. You can get
 account objects from the [account manager](DBAccountManager).*/

@interface DBAccount : NSObject

/** @name Unlinking an account */

/** This method unlinks a user's account from your app.

 Once an account is unlinked, the local cache is deleted. If there is a
 [filesystem](DBFilesystem) object created with this account it will stop running. */
- (void)unlink;


/** @name Getting the current state */

/** The user id of the account. This can be used to associate metadata with a given account. */
@property (nonatomic, readonly) NSString *userId;

/** Whether the account is currently linked. Note that accounts can be unlinked via the <unlink>
 method or from the Dropbox website. */
@property (nonatomic, readonly, getter=isLinked) BOOL linked;

/** Information about the user of this account. */
@property (nonatomic, readonly) DBAccountInfo *info;


/** @name Watching for changes */

/** Add `block` as an observer of an account to get notified whenever the account's
 <linked> or <info> properties change. */
- (void)addObserver:(id)observer block:(DBObserver)block;

/** Remove all blocks associated with `observer` by the <addObserver:block:> method. */
- (void)removeObserver:(id)observer;

@end
