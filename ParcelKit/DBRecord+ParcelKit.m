//
//  DBRecord+ParcelKit.m
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

#import "DBRecord+ParcelKit.h"
#import "PKConstants.h"
#import "NSManagedObject+ParcelKit.h"

#ifndef PKMaximumBinaryDataChunkLengthInBytes
#define PKMaximumBinaryDataChunkLengthInBytes 95000
#endif

@implementation DBRecord (ParcelKit)

- (void)pk_setFieldsWithManagedObject:(NSManagedObject *)managedObject syncAttributeName:(NSString *)syncAttributeName
{
    __weak typeof(self) weakSelf = self;
    NSDictionary *propertiesByName = [[managedObject entity] propertiesByName];
    NSArray *fieldNames = [[self fields] allKeys];
    NSDictionary *values;
    if ([managedObject respondsToSelector:@selector(syncedPropertiesDictionary:)]) {
        // Get the custom properties dictionary
        values = [managedObject performSelector:@selector(syncedPropertiesDictionary:) withObject:propertiesByName];
    } else {
        // Get the standard properties dictionary
        values = [managedObject dictionaryWithValuesForKeys:[propertiesByName allKeys]];
    }
    [values enumerateKeysAndObjectsUsingBlock:^(NSString *name, id value, BOOL *stop) {
        typeof(self) strongSelf = weakSelf; if (!strongSelf) return;
        
        if ([name isEqualToString:syncAttributeName]) return;

        NSPropertyDescription *propertyDescription = [propertiesByName objectForKey:name];
        if ([propertyDescription isTransient]) return;

        if (value && value != [NSNull null]) {
            if ((propertyDescription == nil) || [propertyDescription isKindOfClass:[NSAttributeDescription class]]) {
                id previousValue = [strongSelf objectForKey:name];

                NSAttributeType attributeType = [(NSAttributeDescription *)propertyDescription attributeType];
                if ((propertyDescription == nil) || (attributeType != NSBinaryDataAttributeType)) {
                    if (!previousValue || [previousValue compare:value] != NSOrderedSame) {
                        [strongSelf setObject:value forKey:name];
                    }
                } else {
                    NSString *binaryTableID = [self.table.tableId stringByAppendingString:PKBinaryDataTableSuffix];
                    DBTable *binaryTable = [self.table.datastore getTable:binaryTableID];

                    NSMutableArray *previousRecords = [[NSMutableArray alloc] init];
                    NSMutableData *previousData = [[NSMutableData alloc] init];
                    if (previousValue) {
                        if ([previousValue isKindOfClass:[NSData class]]) {
                            [previousData appendData:previousValue];
                        } else if ([previousValue isKindOfClass:[DBList class]]) {
                            NSArray *binaryRecordIDs = [previousValue values];
                            for (NSString *binaryRecordID in binaryRecordIDs) {
                                DBRecord *record = [binaryTable getRecord:binaryRecordID error:nil];
                                if (record) {
                                    NSData *chunk = [record objectForKey:@"data"];
                                    if (chunk && [chunk isKindOfClass:[NSData class]]) {
                                        [previousData appendData:chunk];
                                    }
                                    [previousRecords addObject:record];
                                }
                            }
                        }
                    }
                    
                    // Only sync data if it's changed
                    NSData *data = value;
                    if (![data isEqualToData:previousData]) {
                        previousData = nil;
                        
                        if ([value length] <= PKMaximumBinaryDataLengthInBytes) {
                            [strongSelf setObject:value forKey:name];
                        } else {
                            // Split the data into chunks
                            [self removeObjectForKey:name];
                            DBList *list = [self getOrCreateList:name];

                            NSUInteger length = [value length];
                            NSUInteger numberOfChunks = ceil(length / (double)PKMaximumBinaryDataChunkLengthInBytes);
                            for (NSInteger i = 0; i < numberOfChunks; i++) {
                                NSUInteger location = i * PKMaximumBinaryDataChunkLengthInBytes;
                                NSRange range = NSMakeRange(location, MIN(PKMaximumBinaryDataChunkLengthInBytes, length - location));
                                NSData *chunk = [value subdataWithRange:range];
                                DBRecord *record = [binaryTable insert:@{@"data": chunk}];
                                [list addObject:record.recordId];
                            }
                        }
                        
                        // Delete all previous records
                        for (DBRecord *record in previousRecords) {
                            [record deleteRecord];
                        }
                    }
                }
            } else if ([propertyDescription isKindOfClass:[NSRelationshipDescription class]]) {
                NSRelationshipDescription *relationshipDescription = (NSRelationshipDescription *)propertyDescription;
                if ([relationshipDescription isToMany]) {
                    DBList *fieldList = [strongSelf getOrCreateList:name];
                    NSMutableOrderedSet *previousIdentifiers = [[NSMutableOrderedSet alloc] initWithArray:[fieldList values]];
                    NSOrderedSet *currentIdentifiers = ([relationshipDescription isOrdered] ? [value valueForKey:syncAttributeName] : [[NSOrderedSet alloc] initWithArray:[[value allObjects] valueForKey:syncAttributeName]]);
                    
                    NSMutableOrderedSet *deletedIdentifiers = [[NSMutableOrderedSet alloc] initWithOrderedSet:previousIdentifiers];
                    [deletedIdentifiers minusOrderedSet:currentIdentifiers];
                    for (NSString *identifier in deletedIdentifiers) {
                        NSInteger index = [[fieldList values] indexOfObject:identifier];
                        if (index != NSNotFound) {
                            [fieldList removeObjectAtIndex:index];
                        }
                    }
                    
                    NSUInteger recordIndex = 0;
                    for (NSString *identifier in currentIdentifiers) {
                        NSInteger index = [[fieldList values] indexOfObject:identifier];
                        if ([relationshipDescription isOrdered]) {
                            if (index != recordIndex) {
                                if (index != NSNotFound) {
                                    [fieldList moveObjectAtIndex:index toIndex:recordIndex];
                                } else {
                                    [fieldList insertObject:identifier atIndex:recordIndex];
                                }
                            }
                        } else if (index == NSNotFound) {
                            [fieldList addObject:identifier];
                        }
                        recordIndex++;
                    }
                } else {
                    [strongSelf setObject:[value valueForKey:syncAttributeName] forKey:name];
                }
            }
        } else {
            if ([fieldNames containsObject:name]) {
                id previousValue = [strongSelf objectForKey:name];
                if ([propertyDescription isKindOfClass:[NSAttributeDescription class]] && [(NSAttributeDescription *)propertyDescription attributeType] == NSBinaryDataAttributeType && [previousValue isKindOfClass:[DBList class]]) {
                    NSString *binaryTableID = [self.table.tableId stringByAppendingString:PKBinaryDataTableSuffix];
                    DBTable *binaryTable = [self.table.datastore getTable:binaryTableID];
                    NSArray *binaryRecordIDs = [previousValue values];
                    for (NSString *binaryRecordID in binaryRecordIDs) {
                        DBRecord *record = [binaryTable getRecord:binaryRecordID error:nil];
                        if (record) {
                            [record deleteRecord];
                        }
                    }
                }
                
                [strongSelf removeObjectForKey:name];
            }
        }
    }];
}

@end
