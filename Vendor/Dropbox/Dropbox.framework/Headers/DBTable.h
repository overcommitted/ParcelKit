/* Copyright (c) 2013 Dropbox, Inc. All rights reserved. */

#import "DBError.h"
#import "DBRecord.h"

@class DBDatastore;

// Enum to specify how conflicts are resolved on a field.
typedef enum {
    DBResolutionRemote, // Resolves conflicts by always taking the remote change. This is the
                        // default resolution strategy.
    DBResolutionLocal, // Resolves conflicts by always taking the local change.
    DBResolutionMax, // Resolves conflicts by taking the largest value, based on type-specific
                     // ordering (see DBTable for more information).
    DBResolutionMin, // Resolves conflicts by taking the smallest value, based on type-specific
                     // ordering (see DBTable for more information).
    DBResolutionSum  // Resolves conflicts by preserving additions or subtractions to a numerical
                     // value (integer or floating point), which allows you to treat it as a counter
                     // or accumulator without losing updates. For non-numerical values this rule
                     // behaves as DBResolutionRemote.
} DBResolutionRule;

/** A collection of [records](DBRecord) that lets you query for existing records or insert new ones. You can
 get an instance using the `getTable:` or `getTables:` methods on <DBDatastore>.
 </p><p>
 In addition to querying and inserting records, you can also set custom conflict resolution rules.
 </p><p>
 When using the max and min resolution rules, values are compared as follows: integer,
 floating point, boolean, and date values are ordered by their numerical value.  String, byte, and
 list values are lexicographically ordered. Integer and floating point values are compared to each
 other by casting to double, but boolean values are treated as a distinct type ordered before all
 other numbers.  Other values of distinct types are ordered by type, in the order listed
 above.  For example, all boolean values are ordered before all other numeric values, which in
 turn are ordered before all string values.
 */
@interface DBTable : NSObject

/** Returns `YES` if `tableId` is a valid ID for a `DBTable`, or `NO` otherwise.
  IDs are case-sensitive, can be 1-32 characters long and may contain alphanumeric
  characters plus these punctuation characters: . - _ + / =
  IDs with a leading : are valid, but reserved for internal use. */
+ (BOOL)isValidId:(NSString *)tableId;

/** Returns records matching the provided filter, or all records if filter is `nil`.

 @param filter For every key value pair in `filter`, the query will only return records where the
 field with the same name has the same value.
 */
- (NSArray *)query:(NSDictionary *)filter error:(DBError **)error;

/** Returns a record with the given `recordId`, or `nil` if that record doesn't exist or an error
 occurred. */
- (DBRecord *)getRecord:(NSString *)recordId error:(DBError **)error;

/** Returns a record with the given `recordId` (unmodified), or inserts a new record with
 the initial set of fields if it doesn't exist already.

 @param inserted if provided, the `BOOL` pointed to by inserted will be set to `YES` if a new record
 was inserted, or `NO` otherwise.

 @returns the record if it is present in the table or inserted, or `nil` if an error occurred. */
- (DBRecord *)getOrInsertRecord:(NSString *)recordId fields:(NSDictionary *)fields
inserted:(BOOL *)inserted error:(DBError **)error;

/** Insert a new record with the initial set of fields into this table with a unique record ID. */
- (DBRecord *)insert:(NSDictionary *)fields;

/** Sets pattern as the resolution pattern for conflicts involving the given fieldname.
 The new resolution rule will be applied when merging local changes with remote changes during a
 call to `-[DBDatastore sync:]`.*/
- (void)setResolutionRule:(DBResolutionRule)rule forField:(NSString *)field;

/** The ID of the table. */
@property (nonatomic, readonly) NSString *tableId;

/** The datastore that contains this table. */
@property (nonatomic, readonly) DBDatastore *datastore;

@end
