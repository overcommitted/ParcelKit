//
//  PKTableMock.m
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

#import "PKTableMock.h"
#import "PKRecordMock.h"

@interface PKTableMock ()
@property (copy, nonatomic) NSString *tableID;
@property (strong, nonatomic, readwrite) NSMutableDictionary *records;
@end

@implementation PKTableMock

- (id)init
{
    self = [super init];
    if (self) {
        _records = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)initWithTableID:(NSString *)tableID
{
    self = [self init];
    if (self) {
        _tableID = tableID;
    }
    return self;
}

- (NSString *)tableId
{
    return _tableID;
}

- (void)deleteRecord:(DBRecord *)record
{
    [self.records removeObjectForKey:record.recordId];
}

#pragma mark - Mocked DBTable Methods

- (DBRecord *)getRecord:(NSString *)recordId error:(DBError **)error
{
    return [self.records objectForKey:recordId];
}

- (PKRecordMock *)getOrInsertRecord:(NSString *)recordId fields:(NSDictionary *)fields
                           inserted:(BOOL *)inserted error:(DBError **)error
{
    PKRecordMock *record = [self.records objectForKey:recordId];
    if (!record) {
        if (inserted) *inserted = YES;
        record = [PKRecordMock record:recordId withFields:fields];
        [record setTable:self];
        [self.records setObject:record forKey:recordId];
    }
    return record;
}

@end
