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

@implementation DBRecord (ParcelKit)
- (void)pk_setFieldsWithManagedObject:(NSManagedObject *)managedObject syncAttributeName:(NSString *)syncAttributeName
{
    __weak typeof(self) weakSelf = self;
    NSDictionary *propertiesByName = [[managedObject entity] propertiesByName];
    NSArray *fieldNames = [[self fields] allKeys];
    NSDictionary *values = [managedObject dictionaryWithValuesForKeys:[propertiesByName allKeys]];
    [values enumerateKeysAndObjectsUsingBlock:^(NSString *name, id value, BOOL *stop) {
        typeof(self) strongSelf = weakSelf; if (!strongSelf) return;
        
        if ([name isEqualToString:syncAttributeName]) return;
        
        if (value && value != [NSNull null]) {
            NSPropertyDescription *propertyDescription = [propertiesByName objectForKey:name];
            if ([propertyDescription isTransient]) return;
            
            if ([propertyDescription isKindOfClass:[NSAttributeDescription class]]) {
                [strongSelf setObject:value forKey:name];
            } else if ([propertyDescription isKindOfClass:[NSRelationshipDescription class]]) {
                if ([(NSRelationshipDescription *)propertyDescription isToMany]) {
                    DBList *fieldList = [strongSelf getOrCreateList:name];
                    NSSet *oldIdentifiers = [[NSMutableSet alloc] initWithArray:[fieldList values]];
                    NSSet *currentIdentifiers = [[NSSet alloc] initWithArray:[[value allObjects] valueForKey:syncAttributeName]];
                    
                    NSMutableSet *deletedIdentifiers = [[NSMutableSet alloc] initWithSet:oldIdentifiers];
                    [deletedIdentifiers minusSet:currentIdentifiers];
                    for (NSString *recordId in deletedIdentifiers) {
                        NSInteger index = [[fieldList values] indexOfObject:recordId];
                        if (index != NSNotFound) {
                            [fieldList removeObjectAtIndex:index];
                        }
                    }
                    
                    NSMutableSet *insertedIdentifiers = [[NSMutableSet alloc] initWithSet:currentIdentifiers];
                    [insertedIdentifiers minusSet:oldIdentifiers];
                    for (NSString *recordId in insertedIdentifiers) {
                        if (![[fieldList values] containsObject:recordId]) {
                            [fieldList addObject:recordId];
                        }
                    }
                } else {
                    [strongSelf setObject:[value valueForKey:syncAttributeName] forKey:name];
                }
            }
        } else {
            if ([fieldNames containsObject:name]) {
                [strongSelf removeObjectForKey:name];
            }
        }
    }];
}
@end
