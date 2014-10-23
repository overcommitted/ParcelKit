Version 2.1.1
================
* Updated Dropbox-Sync-API-SDK to 3.1.1.

Version 2.1.0
================
* Updated Dropbox-Sync-API-SDK to 3.1.0.
* Fixed issue with syncPropertiesDictionary not being used when syncing from Dropbox to Core Data.
* Post notification of last sync date when sync completes.

Version 2.0.1
================
* Updated Dropbox-Sync-API-SDK to 3.0.2.

Version 2.0.0
================
* Updated Dropbox-Sync-API-SDK to 3.0.0. See the Dropbox-Sync-API-SDK Changelog for potentially breaking changes.
* Only post PKSyncManagerDatastoreIncomingChangesNotification if there were changes
* Ignore non-syncable entities

Version 1.3.0
================
* Allow a manual sync to be requested by calling [syncManager syncDatastore]
* Allow selectively syncing certain rows only
* Allow models to customise exactly what data gets synced
* Add a hook to make any modifications after a row is synced
* Only store one to many relationship on one side
* Updated Dropbox-Sync-API-SDK to 2.1.2

Version 1.2.1
================
* Updated Dropbox-Sync-API-SDK to 2.0.3

Version 1.2.0
================
* Sync Core Data changes with the datastore in batches 
* Updated Dropbox-Sync-API-SDK to 2.0.2

Version 1.1.1
================
* Post notification when sync has finished.

Version 1.1.0
================
* Added support for syncing binary data.

Version 1.0.1
================
* Updated Dropbox-Sync-API-SDK to 2.0.1.

Version 1.0.0
================
* Updated Dropbox-Sync-API-SDK to 2.0.0.

Version 1.0.0-b9
================
* Updated Dropbox-Sync-API-SDK to 2.0.0-b7. 

Version 1.0.0-b8
================
* Fix ordered relationships not updating properly.

Version 1.0.0-b7
================
* Update vendored Dropbox-Sync-API-SDK to 2.0.0-b6.

Version 1.0.0-b6
================
* Add support for ordered relationships.

Version 1.0.0-b5
================
* Update +[PKSyncManager syncID] to work with ealier versions of iOS than iOS 6.

Version 1.0.0-b4
================
* Update Dropbox Datastore SDK to 2.0.0-b5.

Version 1.0.0-b3
================
* Rename tableId to tableID.
* Update tests for Xcode DP4 compatibility.

Version 1.0.0-b2
================
* Only set changed fields on DBRecord.
* Update Dropbox Sync SDK to 2.0.0-b4.

Version 1.0.0-b1
================
* Added Podspec.

Version 1.0.0
=============
* Initial Release.