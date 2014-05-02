//
//  NSManagedObject+ParcelKit.m
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

#import "NSManagedObject+ParcelKit.h"
#import <Dropbox/Dropbox.h>
#import "PKConstants.h"

NSString * const PKInvalidAttributeValueException = @"Invalid attribute value";
static NSString * const PKInvalidAttributeValueExceptionFormat = @"“%@.%@” expected “%@” to be of type “%@” but is “%@”";

@implementation NSManagedObject (ParcelKit)
- (void)pk_setPropertiesWithRecord:(DBRecord *)record syncAttributeName:(NSString *)syncAttributeName
{
    NSString *entityName = [[self entity] name];
    
    __weak typeof(self) weakSelf = self;
    NSDictionary *propertiesByName = [[self entity] propertiesByName];
    [propertiesByName enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSPropertyDescription *propertyDescription, BOOL *stop) {
        typeof(self) strongSelf = weakSelf; if (!strongSelf) return;
        
        if ([propertyName isEqualToString:syncAttributeName] || [propertyDescription isTransient]) return;
        
        if ([propertyDescription isKindOfClass:[NSAttributeDescription class]]) {
            NSAttributeType attributeType = [(NSAttributeDescription *)propertyDescription attributeType];
            
            id value = [record objectForKey:propertyName];
            if (value) {
                if ((attributeType == NSStringAttributeType) && (![value isKindOfClass:[NSString class]])) {
                    if ([value respondsToSelector:@selector(stringValue)]) {
                        value = [value stringValue];
                    } else {
                        [NSException raise:PKInvalidAttributeValueException format:PKInvalidAttributeValueExceptionFormat, entityName, propertyName, value, [NSString class], [value class]];
                    }
                } else if (((attributeType == NSInteger16AttributeType) || (attributeType == NSInteger32AttributeType) || (attributeType == NSInteger64AttributeType)) && (![value isKindOfClass:[NSNumber class]])) {
                    if ([value respondsToSelector:@selector(integerValue)]) {
                        value = [NSNumber numberWithInteger:[value integerValue]];
                    } else {
                        [NSException raise:PKInvalidAttributeValueException format:PKInvalidAttributeValueExceptionFormat, entityName, propertyName, value, [NSNumber class], [value class]];
                    }
                } else if ((attributeType == NSBooleanAttributeType) && (![value isKindOfClass:[NSNumber class]])) {
                    if ([value respondsToSelector:@selector(boolValue)]) {
                        value = [NSNumber numberWithBool:[value boolValue]];
                    } else {
                        [NSException raise:PKInvalidAttributeValueException format:PKInvalidAttributeValueExceptionFormat, entityName, propertyName, value, [NSNumber class], [value class]];
                    }
                } else if (((attributeType == NSDoubleAttributeType) || (attributeType == NSFloatAttributeType) || attributeType == NSDecimalAttributeType) && (![value isKindOfClass:[NSNumber class]])) {
                    if ([value respondsToSelector:@selector(doubleValue)]) {
                        value = [NSNumber numberWithDouble:[value doubleValue]];
                    } else {
                        [NSException raise:PKInvalidAttributeValueException format:PKInvalidAttributeValueExceptionFormat, entityName, propertyName, value, [NSNumber class], [value class]];
                    }
                } else if ((attributeType == NSDateAttributeType) && (![value isKindOfClass:[NSDate class]])) {
                    [NSException raise:PKInvalidAttributeValueException format:PKInvalidAttributeValueExceptionFormat, entityName, propertyName, value, [NSDate class], [value class]];
                } else if ((attributeType == NSBinaryDataAttributeType) && (![value isKindOfClass:[NSData class]])) {
                    if ([value isKindOfClass:[DBList class]]) {
                        // Get the corresponding table used to store binary data
                        NSString *binaryTableID = [record.table.tableId stringByAppendingString:PKBinaryDataTableSuffix];
                        DBTable *binaryTable = [record.table.datastore getTable:binaryTableID];
                        
                        // Loop through the binary records and combine them into a single data value
                        NSMutableData *data = [[NSMutableData alloc] init];
                        NSArray *binaryRecordIDs = [value values];
                        for (NSString *binaryRecordID in binaryRecordIDs) {
                            DBError *dberror = nil;
                            DBRecord *record = [binaryTable getRecord:binaryRecordID error:&dberror];
                            if (record) {
                                NSData *chunk = [record objectForKey:@"data"];
                                if (chunk && [chunk isKindOfClass:[NSData class]]) {
                                    [data appendData:chunk];
                                } else {
                                    [NSException raise:PKInvalidAttributeValueException format:@"Invalid binary record “%@.%@” for “%@.%@” expected “data” to be of type “%@” but is “%@”", binaryTableID, binaryRecordID, entityName, propertyName, [NSData class], [chunk class]];
                                }
                            } else {
                                [NSException raise:PKInvalidAttributeValueException format:@"Could not find binary record “%@.%@” for “%@.%@”", binaryTableID, binaryRecordID, entityName, propertyName];
                            }
                        }

                        value = [[NSData alloc] initWithData:data];
                    } else {
                        [NSException raise:PKInvalidAttributeValueException format:PKInvalidAttributeValueExceptionFormat, entityName, propertyName, value, [NSData class], [value class]];
                    }
                }
            } else if (![propertyDescription isOptional] && ![strongSelf valueForKey:propertyName]) {
                 [NSException raise:PKInvalidAttributeValueException format:@"“%@.%@” expected to not be null", entityName, propertyName];
            }
            
            [strongSelf setValue:value forKey:propertyName];
        } else if ([propertyDescription isKindOfClass:[NSRelationshipDescription class]]) {
            NSRelationshipDescription *relationshipDescription = (NSRelationshipDescription *)propertyDescription;
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[[relationshipDescription destinationEntity] name]];
            [fetchRequest setFetchLimit:1];
            
            if ([relationshipDescription isToMany]) {
                DBList *recordList = [record objectForKey:propertyName];
                if (recordList && ![recordList isKindOfClass:[DBList class]]) {
                    [NSException raise:PKInvalidAttributeValueException format:PKInvalidAttributeValueExceptionFormat, entityName, propertyName, recordList, [DBList class], [recordList class]];
                }
                
                NSMutableArray *recordIdentifiers = [[NSMutableArray alloc] init];
                for (id value in [recordList values]) {
                    if (![value isKindOfClass:[NSString class]]) {
                        if ([value respondsToSelector:@selector(stringValue)]) {
                            [recordIdentifiers addObject:[value stringValue]];
                        } else {
                            [NSException raise:PKInvalidAttributeValueException format:PKInvalidAttributeValueExceptionFormat, entityName, propertyName, value, [NSString class], [value class]];
                        }
                    } else {
                        [recordIdentifiers addObject:value];
                    }
                }
                
                id relatedObjects = ([relationshipDescription isOrdered] ? [strongSelf mutableOrderedSetValueForKey:propertyName] : [strongSelf mutableSetValueForKey:propertyName]);
                NSMutableSet *unrelatedObjects = [[NSMutableSet alloc] init];
                for (NSManagedObject *relatedObject in relatedObjects) {
                    if (![recordIdentifiers containsObject:[relatedObject valueForKey:syncAttributeName]]) {
                        if (([relatedObject respondsToSelector:@selector(isRecordSyncable)]) && (![relatedObject performSelector:@selector(isRecordSyncable)])) {
                            // Don't remove links to un-synced objects
                            continue;
                        }
                        [unrelatedObjects addObject:relatedObject];
                    }
                }
                [relatedObjects minusSet:unrelatedObjects];
                
                NSUInteger recordIndex = 0;
                for (NSString *identifier in recordIdentifiers) {
                    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", syncAttributeName, identifier]];
                    [fetchRequest setIncludesPropertyValues:NO];
                    NSError *error = nil;
                    NSArray *managedObjects = [strongSelf.managedObjectContext executeFetchRequest:fetchRequest error:&error];
                    if (managedObjects) {
                        if ([managedObjects count] == 1) {
                            NSManagedObject *relatedObject = managedObjects[0];
                            
                            if ([relationshipDescription isOrdered]) {
                                NSUInteger relatedObjectIndex = [relatedObjects indexOfObject:relatedObject];
                                if (relatedObjectIndex != recordIndex) {
                                    if (relatedObjectIndex != NSNotFound) {
                                        [relatedObjects removeObject:relatedObject];
                                    }
                                    [relatedObjects insertObject:relatedObject atIndex:recordIndex];
                                }
                            } else {
                                if (![relatedObjects containsObject:relatedObject]) {
                                    [relatedObjects addObject:relatedObject];
                                }
                            }
                        }
                    } else {
                        NSLog(@"Error executing fetch request: %@", error);
                    }
                    
                    recordIndex++;
                };
            } else {
                id identifier = [record objectForKey:propertyName];
                if (identifier) {
                    if (![identifier isKindOfClass:[NSString class]]) {
                        if ([identifier respondsToSelector:@selector(stringValue)]) {
                            identifier = [identifier stringValue];
                        } else {
                            [NSException raise:PKInvalidAttributeValueException format:PKInvalidAttributeValueExceptionFormat, entityName, propertyName, identifier, [NSString class], [identifier class]];
                        }
                    }
                    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", syncAttributeName, identifier]];
                    NSError *error = nil;
                    NSArray *managedObjects = [strongSelf.managedObjectContext executeFetchRequest:fetchRequest error:&error];
                    if (managedObjects) {
                        if ([managedObjects count] == 1) {
                            NSManagedObject *relatedObject = managedObjects[0];
                            if (![[strongSelf valueForKey:propertyName] isEqual:relatedObject]) {
                                [strongSelf setValue:relatedObject forKey:propertyName];
                            }
                        }
                    } else {
                        NSLog(@"Error executing fetch request: %@", error);
                    }
                } else {
                    [strongSelf setValue:nil forKey:propertyName];
                }
            }
        }
    }];
    
    if ([self respondsToSelector:@selector(parcelKitWasSyncedFromDropbox)]) {
        // Give objects an opportunity to respond to the sync
        [self performSelector:@selector(parcelKitWasSyncedFromDropbox)];
    }
}
@end
