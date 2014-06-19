//
//  PKDatastoreMock.m
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

#import "PKDatastoreMock.h"
#import "PKTableMock.h"
#import "PKDatastoreStatusMock.h"

static NSString * const PKDatastoreMockObserverKey = @"observer";
static NSString * const PKDatastoreMockObserverBlockKey = @"block";

@interface PKDatastoreMock()
@property (strong, nonatomic) NSMutableSet *observers;
@property (nonatomic, readwrite) PKDatastoreStatusMock *status;
@property (strong, nonatomic) NSDictionary *changes;
@property (strong, nonatomic) NSMutableDictionary *tables;
@end

@implementation PKDatastoreMock
- (id)init
{
    self = [super init];
    if (self) {
        _observers = [[NSMutableSet alloc] init];
        _tables = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - Unit Testing Methods
- (void)updateStatus:(PKDatastoreStatusMock *)status withChanges:(NSDictionary *)changes
{
    self.status = status;
    self.changes = changes;
    
    for (NSDictionary *observerInfo in self.observers) {
        DBObserver block = [observerInfo objectForKey:PKDatastoreMockObserverBlockKey];
        block();
    }
}

#pragma mark - Mocked DBDatastore Methods
- (void)addObserver:(id)observer block:(DBObserver)block
{
    NSDictionary *observerInfo = @{PKDatastoreMockObserverKey: observer, PKDatastoreMockObserverBlockKey: [block copy]};
    [self.observers addObject:observerInfo];
}

- (void)removeObserver:(id)observer
{
    [self.observers filterUsingPredicate:[NSPredicate predicateWithFormat:@"%K != %@", PKDatastoreMockObserverKey, observer]];
}

- (void)setTable:(PKTableMock *)table
{
    [self.tables setObject:table forKey:table.tableId];
}

- (PKTableMock *)getTable:(NSString *)tableID
{
    PKTableMock *table = [self.tables objectForKey:tableID];
    if (!table) {
        table = [[PKTableMock alloc] initWithTableID:tableID];
        [self setTable:table];
    }
    return table;
}

- (NSDictionary *)sync:(DBError **)error
{
    NSDictionary *changes = self.changes;
    self.changes = nil;
    return changes;
}

@end
