/* Copyright (c) 2013 Dropbox, Inc. All rights reserved. */


/** An object that allows you to modify a list that is set as a value on a [record](DBRecord).
 Lists can contain the same values as records, except for other lists. Any changes you make to the
 list are intelligently merged with changes made remotely. */
@interface DBList : NSObject

/** Returns the total number of items in the list. */
- (NSUInteger)count;

/** Returns the object at the given index. */
- (id)objectAtIndex:(NSUInteger)index;

- (id)objectAtIndexedSubscript:(NSUInteger)index;

/** Inserts an object at the given index, moving other objects further down the list. */
- (void)insertObject:(id)obj atIndex:(NSUInteger)index;

/** Removes the object at the given index. */
- (void)removeObjectAtIndex:(NSUInteger)index;

/** Adds an object to the end of the list. */
- (void)addObject:(id)obj;

/** Removes the last object from the list. */
- (void)removeLastObject;

/** Replaces the item at the given index with the given object. */
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)obj;

- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx;

/** Moves the object from the given old idnex, so that it appears at the
 given new index. */
- (void)moveObjectAtIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex;

/** Returns all objects in the list. */
@property (nonatomic, readonly) NSArray *values;

@end
