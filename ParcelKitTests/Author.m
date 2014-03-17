#import "Author.h"


@interface Author ()

// Private interface goes here.

@end


@implementation Author

@synthesize hasSyncCallbackBeenCalled;

- (void)parcelKitWasSyncedFromDropbox {
    self.hasSyncCallbackBeenCalled = YES;
}

- (NSDictionary*)syncedPropertiesDictionary:(NSDictionary*)propertiesByName {
    NSMutableDictionary* values = [[self dictionaryWithValuesForKeys:[propertiesByName allKeys]] mutableCopy];
    [values setObject:@"cheese" forKey:@"favourite_food"];
    return values;
}

@end
