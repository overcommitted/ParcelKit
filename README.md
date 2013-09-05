<img src="https://raw.github.com/overcommitted/ParcelKit/master/ParcelKitLogo.png" width="89px" height="109px" />

ParcelKit
=========
ParcelKit integrates Core Data with [Dropbox](http://www.dropbox.com) using the Dropbox [Datastore API](https://www.dropbox.com/developers/datastore).

Installation
------------
ParcelKit can be added to a project using [CocoaPods](https://github.com/cocoapods/cocoapods). We also distribute a framework build.

### Using CocoaPods

```
// Podfile
pod 'ParcelKit'
```
and
```
pod install
```

### Framework
1. Open the ParcelKit.xcodeproj project
2. Select the “Framework” scheme
3. Build (⌘B) the Framework
4. Open the Products section in Xcode, right click “libParcelKit.a”, and select “Show in Finder”
5. Drag and drop the “ParcelKit.framework” folder into your iPhone/iPad project
6. Edit your build settings and add `-ObjC` to “Other Linker Flags”

Usage
-----
Include ParcelKit in your application.

    #import <ParcelKit/ParcelKit.h>

Initialize an instance of the ParcelKit sync manager with the Core Data managed object context and the Dropbox data store that
should be used for listening for changes from and writing changes to.
    
    PKSyncManager *syncManager = [[PKSyncManager alloc] initWithManagedObjectContext:self.managedObjectContext datastore:self.datastore];
        
Associate the Core Data entity names with the corresponding Dropbox data store tables.  

    [syncManager setTable:@"books" forEntityName:@"Book"];
    
Start observing changes from Core Data and Dropbox.

    [syncManager startObserving];
    
Hold on to the sync manager reference.
    
    self.syncManager = syncManager;


Set up Core Data
----------------
<img src="https://raw.github.com/overcommitted/ParcelKit/master/ParcelKitAttribute.png" align="right" width="725px" height="132px" />

ParcelKit requires an extra attribute inside your Core Data model. 

* __syncID__ with the type __String__. The __Indexed__ property should also be checked.

Make sure you add this attribute to each entity you wish to sync.

An alternative attribute name may be specifed by changing the syncAttributeName property on the sync manager object.

Documentation
-------------
* [ParcelKit Reference](http://overcommitted.github.io/ParcelKit/) documentation

Example Application
-------------------
* [Toado](https://github.com/daikini/toado) - Simple task manager demonstrating the integration of Core Data and Dropbox using ParcelKit.

    
ToDo
----
* Add support for the NSData attribute type

Requirements
------------
* iOS 6.1 or higher
* Dropbox Sync SDK 2.0.0-b3 or higher
* Xcode 4.6 or higher for building the framework
* Xcode 5 Developer Preview 4 or higher for running the included logic tests

License
-------
[MIT](https://github.com/overcommitted/ParcelKit/blob/master/LICENSE).
