//
//  PKSyncManager.m
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

#import "PKSyncManager.h"
#import "NSManagedObject+ParcelKit.h"
#import "DBRecord+ParcelKit.h"

NSString * const PKDefaultSyncAttributeName = @"syncID";
NSString * const PKSyncManagerDatastoreStatusDidChangeNotification = @"PKSyncManagerDatastoreStatusDidChange";
NSString * const PKSyncManagerDatastoreStatusKey = @"status";
NSString * const PKSyncManagerDatastoreIncomingChangesNotification = @"PKSyncManagerDatastoreIncomingChanges";
NSString * const PKSyncManagerDatastoreIncomingChangesKey = @"changes";
NSString * const PKSyncManagerDatastoreLastSyncDateNotification = @"PKSyncManagerDatastoreLastSyncDateNotification";
NSString * const PKSyncManagerDatastoreLastSyncDateKey = @"lastSyncDate";

@interface PKSyncManager ()
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readwrite) NSSet *observedManagedObjectContexts;
@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readwrite) DBDatastore *datastore;
@property (nonatomic, strong) NSMutableDictionary *tablesKeyedByEntityName;
@property (nonatomic) BOOL observing;
@end

@implementation PKSyncManager

+ (NSString *)syncID
{
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    NSString *uuid = (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL, uuidRef));
    return [uuid stringByReplacingOccurrencesOfString:@"-" withString:@""];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _observedManagedObjectContexts = [[NSSet alloc] init];
        _tablesKeyedByEntityName = [[NSMutableDictionary alloc] init];
        _syncAttributeName = PKDefaultSyncAttributeName;
        _syncBatchSize = 20;
    }
    return self;
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext datastore:(DBDatastore *)datastore
{
    self = [self init];
    if (self) {
        _managedObjectContext = managedObjectContext;
        [self addObserverForManagedObjectContext:_managedObjectContext];
        
        _datastore = datastore;
    }
    return self;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) return _persistentStoreCoordinator;
    
    if ([self.managedObjectContext persistentStoreCoordinator]) {
        _persistentStoreCoordinator = [self.managedObjectContext persistentStoreCoordinator];
    } else if ([self.managedObjectContext parentContext]) {
        if ([[self.managedObjectContext parentContext] persistentStoreCoordinator]) {
            _persistentStoreCoordinator = [[self.managedObjectContext parentContext] persistentStoreCoordinator];
        }
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Entity and Table map
- (void)setTablesForEntityNamesWithDictionary:(NSDictionary *)keyedTables
{
    for (NSString *entityName in [self entityNames]) {
        [self removeTableForEntityName:entityName];
    }

    __weak typeof(self) weakSelf = self;
    [keyedTables enumerateKeysAndObjectsUsingBlock:^(NSString *entityName, NSString *tableID, BOOL *stop) {
        typeof(self) strongSelf = weakSelf; if (!strongSelf) return;
        [strongSelf setTable:tableID forEntityName:entityName];
    }];
}

- (void)setTable:(NSString *)tableID forEntityName:(NSString *)entityName
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
    NSAttributeDescription *attributeDescription = [[entity attributesByName] objectForKey:self.syncAttributeName];
    NSAssert([attributeDescription attributeType] == NSStringAttributeType, @"Entity “%@” must contain a string attribute named “%@”", entityName, self.syncAttributeName);
    [self.tablesKeyedByEntityName setObject:tableID forKey:entityName];
}

- (void)removeTableForEntityName:(NSString *)entityName
{
    [self.tablesKeyedByEntityName removeObjectForKey:entityName];
}

- (NSDictionary *)tablesByEntityName
{
    return [[NSDictionary alloc] initWithDictionary:self.tablesKeyedByEntityName];
}

- (NSArray *)tableIDs
{
    return [self.tablesKeyedByEntityName allValues];
}

- (NSArray *)entityNames
{
    return [self.tablesKeyedByEntityName allKeys];
}

- (NSString *)tableForEntityName:(NSString *)entityName
{
    return [self.tablesKeyedByEntityName objectForKey:entityName];
}

- (NSString *)entityNameForTable:(NSString *)tableID
{
    return [[self.tablesKeyedByEntityName allKeysForObject:tableID] lastObject];
}

#pragma mark - Observing methods
- (BOOL)isObserving
{
    return self.observing;
}

- (void)startObserving
{
    if ([self isObserving]) return;
    self.observing = YES;
    
    __weak typeof(self) weakSelf = self;
    [self.datastore addObserver:self block:^ {
        typeof(self) strongSelf = weakSelf; if (!strongSelf) return;
        if (![strongSelf isObserving]) return;
        
        DBDatastoreStatus *status = strongSelf.datastore.status;
        if (status.incoming) {
            [strongSelf syncDatastore];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:PKSyncManagerDatastoreStatusDidChangeNotification object:strongSelf userInfo:@{PKSyncManagerDatastoreStatusKey:status}];
        });
    }];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    for (NSManagedObjectContext *managedObjectContext in self.observedManagedObjectContexts) {
        [notificationCenter addObserver:self selector:@selector(managedObjectContextWillSave:) name:NSManagedObjectContextWillSaveNotification object:managedObjectContext];
    }
}

- (void)stopObserving
{
    if (![self isObserving]) return;
    self.observing = NO;
    self.persistentStoreCoordinator = nil;
    
    [self.datastore removeObserver:self];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    for (NSManagedObjectContext *managedObjectContext in self.observedManagedObjectContexts) {
        [notificationCenter removeObserver:self name:NSManagedObjectContextWillSaveNotification object:managedObjectContext];
    }
}

- (void)addObserverForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    if ([self.observedManagedObjectContexts containsObject:managedObjectContext]) return;
    self.observedManagedObjectContexts = [self.observedManagedObjectContexts setByAddingObject:managedObjectContext];
    
    if ([self isObserving]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextWillSave:) name:NSManagedObjectContextWillSaveNotification object:managedObjectContext];
    }
}

- (void)removeObserverForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    if (![self.observedManagedObjectContexts containsObject:managedObjectContext]) return;
    
    NSMutableSet *observedManagedObjectContexts = [[NSMutableSet alloc] initWithSet:self.observedManagedObjectContexts];
    [observedManagedObjectContexts removeObject:managedObjectContext];
    self.observedManagedObjectContexts = [[NSSet alloc] initWithSet:observedManagedObjectContexts];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextWillSaveNotification object:managedObjectContext];
}

#pragma mark - Updating Core Data
- (BOOL)updateCoreDataWithDatastoreChanges:(NSDictionary *)changes
{
    static NSString * const PKUpdateManagedObjectKey = @"object";
    static NSString * const PKUpdateRecordKey = @"record";
    
    if ([changes count] == 0) return NO;
    
    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    [managedObjectContext setUndoManager:nil];

    __weak typeof(self) weakSelf = self;
    [managedObjectContext performBlockAndWait:^{
        typeof(self) strongSelf = weakSelf; if (!strongSelf) return;
        
        __block NSMutableArray *updates = [[NSMutableArray alloc] init];
        
        typeof(self) weakSelf = strongSelf;
        [changes enumerateKeysAndObjectsUsingBlock:^(NSString *tableID, NSArray *records, BOOL *stop) {
            typeof(self) strongSelf = weakSelf; if (!strongSelf) return;
            NSString *entityName = [strongSelf entityNameForTable:tableID];
            if (!entityName) return;
            
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
            [fetchRequest setFetchLimit:1];
            
            for (DBRecord *record in records) {
                [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", strongSelf.syncAttributeName, record.recordId]];
                
                NSError *error = nil;
                NSArray *managedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
                if (managedObjects)  {
                    NSManagedObject *managedObject = [managedObjects lastObject];
                    
                    if ([record isDeleted]) {
                        if (managedObject) {
                            [managedObjectContext deleteObject:managedObject];
                        }
                    } else {
                        if (!managedObject) {
                            managedObject = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:managedObjectContext];
                            [managedObject setValue:record.recordId forKey:strongSelf.syncAttributeName];
                        }
                        
                        [updates addObject:@{PKUpdateManagedObjectKey: managedObject, PKUpdateRecordKey: record}];
                    }
                } else {
                    NSLog(@"Error executing fetch request: %@", error);
                }
            }
        }];
        
        
        for (NSDictionary *update in updates) {
            NSManagedObject *managedObject = update[PKUpdateManagedObjectKey];
            DBRecord *record = update[PKUpdateRecordKey];
            [managedObject pk_setPropertiesWithRecord:record syncAttributeName:strongSelf.syncAttributeName];
        }
        
        if ([managedObjectContext hasChanges]) {
            [[NSNotificationCenter defaultCenter] addObserver:strongSelf selector:@selector(syncManagedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:managedObjectContext];
            NSError *error = nil;
            if (![managedObjectContext save:&error]) {
                NSLog(@"Error saving managed object context: %@", error);
            }
            [[NSNotificationCenter defaultCenter] removeObserver:strongSelf name:NSManagedObjectContextDidSaveNotification object:managedObjectContext];
        }
    }];
    
    return YES;
}

- (void)syncManagedObjectContextDidSave:(NSNotification *)notification
{
    if ([NSThread isMainThread]) {
        [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    } else {
        [self performSelectorOnMainThread:@selector(syncManagedObjectContextDidSave:) withObject:notification waitUntilDone:YES];
    }
}

#pragma mark - Updating Datastore
- (void)managedObjectContextWillSave:(NSNotification *)notification
{
    if (![self isObserving]) return;
    
    NSManagedObjectContext *managedObjectContext = notification.object;
    if (![self.observedManagedObjectContexts containsObject:managedObjectContext]) return;
    
    NSSet *deletedObjects = [managedObjectContext deletedObjects];
    for (NSManagedObject *managedObject in [self syncableManagedObjectsFromManagedObjects:deletedObjects]) {
        NSString *tableID = [self tableForEntityName:[[managedObject entity] name]];
        DBTable *table = [self.datastore getTable:tableID];
        DBError *error = nil;
        DBRecord *record = [table getRecord:[managedObject primitiveValueForKey:self.syncAttributeName] error:&error];
        if (record) {
            [record deleteRecord];
        }
    };
    
    NSMutableSet *managedObjects = [[NSMutableSet alloc] init];
    [managedObjects unionSet:[managedObjectContext insertedObjects]];
    [managedObjects unionSet:[managedObjectContext updatedObjects]];
    
    NSUInteger index = 0;
    for (NSManagedObject *managedObject in [self syncableManagedObjectsFromManagedObjects:managedObjects]) {
        [self updateDatastoreWithManagedObject:managedObject];
        index++;

        if (index % self.syncBatchSize == 0) {
            [self syncDatastore];
        }
    }

    [self syncDatastore];
}

- (void)updateDatastoreWithManagedObject:(NSManagedObject *)managedObject
{
    NSString *tableID = [self tableForEntityName:[[managedObject entity] name]];
    if (!tableID) return;
    
    DBTable *table = [self.datastore getTable:tableID];
    DBError *error = nil;
    DBRecord *record = [table getOrInsertRecord:[managedObject valueForKey:self.syncAttributeName] fields:nil inserted:NULL error:&error];
    if (record) {
        [record pk_setFieldsWithManagedObject:managedObject syncAttributeName:self.syncAttributeName];
    } else {
        NSLog(@"Error getting or inserting datatore record: %@", error);
    }
}

- (BOOL)syncDatastore
{
    DBError *error = nil;
    NSDictionary *changes = [self.datastore sync:&error];
    if (changes) {
        if ([self updateCoreDataWithDatastoreChanges:changes]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:PKSyncManagerDatastoreIncomingChangesNotification object:self userInfo:@{PKSyncManagerDatastoreIncomingChangesKey: changes}];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:PKSyncManagerDatastoreLastSyncDateNotification object:self userInfo:@{PKSyncManagerDatastoreLastSyncDateKey: [NSDate date]}];
        
        return YES;
    } else {
        NSLog(@"Error syncing with Dropbox: %@", error);
        return NO;
    }
}

- (NSSet *)syncableManagedObjectsFromManagedObjects:(NSSet *)managedObjects
{
    NSMutableSet *syncableManagedObjects = [[NSMutableSet alloc] init];
    for (NSManagedObject *managedObject in managedObjects) {
        NSString *tableID = [self tableForEntityName:[[managedObject entity] name]];
        if (!tableID) continue;
        
        if ([managedObject respondsToSelector:@selector(isRecordSyncable)]) {
            id<ParcelKitSyncedObject> pkObj = (id<ParcelKitSyncedObject>)managedObject;
            if (![pkObj isRecordSyncable]) {
                continue;
            }
        }
        
        if (![managedObject valueForKey:self.syncAttributeName]) {
            [managedObject setPrimitiveValue:[[self class] syncID] forKey:self.syncAttributeName];
        }
        
        [syncableManagedObjects addObject:managedObject];
    }
    
    return [[NSSet alloc] initWithSet:syncableManagedObjects];
}

@end
