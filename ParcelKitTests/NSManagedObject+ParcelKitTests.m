//
//  NSManagedObjectParcelKitTests.m
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

#import "PKSyncManager.h"
#import "NSManagedObject+ParcelKit.h"
#import "NSManagedObjectContext+ParcelKitTests.h"
#import "PKDatastoreMock.h"
#import "PKTableMock.h"
#import "PKRecordMock.h"
#import "PKListMock.h"
#import "Author.h"

@interface NSManagedObjectParcelKitTests : XCTestCase
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObject *book;
@property (strong, nonatomic) Author *author;
@property (strong, nonatomic) NSManagedObject *publisher;
@end

@implementation NSManagedObjectParcelKitTests

- (void)setUp
{
    [super setUp];
    
    self.managedObjectContext = [NSManagedObjectContext pk_managedObjectContextWithModelName:@"Tests"];
    
    self.book = [NSEntityDescription insertNewObjectForEntityForName:@"Book" inManagedObjectContext:self.managedObjectContext];
    [self.book setValue:@"1" forKey:PKDefaultSyncAttributeName];
    [self.book setValue:@"To Kill a Mockingbird" forKey:@"title"];
    
    self.author = [Author insertInManagedObjectContext:self.managedObjectContext];
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

- (void)testSetPropertiesWithRecordShouldIgnoreSyncAttribute
{
    PKRecordMock *record = [PKRecordMock record:@"123" withFields:@{PKDefaultSyncAttributeName: @"123"}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@"1", [self.book valueForKey:PKDefaultSyncAttributeName], @"");
}

- (void)testSetPropertiesWithRecordShouldIgnoreTransientAttributes
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"coverPath": @"/tmp/cover.png"}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertNil([self.book valueForKey:@"coverPath"], @"");
}

- (void)testSetPropertiesWithRecordShouldIgnoreUnknownAttributes
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"publisherAddress": @"10 East 53rd Street, New York, NY 10022"}];
    XCTAssertNoThrow([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfRequiredAttributeHasNoValue
{
    [self.book setValue:nil forKey:@"title"];

    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{}];
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldSetStringAttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"title": @"To Kill a Mockingbird Part 2: Birdy's Revenge"}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@"To Kill a Mockingbird Part 2: Birdy's Revenge", [self.book valueForKey:@"title"], @"");
}

- (void)testSetPropertiesWithRecordShouldConvertStringAttributeTypeIfNotString
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"title": @(42)}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@"42", [self.book valueForKey:@"title"], @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfCannotConvertStringAttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"title": [NSDate date]}];
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldSetInteger16AttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"yearPublished": @(1960)}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(1960), [self.book valueForKey:@"yearPublished"], @"");
}

- (void)testSetPropertiesWithRecordShouldConvertInteger16AttributeTypeIfNotNumber
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"yearPublished": @"1960"}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(1960), [self.book valueForKey:@"yearPublished"], @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfCannotConvertInteger16AttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"yearPublished": [NSDate date]}];
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldSetInteger32AttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"pageCount": @(296)}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(296), [self.book valueForKey:@"pageCount"], @"");
}

- (void)testSetPropertiesWithRecordShouldConvertInteger32AttributeTypeIfNotNumber
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"pageCount": @"296"}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(296), [self.book valueForKey:@"pageCount"], @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfCannotConvertInteger32AttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"pageCount": [NSDate date]}];
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldSetInteger64AttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"ratingsCount": @(1234567890)}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(1234567890), [self.book valueForKey:@"ratingsCount"], @"");
}

- (void)testSetPropertiesWithRecordShouldConvertInteger64AttributeTypeIfNotNumber
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"ratingsCount": @"1234567890"}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(1234567890), [self.book valueForKey:@"ratingsCount"], @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfCannotConvertInteger64AttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"ratingsCount": [NSDate date]}];
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldSetDoubleAttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"averageRating": @(4.2)}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(4.2), [self.book valueForKey:@"averageRating"], @"");
}

- (void)testSetPropertiesWithRecordShouldConvertDoubleAttributeTypeIfNotNumber
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"averageRating": @"4.2"}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(4.2), [self.book valueForKey:@"averageRating"], @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfCannotConvertDoubleAttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"averageRating": [NSDate date]}];
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldSetDecimalAttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"price": @(19.60)}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(19.60), [self.book valueForKey:@"price"], @"");
}

- (void)testSetPropertiesWithRecordShouldConvertDecimalAttributeTypeIfNotNumber
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"price": @"19.60"}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(19.60), [self.book valueForKey:@"price"], @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfCannotConvertDecimalAttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"price": [NSDate date]}];
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldSetFloatAttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"coverHeight": @(768.0f)}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(768.0f), [self.book valueForKey:@"coverHeight"], @"");
}

- (void)testSetPropertiesWithRecordShouldConvertFloatAttributeTypeIfNotNumber
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"coverHeight": @"768.0"}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(768.0f), [self.book valueForKey:@"coverHeight"], @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfCannotConvertFloatAttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"coverHeight": [NSDate date]}];
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldSetBooleanAttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"isFavorite": @(1)}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(1), [self.book valueForKey:@"isFavorite"], @"");
}

- (void)testSetPropertiesWithRecordShouldConvertBooleanAttributeTypeIfNotNumber
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"isFavorite": @"1"}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(1), [self.book valueForKey:@"isFavorite"], @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfCannotConvertBooleanAttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"isFavorite": [NSDate date]}];
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldSetDateAttributeType
{
    NSDate *publishedDate = [NSDate date];
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"publishedDate": publishedDate}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(publishedDate, [self.book valueForKey:@"publishedDate"], @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfCannotConvertDateAttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"publishedDate": @"1960-07-11"}];
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldSetBinaryDataAttributeType
{
    NSData *cover = [NSData data];
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"cover": cover}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(cover, [self.book valueForKey:@"cover"], @"");
}

- (void)testSetPropertiesWithRecordShouldCombineBinaryDataAttributeTypeIfSplitIntoChunks
{
    PKDatastoreMock *datastore = [[PKDatastoreMock alloc] init];
    PKTableMock *binaryTable = [[PKTableMock alloc] initWithTableID:@"books.bin" datastore:datastore];

    NSData *chunkOne = [@"One" dataUsingEncoding:NSUTF8StringEncoding];
    [binaryTable setRecord:[PKRecordMock record:@"1" withFields:@{@"data": chunkOne}]];
    
    NSData *chunkTwo = [@"Two" dataUsingEncoding:NSUTF8StringEncoding];
    [binaryTable setRecord:[PKRecordMock record:@"2" withFields:@{@"data": chunkTwo}]];
    
    NSData *chunkThree = [@"Three" dataUsingEncoding:NSUTF8StringEncoding];
    [binaryTable setRecord:[PKRecordMock record:@"3" withFields:@{@"data": chunkThree}]];
    
    PKTableMock *table = [[PKTableMock alloc] initWithTableID:@"books" datastore:datastore];
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"cover": [[PKListMock alloc] initWithValues:@[@"1", @"2", @"3"]]}];
    [record setTable:table];
    
    NSMutableData *cover = [[NSMutableData alloc] init];
    [cover appendData:chunkOne];
    [cover appendData:chunkTwo];
    [cover appendData:chunkThree];
    
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(cover, [self.book valueForKey:@"cover"], @"");
    
    NSString *stringValue = [[NSString alloc] initWithData:[self.book valueForKey:@"cover"] encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(@"OneTwoThree", stringValue, @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfInvalidBinaryAttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"cover": @"Not binary or list type"}];
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfCannotFindBinaryTableForChunkedBinaryDataAttribute
{
    PKDatastoreMock *datastore = [[PKDatastoreMock alloc] init];
    PKTableMock *table = [[PKTableMock alloc] initWithTableID:@"books" datastore:datastore];
    
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"cover": [[PKListMock alloc] initWithValues:@[@"1", @"2", @"3"]]}];
    [record setTable:table];
    
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfBinaryTableRecordContainsInvalidDataForChunkedBinaryDataAttribute
{
    PKDatastoreMock *datastore = [[PKDatastoreMock alloc] init];
    
    PKTableMock *binaryTable = [[PKTableMock alloc] initWithTableID:@"books.bin" datastore:datastore];
    NSData *chunkOne = [@"One" dataUsingEncoding:NSUTF8StringEncoding];
    [binaryTable setRecord:[PKRecordMock record:@"1" withFields:@{@"data": chunkOne}]];
    [binaryTable setRecord:[PKRecordMock record:@"2" withFields:@{@"data": @"Not a binary value"}]];
    
    PKTableMock *table = [[PKTableMock alloc] initWithTableID:@"books" datastore:datastore];
    
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"cover": [[PKListMock alloc] initWithValues:@[@"1", @"2"]]}];
    [record setTable:table];
    
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfBinaryTableRecordDataIsMissingForChunkedBinaryDataAttribute
{
    PKDatastoreMock *datastore = [[PKDatastoreMock alloc] init];
    
    PKTableMock *binaryTable = [[PKTableMock alloc] initWithTableID:@"books.bin" datastore:datastore];
    NSData *chunkOne = [@"One" dataUsingEncoding:NSUTF8StringEncoding];
    [binaryTable setRecord:[PKRecordMock record:@"1" withFields:@{@"data": chunkOne}]];
    [binaryTable setRecord:[PKRecordMock record:@"2" withFields:@{}]];
    
    PKTableMock *table = [[PKTableMock alloc] initWithTableID:@"books" datastore:datastore];
    
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"cover": [[PKListMock alloc] initWithValues:@[@"1", @"2"]]}];
    [record setTable:table];
    
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldSetToManyRelationship
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"authors": [[PKListMock alloc] initWithValues:@[@"1"]]}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    
    NSSet *authors = [self.book valueForKey:@"authors"];
    XCTAssertNotNil(authors, @"");
    XCTAssertEqual(1, (int)[authors count], @"");
    
    NSManagedObject *author = [authors anyObject];
    XCTAssertEqualObjects(author, self.author, @"");
}

- (void)testSetPropertiesWithRecordShouldSetOrderedToManyRelationship
{
    NSManagedObject *author = [NSEntityDescription insertNewObjectForEntityForName:@"Author" inManagedObjectContext:self.managedObjectContext];
    
    NSMutableArray *unsortedIdentifiers = [[NSMutableArray alloc] init];
    for (int i = 0; i < 10; i++) {
        NSManagedObject *book = [NSEntityDescription insertNewObjectForEntityForName:@"Book" inManagedObjectContext:self.managedObjectContext];
        NSString *identifier = [NSString stringWithFormat:@"%i", i + 100];
        [book setValue:identifier forKey:PKDefaultSyncAttributeName];
        
        if (i % 2) {
            [book setValue:[NSSet setWithObject:author] forKey:@"authors"];
        }
        
        [unsortedIdentifiers addObject:identifier];
    }
    
    NSArray *identifiers = [[unsortedIdentifiers reverseObjectEnumerator] allObjects];
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"books": [[PKListMock alloc] initWithValues:identifiers]}];
    [author pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    
    NSOrderedSet *books = [author valueForKey:@"books"];
    XCTAssertNotNil(books, @"");
    XCTAssertEqual(10, (int)[books count], @"");

    [identifiers enumerateObjectsUsingBlock:^(NSString *identifier, NSUInteger idx, BOOL *stop) {
        NSManagedObject *book = [books objectAtIndex:idx];
        XCTAssertEqualObjects(identifier, [book valueForKey:PKDefaultSyncAttributeName], @"");
    }];
}

- (void)testSetPropertiesWithRecordShouldIgnoreMissingObjectsInToManyRelationship
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"authors": [[PKListMock alloc] initWithValues:@[@"1", @"2"]]}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    
    NSSet *authors = [self.book valueForKey:@"authors"];
    XCTAssertNotNil(authors, @"");
    XCTAssertEqual(1, (int)[authors count], @"");
    
    NSManagedObject *author = [authors anyObject];
    XCTAssertEqualObjects(author, self.author, @"");
}

- (void)testSetPropertiesWithRecordShouldRemoveObjectsInToManyRelationship
{
    NSManagedObject *authorToBeRemoved = [NSEntityDescription insertNewObjectForEntityForName:@"Author" inManagedObjectContext:self.managedObjectContext];
    [authorToBeRemoved setValue:@"2" forKey:PKDefaultSyncAttributeName];
    
    [self.book setValue:[NSSet setWithObjects:self.author, authorToBeRemoved, nil] forKey:@"authors"];
    XCTAssertEqual(2, (int)[[self.book valueForKey:@"authors"] count], @"");
    
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"authors": [[PKListMock alloc] initWithValues:@[@"1"]]}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    
    NSSet *authors = [self.book valueForKey:@"authors"];
    XCTAssertNotNil(authors, @"");
    XCTAssertEqual(1, (int)[authors count], @"");
    
    NSManagedObject *author = [authors anyObject];
    XCTAssertEqualObjects(author, self.author, @"");
}

- (void)testSetPropertiesWithRecordShouldRemoveObjectsInOrderedToManyRelationship
{
    NSManagedObject *author = [NSEntityDescription insertNewObjectForEntityForName:@"Author" inManagedObjectContext:self.managedObjectContext];
    
    NSMutableArray *unsortedIdentifiers = [[NSMutableArray alloc] init];
    for (int i = 0; i < 3; i++) {
        NSManagedObject *book = [NSEntityDescription insertNewObjectForEntityForName:@"Book" inManagedObjectContext:self.managedObjectContext];
        NSString *identifier = [NSString stringWithFormat:@"%i", i + 100];
        [book setValue:identifier forKey:PKDefaultSyncAttributeName];
        [book setValue:[NSSet setWithObject:author] forKey:@"authors"];
        [unsortedIdentifiers addObject:identifier];
    }

    NSManagedObject *shouldDeleteBookOne = [NSEntityDescription insertNewObjectForEntityForName:@"Book" inManagedObjectContext:self.managedObjectContext];
    [shouldDeleteBookOne setValue:@"shouldDeleteBookOne" forKey:PKDefaultSyncAttributeName];
    [shouldDeleteBookOne setValue:[NSSet setWithObject:author] forKey:@"authors"];

    NSManagedObject *shouldDeleteBookTwo = [NSEntityDescription insertNewObjectForEntityForName:@"Book" inManagedObjectContext:self.managedObjectContext];
    [shouldDeleteBookTwo setValue:@"shouldDeleteBookTwo" forKey:PKDefaultSyncAttributeName];
    [shouldDeleteBookTwo setValue:[NSSet setWithObject:author] forKey:@"authors"];
    
    NSArray *identifiers = [[unsortedIdentifiers reverseObjectEnumerator] allObjects];
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"books": [[PKListMock alloc] initWithValues:identifiers]}];
    [author pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    
    NSOrderedSet *books = [author valueForKey:@"books"];
    XCTAssertNotNil(books, @"");
    XCTAssertEqual(3, (int)[books count], @"");
    
    [identifiers enumerateObjectsUsingBlock:^(NSString *identifier, NSUInteger idx, BOOL *stop) {
        NSManagedObject *book = [books objectAtIndex:idx];
        XCTAssertEqualObjects(identifier, [book valueForKey:PKDefaultSyncAttributeName], @"");
    }];
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfToManyRelationshipIsNotAList
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"authors": @"1,2"}];
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldSetToOneRelationship
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"publisher": @"1"}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(self.publisher, [self.book valueForKey:@"publisher"], @"");
}

- (void)testSetPropertiesWithRecordShouldNotSetToOneToManyRelationshipOnTheManySide
{
    [self.book setValue:self.publisher forKey:@"publisher"];
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"books": @""}];
    [self.publisher pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(self.publisher, [self.book valueForKey:@"publisher"], @"");
}

- (void)testSetPropertiesWithRecordShouldIgnoreMissingObjectInToOneRelationship
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"publisher": @"2"}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertNil([self.book valueForKey:@"publisher"], @"");
}

- (void)testSetPropertiesWithRecordShouldRemoveToOneRelationship
{
    [self.book setValue:self.publisher forKey:@"publisher"];
    
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertNil([self.book valueForKey:@"publisher"], @"");
}

- (void)testSetPropertiesWithRecordShouldConvertToOneRelationshipValueIfNotString
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"publisher": @(1)}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(self.publisher, [self.book valueForKey:@"publisher"], @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfToManyCannotConvertToOneRelationshipValue
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"publisher": [NSDate date]}];
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldSetMultipleProperties
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"title": @"To Kill a Mockingbird Part 2: Birdy's Revenge", @"pageCount": @(296)}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@"To Kill a Mockingbird Part 2: Birdy's Revenge", [self.book valueForKey:@"title"], @"");
    XCTAssertEqualObjects(@(296), [self.book valueForKey:@"pageCount"], @"");
}

-(void)testSetPropertiesWithRecordShouldTriggerCallback
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"title": @"To Kill a Mockingbird Part 2: Birdy's Revenge"}];
    [self.author pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssert(self.author.hasSyncCallbackBeenCalled, @"");
    
}

@end
