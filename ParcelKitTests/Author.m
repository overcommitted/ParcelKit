#import "Author.h"


@interface Author ()

// Private interface goes here.

@end


@implementation Author

@synthesize hasSyncCallbackBeenCalled;

- (void)parcelKitWasSyncedFromDropbox {
    self.hasSyncCallbackBeenCalled = YES;
}

@end
