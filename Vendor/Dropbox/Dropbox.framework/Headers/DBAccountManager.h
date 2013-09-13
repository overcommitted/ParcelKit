/* Copyright (c) 2012 Dropbox, Inc. All rights reserved. */

#import <UIKit/UIKit.h>

@class DBAccount;

/** An observer for the <linkedAccount> property */
typedef void (^DBAccountManagerObserver)(DBAccount *account);

/** The account manager is responsible for linking new users and persisting account information
 across runs of your app. You typically create an account manager at app startup with your
 app key and secret and keep it until your app terminates.
 */

@interface DBAccountManager : NSObject

/** @name Creating an account manager */

/** Create a new account manager with your app's app key and secret. You can register your app or
 find your key at the [apps](https://www.dropbox.com/developers/apps) page. */
- (id)initWithAppKey:(NSString *)key secret:(NSString *)secret;

/** A convenient place to store your app's account manager. */
+ (void)setSharedManager:(DBAccountManager *)sharedManager;

/** A convenient place to get your app's account manager. */
+ (DBAccountManager *)sharedManager;


/** @name Linking new accounts */

/** This method begins the process for linking new accounts.

    @param rootController the topmost view controller in your controller hierarchy.
 */
- (void)linkFromController:(UIViewController *)rootController;

/** You must call this method in your app delegate's
 `-application:openURL:sourceApplication:annotation:` method in order to complete the link process.

 @returns The [account](DBAccount) object if the link was successful, or `nil` if the user
 cancelled.
 */
- (DBAccount *)handleOpenURL:(NSURL *)url;


/** @name Getting the current state */

/** The currently linked account, or `nil` if there are no accounts currently linked.

 If your app needs to link multiple accounts at the same time, you should always use the
 <linkedAccounts> property. */
@property (nonatomic, readonly) DBAccount *linkedAccount;

/** All currently linked accounts, or `nil` if there are no accounts currently linked.

 The accounts are ordered from the least recently to the most recently linked. */
@property (nonatomic, readonly) NSArray *linkedAccounts;


/** @name Watching for changes */

/** Add `block` as an observer to get called whenever a new account is linked or an existing
 account is unlinked. The observer will be called regardless of whether the account was
 unlinked using `-[DBAccount unlink]` or by the user on the Dropbox website.

 @param observer this is only used as a handle to unregister blocks with the <removeObserver:> method.
 */
- (void)addObserver:(id)observer block:(DBAccountManagerObserver)block;

/** Use this method to remove all blocks associated with `observer`.

 @param observer the same value you provided to the <addObserver:block:> method.
 */
- (void)removeObserver:(id)observer;

@end
