//
//  DBRecordParcelKitTests.m
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
#import "DBRecord+ParcelKit.h"

#import "PKSyncManager.h"
#import "PKDatastoreMock.h"
#import "PKTableMock.h"
#import "PKRecordMock.h"
#import "PKListMock.h"
#import "NSManagedObjectContext+ParcelKitTests.h"

@interface DBRecordParcelKitTests : XCTestCase
@property (strong, nonatomic) PKDatastoreMock *datastore;
@property (strong, nonatomic) PKTableMock *table;
@property (strong, nonatomic) PKRecordMock *record;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObject *book;
@property (strong, nonatomic) NSManagedObject *author;
@property (strong, nonatomic) NSManagedObject *publisher;
@end

@implementation DBRecordParcelKitTests

- (void)setUp
{
    [super setUp];
    
    self.datastore = [[PKDatastoreMock alloc] init];
    self.table = [[PKTableMock alloc] initWithTableID:@"books" datastore:self.datastore];
    self.record = [[PKRecordMock alloc] initWithRecordId:@"1" fields:nil deleted:NO];
    [self.record setTable:self.table];
    
    self.managedObjectContext = [NSManagedObjectContext pk_managedObjectContextWithModelName:@"Tests"];
    
    self.book = [NSEntityDescription insertNewObjectForEntityForName:@"Book" inManagedObjectContext:self.managedObjectContext];
    [self.book setValue:@"1" forKey:PKDefaultSyncAttributeName];
    [self.book setValue:@"To Kill a Mockingbird" forKey:@"title"];
    
    self.author = [NSEntityDescription insertNewObjectForEntityForName:@"Author" inManagedObjectContext:self.managedObjectContext];
    [self.author setValue:@"1" forKey:PKDefaultSyncAttributeName];
    [self.author setValue:@"Harper Lee" forKey:@"name"];
    
    self.publisher = [NSEntityDescription insertNewObjectForEntityForName:@"Publisher" inManagedObjectContext:self.managedObjectContext];
    [self.publisher setValue:@"1" forKey:PKDefaultSyncAttributeName];
    [self.publisher setValue:@"J. B. Lippincott & Co." forKey:@"name"];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testSetFieldsWithManagedObjectShouldIgnoreSyncAttribute
{
    [self.record pk_setFieldsWithManagedObject:self.book syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertNil([self.record objectForKey:PKDefaultSyncAttributeName], @"");
}

- (void)testSetFieldsWithManagedObjectShouldIgnoreTransientAttributes
{
    [self.book setValue:@"/tmp/cover.png" forKey:@"coverPath"];
    [self.record pk_setFieldsWithManagedObject:self.book syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertNil([self.record objectForKey:@"coverPath"], @"");
}

- (void)testSetFieldsWithManagedObjectShouldSetAttribute
{
    [self.record pk_setFieldsWithManagedObject:self.book syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects([self.book valueForKey:@"title"], [self.record objectForKey:@"title"], @"");
}

- (void)testSetFieldsWithManagedObjectShouldSetBinaryDataAttributeDirectlyIfDataIsSmallEnough
{
    NSData *cover = [@"One" dataUsingEncoding:NSUTF8StringEncoding];
    [self.book setValue:cover forKey:@"cover"];
    [self.record pk_setFieldsWithManagedObject:self.book syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(cover, [self.record objectForKey:@"cover"], @"");
}

- (void)testSetFieldsWithManagedObjectShouldSplitBinaryDataAttributeIfDataIsNotSmallEnough
{
    PKTableMock *binaryTable = [[PKTableMock alloc] initWithTableID:@"books.bin" datastore:self.datastore];

    [self.book setValue:[@"OneTwoThree" dataUsingEncoding:NSUTF8StringEncoding] forKey:@"cover"];
    [self.record pk_setFieldsWithManagedObject:self.book syncAttributeName:PKDefaultSyncAttributeName];
    
    DBList *records = [self.record objectForKey:@"cover"];
    XCTAssertNotNil(records, @"");
    XCTAssertEqual(4, (int)[records count], @"");

    // For testing data is split into 3 byte chunks
    XCTAssertEqual(4, (int)[binaryTable.records count], @"");
    XCTAssertEqualObjects(@"One", [[NSString alloc] initWithData:[binaryTable getRecord:records[0] error:nil][@"data"] encoding:NSUTF8StringEncoding]);
    XCTAssertEqualObjects(@"Two", [[NSString alloc] initWithData:[binaryTable getRecord:records[1] error:nil][@"data"] encoding:NSUTF8StringEncoding]);
    XCTAssertEqualObjects(@"Thr", [[NSString alloc] initWithData:[binaryTable getRecord:records[2] error:nil][@"data"] encoding:NSUTF8StringEncoding]);
    XCTAssertEqualObjects(@"ee", [[NSString alloc] initWithData:[binaryTable getRecord:records[3] error:nil][@"data"] encoding:NSUTF8StringEncoding]);
}

- (void)testSetFieldsWithManagedObjectSettingBinaryDataShouldRemoveAnyPreviouslyChunkedBinaryDataAttribute
{
    PKTableMock *binaryTable = [[PKTableMock alloc] initWithTableID:@"books.bin" datastore:self.datastore];
    [binaryTable setRecord:[PKRecordMock record:@"1" withFields:nil]];
    [binaryTable setRecord:[PKRecordMock record:@"2" withFields:nil]];
    [binaryTable setRecord:[PKRecordMock record:@"3" withFields:nil]];
    
    DBList *list = [self.record getOrCreateList:@"cover"];
    [list addObject:@"1"];
    [list addObject:@"2"];
    [list addObject:@"3"];
    
    [self.book setValue:[@"One" dataUsingEncoding:NSUTF8StringEncoding] forKey:@"cover"];
    [self.record pk_setFieldsWithManagedObject:self.book syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqual(0, (int)[binaryTable.records count], @"");
}

- (void)testSetFieldsWithManagedObjectRemovingBinaryDataShouldRemoveAnyPreviouslyChunkedBinaryDataAttribute
{
    PKTableMock *binaryTable = [[PKTableMock alloc] initWithTableID:@"books.bin" datastore:self.datastore];
    [binaryTable setRecord:[PKRecordMock record:@"1" withFields:nil]];
    [binaryTable setRecord:[PKRecordMock record:@"2" withFields:nil]];
    [binaryTable setRecord:[PKRecordMock record:@"3" withFields:nil]];
    
    DBList *list = [self.record getOrCreateList:@"cover"];
    [list addObject:@"1"];
    [list addObject:@"2"];
    [list addObject:@"3"];
    
    [self.record pk_setFieldsWithManagedObject:self.book syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqual(0, (int)[binaryTable.records count], @"");
}

- (void)testSetFieldsWithManagedObjectShouldSetMultipleAttributes
{
    [self.book setValue:@(296) forKey:@"pageCount"];

    [self.record pk_setFieldsWithManagedObject:self.book syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects([self.book valueForKey:@"title"], [self.record objectForKey:@"title"], @"");
    XCTAssertEqualObjects([self.book valueForKey:@"pageCount"], [self.record objectForKey:@"pageCount"], @"");
}

- (void)testSetFieldsWithManagedObjectShouldOnlySetChangedAttributes
{
    [self.book setValue:@(1960) forKey:@"yearPublished"];
    
    [self.record setObject:[self.book valueForKey:@"title"] forKey:@"title"];
    [self.record setObject:@(2013) forKey:@"yearPublished"];
    
    id recordMock = [OCMockObject partialMockForObject:self.record];
    [[recordMock expect] setObject:@(1960) forKey:@"yearPublished"];
    [[recordMock reject] setObject:[self.book valueForKey:@"title"] forKey:@"title"];
    
    [self.record pk_setFieldsWithManagedObject:self.book syncAttributeName:PKDefaultSyncAttributeName];
    
    [recordMock verify];
}

- (void)testSetFieldsWithManagedObjectShouldSetToManyRelationship
{
    [self.book setValue:[NSSet setWithObject:self.author] forKey:@"authors"];
    
    [self.record pk_setFieldsWithManagedObject:self.book syncAttributeName:PKDefaultSyncAttributeName];
    
    NSArray *authors = [[self.record getOrCreateList:@"authors"] values];
    XCTAssertNotNil(authors, @"");
    XCTAssertEqual(1, (int)[authors count], @"");
    XCTAssertTrue([authors containsObject:[self.author valueForKey:PKDefaultSyncAttributeName]], @"");
}

- (void)testSetFieldsWithManagedObjectShouldSetOrderedToManyRelationship
{
    NSMutableArray *identifiers = [[NSMutableArray alloc] init];
    for (int i = 0; i < 10; i++) {
        NSManagedObject *book = [NSEntityDescription insertNewObjectForEntityForName:@"Book" inManagedObjectContext:self.managedObjectContext];
        NSString *identifier = [NSString stringWithFormat:@"%i", i + 100];
        [book setValue:identifier forKey:PKDefaultSyncAttributeName];
        [book setValue:[NSSet setWithObject:self.author] forKey:@"authors"];
        
        if (i % 2) {
            [identifiers addObject:identifier];
        }
    }
    
    NSArray *unsortedIdentifiers = [[identifiers reverseObjectEnumerator] allObjects];
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"books": [[PKListMock alloc] initWithValues:unsortedIdentifiers]}];
    [record pk_setFieldsWithManagedObject:self.author syncAttributeName:PKDefaultSyncAttributeName];
    
    NSArray *books = [[record getOrCreateList:@"books"] values];
    XCTAssertNotNil(books, @"");
    XCTAssertEqual(10, (int)[books count], @"");

    [[self.author valueForKey:@"books"] enumerateObjectsUsingBlock:^(NSManagedObject *book, NSUInteger idx, BOOL *stop) {
        NSString *identifier = [books objectAtIndex:idx];
        XCTAssertEqualObjects([book valueForKey:PKDefaultSyncAttributeName], identifier, @"");
    }];
}

- (void)testSetFieldsWithManagedObjectShouldSetToManyMultipleRelationships
{
    NSManagedObject *anotherAuthor = [NSEntityDescription insertNewObjectForEntityForName:@"Author" inManagedObjectContext:self.managedObjectContext];
    [anotherAuthor setValue:@"2" forKey:PKDefaultSyncAttributeName];

    [self.book setValue:[NSSet setWithObjects:self.author, anotherAuthor, nil] forKey:@"authors"];
    
    [self.record pk_setFieldsWithManagedObject:self.book syncAttributeName:PKDefaultSyncAttributeName];
    
    NSArray *authors = [[self.record getOrCreateList:@"authors"] values];
    XCTAssertNotNil(authors, @"");
    XCTAssertEqual(2, (int)[authors count], @"");
    XCTAssertTrue([authors containsObject:[self.author valueForKey:PKDefaultSyncAttributeName]], @"");
    XCTAssertTrue([authors containsObject:[anotherAuthor valueForKey:PKDefaultSyncAttributeName]], @"");
}

- (void)testSetFieldsWithManagedObjectShouldRemoveObjectsInToManyRelationship
{
    [self.book setValue:[NSSet setWithObject:self.author] forKey:@"authors"];
    
    DBList *authorsList = [self.record getOrCreateList:@"authors"];
    [authorsList addObject:@"1"];
    [authorsList addObject:@"2"];
    
    [self.record pk_setFieldsWithManagedObject:self.book syncAttributeName:PKDefaultSyncAttributeName];
    
    NSArray *authors = [authorsList values];
    XCTAssertNotNil(authors, @"");
    XCTAssertEqual(1, (int)[authors count], @"");
    XCTAssertTrue([authors containsObject:[self.author valueForKey:PKDefaultSyncAttributeName]], @"");
}

- (void)testSetFieldsWithManagedObjectShouldRemoveObjectsInOrderedToManyRelationship
{
    NSMutableArray *identifiers = [[NSMutableArray alloc] init];
    for (int i = 0; i < 3; i++) {
        NSManagedObject *book = [NSEntityDescription insertNewObjectForEntityForName:@"Book" inManagedObjectContext:self.managedObjectContext];
        NSString *identifier = [NSString stringWithFormat:@"%i", i + 100];
        [book setValue:identifier forKey:PKDefaultSyncAttributeName];
        [book setValue:[NSSet setWithObject:self.author] forKey:@"authors"];
        [identifiers addObject:identifier];
    }
    
    NSArray *unsortedIdentifiers = [[[identifiers reverseObjectEnumerator] allObjects] arrayByAddingObjectsFromArray:@[@"should-delete-1", @"should-delete-2"]];
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"books": [[PKListMock alloc] initWithValues:unsortedIdentifiers]}];
    [record pk_setFieldsWithManagedObject:self.author syncAttributeName:PKDefaultSyncAttributeName];
    
    NSArray *books = [[record getOrCreateList:@"books"] values];
    XCTAssertNotNil(books, @"");
    XCTAssertEqual(3, (int)[books count], @"");
    
    [[self.author valueForKey:@"books"] enumerateObjectsUsingBlock:^(NSManagedObject *book, NSUInteger idx, BOOL *stop) {
        NSString *identifier = [books objectAtIndex:idx];
        XCTAssertEqualObjects([book valueForKey:PKDefaultSyncAttributeName], identifier, @"");
    }];
}

- (void)testSetFieldsWithManagedObjectShouldSetToOneRelationship
{
    [self.book setValue:self.publisher forKey:@"publisher"];
    [self.record pk_setFieldsWithManagedObject:self.book syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects([self.publisher valueForKey:PKDefaultSyncAttributeName], [self.record objectForKey:@"publisher"], @"");
}

- (void)testSetFieldsWithManagedObjectShouldRemoveToOneRelationship
{
    [self.record setObject:@"1" forKey:@"publisher"];

    [self.book setValue:self.publisher forKey:@"publisher"];
    [self.managedObjectContext save:nil];
    [self.book setValue:nil forKey:@"publisher"];
    
    [self.record pk_setFieldsWithManagedObject:self.book syncAttributeName:PKDefaultSyncAttributeName];
    
   
    XCTAssertFalse([[[self.record fields] allKeys] containsObject:@"publisher"], @"");
}

@end
