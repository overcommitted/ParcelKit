#import "_Author.h"
#import "NSManagedObject+ParcelKit.h"

@interface Author : _Author <ParcelKitSyncedObject> {}

@property (nonatomic) BOOL hasSyncCallbackBeenCalled;

@end
