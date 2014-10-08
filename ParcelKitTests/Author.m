#import "Author.h"

@implementation Author
@dynamic syncID;
@dynamic name;
@dynamic royalties;
@dynamic favoriteFood;
@dynamic books;

@synthesize hasSyncCallbackBeenCalled;
@synthesize isRecordSyncable;

- (instancetype)initWithEntity:(NSEntityDescription *)entity insertIntoManagedObjectContext:(NSManagedObjectContext *)context {
    if (self = [super initWithEntity:entity insertIntoManagedObjectContext:context]) {
        self.isRecordSyncable = YES;
    }
    return self;
}

- (void)parcelKitWasSyncedFromDropbox {
    self.hasSyncCallbackBeenCalled = YES;
}

- (NSDictionary *)syncedPropertiesDictionary:(NSDictionary *)propertiesByName {
    NSMutableDictionary *values = [[self dictionaryWithValuesForKeys:[propertiesByName allKeys]] mutableCopy];
    [values removeObjectForKey:@"royalties"];
    [values setObject:@"cheese" forKey:@"favoriteFood"];
    return values;
}

@end
