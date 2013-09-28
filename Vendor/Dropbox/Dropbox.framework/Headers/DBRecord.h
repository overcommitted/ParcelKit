/* Copyright (c) 2013 Dropbox, Inc. All rights reserved. */

#import "DBError.h"

@class DBTable, DBList;

/** A record represents an entry in a particular table and datastore. A record has a unique ID, and
 contains a set of fields, each of which has a name and a value. You can get records from a
 <DBTable> object.
 <p>
 Fields can hold values of the following types: NSNumber, NSString, NSData, NSDate, NSArray.
 For objects of type NSNumber, the value of <code>objCType</code> is not guaranteed to be preserved,
 but the datastore will distinguish been boolean, integer, and floating-point values.  When you get
 a field that has a list value, its type will be DBList, which allows you to perform conflict-free
 list mutations.
 </p><p>
 Changes to this record are immediately visible to other record objects with the same
 <code>tableId</code> and <code>recordId</code> Calling <code>-[DBDatastore sync:]</code>, which
 incorporates remote changes into your datastore, will also update any records you have a
 reference to.
 </p>
 */
@interface DBRecord : NSObject

/** Returns `YES` if `recordId` is a valid ID for a `DBRecord`, or `NO` otherwise.
 IDs are case-sensitive, can be 1-32 characters long and may contain alphanumeric
 characters plus these punctuation characters: . - _ + / =
 IDs with a leading : are valid, but reserved for internal use. */
+ (BOOL)isValidId:(NSString *)recordId;

/** Returns `YES` if `name` is a valid name for a field in a `DBRecord`, or `NO` otherwise.
 Names are case-sensitive, can be 1-32 characters long and may contain alphanumeric
 characters plus these punctuation characters: . - _ + / =
 Names with a leading : are valid, but reserved for internal use. */
+ (BOOL)isValidFieldName:(NSString *)name;

/** The id of the record. */
@property (nonatomic, readonly) NSString *recordId;

/** The table that contains this record. */
@property (nonatomic, readonly) DBTable *table;

/** The fields of this record. */
@property (nonatomic, readonly) NSDictionary *fields;

/** Get the value of a single field. */
- (id)objectForKey:(NSString *)key;

- (id)objectForKeyedSubscript:(id)key;

/** Returns the current list at the given field, or returns an empty [list](DBList) if no value
 is set. If the field has a non-list value, this method will return `nil`.

 Please note that if the empty list is returned, the list won't appear in the record until
 you insert an element. If you don't insert any elements, the field will remain unset. */
- (DBList *)getOrCreateList:(NSString *)fieldName;

/** Update all the fields in the provided dictionary with the values that they map to. */
- (void)update:(NSDictionary *)fieldsToUpdate;

/** Update a single field with the provided value.  The value must be non-nil. */
- (void)setObject:(id)obj forKey:(NSString *)fieldName;

- (void)setObject:(id)value forKeyedSubscript:(id)key;

/* Remove a single field from the record. */
- (void)removeObjectForKey:(NSString *)fieldName;

/** Delete this record. This method has no effect on records which have already been deleted. */
- (void)deleteRecord;

/** Whether this record is deleted. */
@property (nonatomic, readonly, getter=isDeleted) BOOL deleted;

@end
