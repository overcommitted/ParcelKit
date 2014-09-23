#import <CoreData/CoreData.h>
#import "NSManagedObject+ParcelKit.h"

@interface Author : NSManagedObject <ParcelKitSyncedObject> {}

@property (nonatomic, retain) NSString *syncID;
@property (nonatomic, retain) NSString *name;
@property (nonatomic) double royalties;
@property (nonatomic, retain) NSString *favoriteFood;
@property (nonatomic, retain) NSSet *books;

@property (nonatomic) BOOL hasSyncCallbackBeenCalled;
@property (nonatomic) BOOL isRecordSyncable;
@end
