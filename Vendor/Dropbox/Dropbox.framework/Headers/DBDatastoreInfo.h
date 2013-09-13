/* Copyright (c) 2013 Dropbox, Inc. All rights reserved. */

/** The datastore info class contains basic information about a datastore.  Currently
 this only includes its ID, but more fields will be added in future. */

@interface DBDatastoreInfo : NSObject

/** The ID for this datastore. */
@property (nonatomic, readonly) NSString *datastoreId;

@end
