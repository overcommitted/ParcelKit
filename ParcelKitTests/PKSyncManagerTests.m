//
//  PKSyncManagerTests.m
//  ParcelKit
//
//  Copyright (c) 2013 Overcommitted, LLC. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "NSManagedObjectContext+ParcelKitTests.h"
#import "PKSyncManager.h"
#import "PKDatastoreMock.h"
#import "PKTableMock.h"
#import "PKRecordMock.h"
#import "Author.h"

@interface PKSyncManager (ParcelKitTests)
- (void)updateCoreDataWithDatastoreChanges:(NSDictionary *)changes;
@end

@interface PKSyncManagerTests : XCTestCase
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) id datastore;
@property (strong, nonatomic) PKSyncManager *syncManager;
@end

@implementation PKSyncManagerTests

- (void)setUp
{
    [super setUp];
    
    self.managedObjectContext = [NSManagedObjectContext pk_managedObjectContextWithModelName:@"Tests"];
    self.datastore = [OCMockObject partialMockForObject:[[PKDatastoreMock alloc] init]];
    self.syncManager = [[PKSyncManager alloc] initWithManagedObjectContext:self.managedObjectContext datastore:self.datastore];
    [self.syncManager setTablesForEntityNamesWithDictionary:@{@"Book": @"books", @"Author": @"authors"}];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

#pragma mark - Sync Manager Setup

- (void)testSyncIdShouldReturnAString
{
    NSString *syncID = [PKSyncManager syncID];
    XCTAssertNotNil(syncID, @"syncID should not be nil");
    XCTAssertTrue([syncID isKindOfClass:[NSString class]], @"syncID should be a string");
}

- (void)testSyncIdShouldBeAtLeastOneCharacter
{
    NSString *syncID = [PKSyncManager syncID];
    XCTAssertTrue([syncID length] > 0, @"syncID should be at least 1 character");
}

- (void)testSyncIdShouldBeLessThanThirtyTwoCharacters
{
    NSString *syncID = [PKSyncManager syncID];
    XCTAssertTrue([syncID length] <= 32, @"syncID should be less than or equal to 32 characters");
}

- (void)testSyncIdShouldBeRandom
{
    NSString *syncIDA = [PKSyncManager syncID];
    NSString *syncIDB = [PKSyncManager syncID];
    XCTAssertFalse([syncIDA isEqualToString:syncIDB], @"syncID should be random");
}

- (void)testInitializingManagedObjectContextAndDatastore
{
    PKSyncManager *syncManager = [[PKSyncManager alloc] initWithManagedObjectContext:self.managedObjectContext datastore:self.datastore];
    XCTAssertEqualObjects(self.managedObjectContext, syncManager.managedObjectContext, @"managedObjectContext should be initialized");
    XCTAssertEqualObjects(self.datastore, syncManager.datastore, @"datastore should be initialized");
}

- (void)testSyncAttributeNameShouldReturnDefaultValue
{
    PKSyncManager *syncManager = [[PKSyncManager alloc] init];
    XCTAssertEqualObjects(@"syncID", syncManager.syncAttributeName, @"");
}

- (void)testSettingSyncAttributeNameShouldSetSpecifiedValue
{
    PKSyncManager *syncManager = [[PKSyncManager alloc] initWithManagedObjectContext:self.managedObjectContext datastore:self.datastore];
    syncManager.syncAttributeName = @"sinkID";
     XCTAssertEqualObjects(@"sinkID", syncManager.syncAttributeName, @"");
}

- (void)testSetTablesForEntityNamesWithDictionaryShouldSetSpecifiedRelationships
{
    PKSyncManager *syncManager = [[PKSyncManager alloc] initWithManagedObjectContext:self.managedObjectContext datastore:self.datastore];
    NSDictionary *tablesByEntityName = @{@"Book": @"books", @"Author": @"authors"};
    [syncManager setTablesForEntityNamesWithDictionary:tablesByEntityName];
    XCTAssertEqualObjects(tablesByEntityName, [syncManager tablesByEntityName], @"");
}

- (void)testSetTablesForEntityNamesWithDictionaryShouldRemoveExistingRelationships
{
    PKSyncManager *syncManager = [[PKSyncManager alloc] initWithManagedObjectContext:self.managedObjectContext datastore:self.datastore];
    [syncManager setTablesForEntityNamesWithDictionary:@{@"Book": @"books"}];
    
    NSDictionary *tablesByEntityName = @{@"Author": @"authors"};
    [syncManager setTablesForEntityNamesWithDictionary:tablesByEntityName];
    XCTAssertEqualObjects(tablesByEntityName, [syncManager tablesByEntityName], @"");
}

- (void)testSetTableForEntityNameShouldSetSpecifiedRelationship
{
    PKSyncManager *syncManager = [[PKSyncManager alloc] initWithManagedObjectContext:self.managedObjectContext datastore:self.datastore];
    [syncManager setTable:@"books" forEntityName:@"Book"];
    XCTAssertEqualObjects(@{@"Book": @"books"}, [syncManager tablesByEntityName], @"");
}

- (void)testSetTableForEntityNameShouldReplaceExistingRelationship
{
    PKSyncManager *syncManager = [[PKSyncManager alloc] initWithManagedObjectContext:self.managedObjectContext datastore:self.datastore];
    [syncManager setTable:@"books" forEntityName:@"Book"];
    [syncManager setTable:@"Book" forEntityName:@"Book"];
    XCTAssertEqualObjects(@{@"Book": @"Book"}, [syncManager tablesByEntityName], @"");
}

- (void)testSetTableForEntityNameShouldRaiseExceptionIfEntityDoesNotContainSyncAttribute
{
    PKSyncManager *syncManager = [[PKSyncManager alloc] initWithManagedObjectContext:self.managedObjectContext datastore:self.datastore];
    syncManager.syncAttributeName = @"non-existent";
    XCTAssertThrowsSpecificNamed([syncManager setTable:@"books" forEntityName:@"Book"], NSException, NSInternalInconsistencyException, @"");
}

- (void)testSetTableForEntityNameShouldRaiseExceptionIfEntitySyncAttributeTypeIsNotAString
{
    PKSyncManager *syncManager = [[PKSyncManager alloc] initWithManagedObjectContext:self.managedObjectContext datastore:self.datastore];
    syncManager.syncAttributeName = @"pageCount";
    XCTAssertThrowsSpecificNamed([syncManager setTable:@"books" forEntityName:@"Book"], NSException, NSInternalInconsistencyException, @"");
}

- (void)testRemoveTableForEntityNameShouldRemoveSpecifiedRelationship
{
    PKSyncManager *syncManager = [[PKSyncManager alloc] initWithManagedObjectContext:self.managedObjectContext datastore:self.datastore];
    [syncManager setTable:@"books" forEntityName:@"Book"];
    [syncManager removeTableForEntityName:@"Book"];
    XCTAssertEqualObjects(@{}, [syncManager tablesByEntityName], @"");
}

- (void)testTableIDsShouldReturnSpecifiedTableIDs
{
    NSArray *tableIDs = [self.syncManager tableIDs];
    XCTAssertEqual(2, (int)[tableIDs count], @"");
    XCTAssertTrue([tableIDs containsObject:@"books"], @"");
    XCTAssertTrue([tableIDs containsObject:@"authors"], @"");
}

- (void)testEntityNamesShouldReturnSpecifiedEntityNames
{
    NSArray *entityNames = [self.syncManager entityNames];
    XCTAssertEqual(2, (int)[entityNames count], @"");
    XCTAssertTrue([entityNames containsObject:@"Book"], @"");
    XCTAssertTrue([entityNames containsObject:@"Author"], @"");
}

- (void)testTableForEntityNameShouldReturnRelatedTableForEntityName
{
    XCTAssertEqualObjects(@"books", [self.syncManager tableForEntityName:@"Book"], @"");
    XCTAssertEqualObjects(@"authors", [self.syncManager tableForEntityName:@"Author"], @"");
}

- (void)testEntityNameForTableShouldReturnRelatedEntityNameForTable
{
    XCTAssertEqualObjects(@"Book", [self.syncManager entityNameForTable:@"books"], @"");
    XCTAssertEqualObjects(@"Author", [self.syncManager entityNameForTable:@"authors"], @"");
}

#pragma mark - Observing Setup

- (void)testIsObservingShouldReturnTrueWhenObservingStarted
{
    XCTAssertFalse([self.syncManager isObserving], @"");
    [self.syncManager startObserving];
    XCTAssertTrue([self.syncManager isObserving], @"");
}

- (void)testIsObservingShouldReturnFalseWhenObservingStopped
{
    [self.syncManager startObserving];
    
    [self.syncManager stopObserving];
    XCTAssertFalse([self.syncManager isObserving], @"");
}

- (void)testStartObservingShouldObserveDatastore
{
    [(DBDatastore *)[self.datastore expect] addObserver:self.syncManager block:[OCMArg isNotNil]];
    [self.syncManager startObserving];
    [self.datastore verify];
}

- (void)testStartObservingShouldObserveManagedObjectContext
{
    id mockNotificationCenter = [OCMockObject niceMockForClass:[NSNotificationCenter class]];
    [[mockNotificationCenter expect] addObserver:self.syncManager selector:[OCMArg anySelector] name:NSManagedObjectContextWillSaveNotification object:self.syncManager.managedObjectContext];
    
    id mockNotificationCenterClass = [OCMockObject mockForClass:[NSNotificationCenter class]];
    [[[mockNotificationCenterClass expect] andReturn:mockNotificationCenter] defaultCenter];
    
    [self.syncManager startObserving];
    
    [mockNotificationCenter verify];
    [mockNotificationCenterClass stopMocking];
}

#pragma mark - Observe Datastore Changes

- (void)testIncomingDatastoreChangeShouldUpdateCoreDataWithSingleObject
{
    [self.syncManager startObserving];
    
    PKRecordMock *book = [PKRecordMock record:@"1" withFields:@{@"title": @"To Kill a Mockingbird"}];
    [self.datastore updateStatus:DBDatastoreIncoming withChanges:@{@"books": @[book]}];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Book"];
    NSArray *objects = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    XCTAssertEqual(1, (int)[objects count], @"");
    
    NSManagedObject *object = objects[0];
    XCTAssertEqualObjects(@"1", [object valueForKey:self.syncManager.syncAttributeName], @"");
    XCTAssertEqualObjects(@"To Kill a Mockingbird", [object valueForKey:@"title"], @"");
}

- (void)testIncomingDatastoreChangeShouldUpdateCoreDataWithMultipleObjects
{
    [self.syncManager startObserving];
    
    PKRecordMock *bookA = [PKRecordMock record:@"1" withFields:@{@"title": @"To Kill a Mockingbird"}];
    PKRecordMock *bookB = [PKRecordMock record:@"2" withFields:@{@"title": @"The Grapes of Wrath"}];
    [self.datastore updateStatus:DBDatastoreIncoming withChanges:@{@"books": @[bookA, bookB]}];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Book"];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"syncID" ascending:YES]]];
    NSArray *objects = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    XCTAssertEqual(2, (int)[objects count], @"");
    
    NSManagedObject *objectA = objects[0];
    XCTAssertEqualObjects(@"1", [objectA valueForKey:self.syncManager.syncAttributeName], @"");
    XCTAssertEqualObjects(@"To Kill a Mockingbird", [objectA valueForKey:@"title"], @"");
    
    NSManagedObject *objectB = objects[1];
    XCTAssertEqualObjects(@"2", [objectB valueForKey:self.syncManager.syncAttributeName], @"");
    XCTAssertEqualObjects(@"The Grapes of Wrath", [objectB valueForKey:@"title"], @"");
}

- (void)testIncomingDatastoreChangeShouldUpdateCoreDataWithUpdatedObject
{
    NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"Book" inManagedObjectContext:self.managedObjectContext];
    [object setValue:@"1" forKey:self.syncManager.syncAttributeName];
    [object setValue:@"To Kill a Mockingbird" forKey:@"title"];
    XCTAssertTrue([self.managedObjectContext save:nil], @"");
    
    [self.syncManager startObserving];
    
    PKRecordMock *book = [PKRecordMock record:@"1" withFields:@{@"title": @"To Kill a Mockingbird Part 2: Birdy's Revenge"}];
    [self.datastore updateStatus:DBDatastoreIncoming withChanges:@{@"books": @[book]}];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Book"];
    NSArray *objects = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    XCTAssertEqual(1, (int)[objects count], @"");
    
    NSManagedObject *updatedObject = objects[0];
    XCTAssertEqualObjects(@"1", [updatedObject valueForKey:self.syncManager.syncAttributeName], @"");
    XCTAssertEqualObjects(@"To Kill a Mockingbird Part 2: Birdy's Revenge", [updatedObject valueForKey:@"title"], @"");
}

- (void)testIncomingDatastoreChangeShouldUpdateCoreDataWithDeletedObject
{
    NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"Book" inManagedObjectContext:self.managedObjectContext];
    [object setValue:@"1" forKey:self.syncManager.syncAttributeName];
    [object setValue:@"To Kill a Mockingbird" forKey:@"title"];
    XCTAssertTrue([self.managedObjectContext save:nil], @"");
    
    [self.syncManager startObserving];
    
    PKRecordMock *book = [PKRecordMock record:@"1" withFields:nil deleted:YES];
    [self.datastore updateStatus:DBDatastoreIncoming withChanges:@{@"books": @[book]}];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Book"];
    NSArray *objects = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    XCTAssertEqual(0, (int)[objects count], @"");
}

- (void)testNonIncomingDatastoreChangesShouldNotUpdateCoreData
{
    [self.syncManager startObserving];
    
    PKRecordMock *book = [PKRecordMock record:@"1" withFields:@{@"title": @"To Kill a Mockingbird"}];
    [self.datastore updateStatus:(DBDatastoreConnected | DBDatastoreDownloading | DBDatastoreUploading | DBDatastoreOutgoing) withChanges:@{@"books": @[book]}];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Book"];
    NSArray *objects = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    XCTAssertEqual(0, (int)[objects count], @"");
}

#pragma mark - Observe Core Data Changes

- (void)testCoreDataInsertShouldUpdateDatastoreWithSingleObject
{
    [self.syncManager startObserving];
    
    NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"Book" inManagedObjectContext:self.managedObjectContext];
    [object setValue:@"1" forKey:self.syncManager.syncAttributeName];
    [object setValue:@"To Kill a Mockingbird" forKey:@"title"];
    XCTAssertTrue([self.managedObjectContext save:nil], @"");
    
    DBTable *table = [self.datastore getTable:@"books"];
    XCTAssertNotNil(table, @"");
    
    DBRecord *record = [table getRecord:@"1" error:nil];
    XCTAssertNotNil(record, @"");
    XCTAssertEqualObjects(@"1", record.recordId, @"");
    XCTAssertEqualObjects(@"To Kill a Mockingbird", [record objectForKey:@"title"], @"");
}

- (void)testCoreDataInsertShouldUpdateDatastoreWithMultipleObjects
{
    [self.syncManager startObserving];
    
    NSManagedObject *objectA = [NSEntityDescription insertNewObjectForEntityForName:@"Book" inManagedObjectContext:self.managedObjectContext];
    [objectA setValue:@"1" forKey:self.syncManager.syncAttributeName];
    [objectA setValue:@"To Kill a Mockingbird" forKey:@"title"];
    
    NSManagedObject *objectB = [NSEntityDescription insertNewObjectForEntityForName:@"Book" inManagedObjectContext:self.managedObjectContext];
    [objectB setValue:@"2" forKey:self.syncManager.syncAttributeName];
    [objectB setValue:@"The Grapes of Wrath" forKey:@"title"];
    
    XCTAssertTrue([self.managedObjectContext save:nil], @"");
    
    DBTable *table = [self.datastore getTable:@"books"];
    XCTAssertNotNil(table, @"");
    
    DBRecord *recordA = [table getRecord:@"1" error:nil];
    XCTAssertNotNil(recordA, @"");
    XCTAssertEqualObjects(@"1", recordA.recordId, @"");
    XCTAssertEqualObjects(@"To Kill a Mockingbird", [recordA objectForKey:@"title"], @"");
    
    DBRecord *recordB = [table getRecord:@"2" error:nil];
    XCTAssertNotNil(recordB, @"");
    XCTAssertEqualObjects(@"2", recordB.recordId, @"");
    XCTAssertEqualObjects(@"The Grapes of Wrath", [recordB objectForKey:@"title"], @"");
}

- (void)testCoreDataUpdateShouldUpdateDatastoreWithUpdatedObject
{
    [self.syncManager startObserving];
    
    NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"Book" inManagedObjectContext:self.managedObjectContext];
    [object setValue:@"1" forKey:self.syncManager.syncAttributeName];
    [object setValue:@"To Kill a Mockingbird" forKey:@"title"];
    XCTAssertTrue([self.managedObjectContext save:nil], @"");
    
    [object setValue:@"To Kill a Mockingbird Part 2: Birdy's Revenge" forKey:@"title"];
    XCTAssertTrue([self.managedObjectContext save:nil], @"");
    
    DBTable *table = [self.datastore getTable:@"books"];
    XCTAssertNotNil(table, @"");
    
    DBRecord *record = [table getRecord:@"1" error:nil];
    XCTAssertNotNil(record, @"");
    XCTAssertEqualObjects(@"1", record.recordId, @"");
    XCTAssertEqualObjects(@"To Kill a Mockingbird Part 2: Birdy's Revenge", [record objectForKey:@"title"], @"");
}

- (void)testCoreDataUpdateShouldNotUpdateDatastoreWithUpdatedUnsyncableObject
{
    [self.syncManager startObserving];
    
    Author *object = [Author insertInManagedObjectContext:self.managedObjectContext];
    [object setValue:@"1" forKey:self.syncManager.syncAttributeName];
    [object setValue:@"Harper Lee" forKey:@"name"];
    object.isRecordSyncable = NO;
    XCTAssertTrue([self.managedObjectContext save:nil], @"");
    
    DBTable *table = [self.datastore getTable:@"authors"];
    XCTAssertNotNil(table, @"");
    
    DBRecord *record = [table getRecord:@"1" error:nil];
    XCTAssertNil(record, @"");
}

- (void)testCoreDataDeleteShouldUpdateDatastoreWithDeletedObject
{
    [self.syncManager startObserving];
    
    NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"Book" inManagedObjectContext:self.managedObjectContext];
    [object setValue:@"1" forKey:self.syncManager.syncAttributeName];
    [object setValue:@"To Kill a Mockingbird" forKey:@"title"];
    XCTAssertTrue([self.managedObjectContext save:nil], @"");
    
    [self.managedObjectContext deleteObject:object];
    XCTAssertTrue([self.managedObjectContext save:nil], @"");
    
    DBTable *table = [self.datastore getTable:@"books"];
    XCTAssertNotNil(table, @"");
    
    DBRecord *record = [table getRecord:@"1" error:nil];
    XCTAssertNil(record, @"");
}

- (void)testCoreDataDeleteShouldNotUpdateDatastoreWithDeletedUnsycableObject
{
    [self.syncManager startObserving];
    
    Author *object = [Author insertInManagedObjectContext:self.managedObjectContext];
    [object setValue:@"1" forKey:self.syncManager.syncAttributeName];
    [object setValue:@"Harper Lee" forKey:@"name"];
    XCTAssertTrue([self.managedObjectContext save:nil], @"");
    
    object.isRecordSyncable = NO;
    [self.managedObjectContext deleteObject:object];
    XCTAssertTrue([self.managedObjectContext save:nil], @"");
    
    DBTable *table = [self.datastore getTable:@"authors"];
    XCTAssertNotNil(table, @"");
    
    DBRecord *record = [table getRecord:@"1" error:nil];
    XCTAssertNotNil(record, @"");
    XCTAssertEqualObjects(@"Harper Lee", [record objectForKey:@"name"], @"");
}

- (void)testCoreDataInsertWithoutSyncAttributeSpecifiedShouldAddSyncAttribute
{
    [self.syncManager startObserving];
    
    NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"Book" inManagedObjectContext:self.managedObjectContext];
    [object setValue:@"Treasure Island" forKey:@"title"];
    XCTAssertTrue([self.managedObjectContext save:nil], @"");
    XCTAssertNotNil([object valueForKey:self.syncManager.syncAttributeName], @"");
}

- (void)testCoreDataUpdateWithoutSyncAttributeSpecifiedShouldAddSyncAttribute
{
    NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"Book" inManagedObjectContext:self.managedObjectContext];
    [object setValue:@"Treasure Island" forKey:@"title"];
    XCTAssertTrue([self.managedObjectContext save:nil], @"");
    XCTAssertNil([object valueForKey:self.syncManager.syncAttributeName], @"");
    
    [self.syncManager startObserving];
    
    [object setValue:@"Return to Treasure Island" forKey:@"title"];
    XCTAssertTrue([self.managedObjectContext save:nil], @"");
    XCTAssertNotNil([object valueForKey:self.syncManager.syncAttributeName], @"");
}
@end
