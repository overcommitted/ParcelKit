//
//  PKListMock.m
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

#import "PKListMock.h"

@interface PKListMock ()
@property (strong, nonatomic) NSMutableArray *mockValues;
@end

@implementation PKListMock

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mockValues = [[NSMutableArray alloc] init];
    }
    return self;
}

- (instancetype)initWithValues:(NSArray *)values
{
    self = [self init];
    if (self) {
        [_mockValues addObjectsFromArray:values];
    }
    return self;
}

- (void)addObject:(id)obj
{
    [self.mockValues addObject:obj];
}

- (id)objectAtIndex:(NSUInteger)index
{
    return [self.mockValues objectAtIndex:index];
}

- (void)insertObject:(id)obj atIndex:(NSUInteger)index
{
    [self.mockValues insertObject:obj atIndex:index];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    [self.mockValues removeObjectAtIndex:index];
}

- (void)moveObjectAtIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex
{
    id object = [self.mockValues objectAtIndex:oldIndex];
    [self.mockValues removeObjectAtIndex:oldIndex];
    [self.mockValues insertObject:object atIndex:newIndex];
}

- (NSArray *)values
{
    return [[NSArray alloc] initWithArray:self.mockValues];
}

- (NSUInteger)count
{
    return [self.mockValues count];
}
@end
