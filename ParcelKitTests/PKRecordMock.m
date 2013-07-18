//
//  PKRecordMock.m
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

#import "PKRecordMock.h"
#import "PKTableMock.h"
#import "PKListMock.h"

@interface PKRecordMock ()
@property (copy, nonatomic) NSString *recordId;
@property (strong, nonatomic) NSMutableDictionary *mockFields;
@property (strong, nonatomic) NSMutableDictionary *mockLists;
@property (assign, nonatomic) BOOL deleted;
@end

@implementation PKRecordMock
@synthesize table = _table;
@synthesize recordId = _recordId;
@synthesize deleted = _deleted;

+ (instancetype)record:(NSString *)recordId withFields:(NSDictionary *)fields deleted:(BOOL)deleted
{
    return [[self alloc] initWithRecordId:recordId fields:fields deleted:deleted];
}

+ (instancetype)record:(NSString *)recordId withFields:(NSDictionary *)fields
{
    return [self record:recordId withFields:fields deleted:NO];
}

- (id)init
{
    self = [super init];
    if (self) {
        _mockFields = [[NSMutableDictionary alloc] init];
        _mockLists = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)initWithRecordId:(NSString *)recordId fields:(NSDictionary *)fields deleted:(BOOL)deleted
{
    self = [self init];
    if (self) {
        _recordId = recordId;
        _deleted = deleted;
        [_mockFields addEntriesFromDictionary:fields];
    }
    return self;
}

- (void)setTable:(DBTable *)table
{
    _table = table;
}

#pragma mark - Mocked DBRecord Methods

- (id)objectForKey:(NSString *)key
{
    return [self.mockFields objectForKey:key];
}

- (void)setObject:(id)obj forKey:(NSString *)fieldName
{
    [self.mockFields setObject:obj forKey:fieldName];
}

- (void)removeObjectForKey:(NSString *)fieldName
{
    [self.mockFields removeObjectForKey:fieldName];
}

- (NSDictionary *)fields
{
    return [[NSDictionary alloc] initWithDictionary:self.mockFields];
}

- (BOOL)isDeleted
{
    return self.deleted;
}

- (void)deleteRecord
{
    [(PKTableMock *)self.table deleteRecord:self];
}

- (DBList *)getOrCreateList:(NSString *)fieldName
{
    PKListMock *list = [self.mockLists objectForKey:fieldName];
    if (!list) {
        list = [[PKListMock alloc] init];
        [self.mockLists setObject:list forKey:fieldName];
    }
    return list;
}
@end
