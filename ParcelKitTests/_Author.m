// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Author.m instead.

#import "_Author.h"

const struct AuthorAttributes AuthorAttributes = {
	.name = @"name",
	.syncID = @"syncID",
};

const struct AuthorRelationships AuthorRelationships = {
	.books = @"books",
};

const struct AuthorFetchedProperties AuthorFetchedProperties = {
};

@implementation AuthorID
@end

@implementation _Author

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Author" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Author";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Author" inManagedObjectContext:moc_];
}

- (AuthorID*)objectID {
	return (AuthorID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic name;






@dynamic syncID;






@dynamic books;

	
- (NSMutableOrderedSet*)booksSet {
	[self willAccessValueForKey:@"books"];
  
	NSMutableOrderedSet *result = (NSMutableOrderedSet*)[self mutableOrderedSetValueForKey:@"books"];
  
	[self didAccessValueForKey:@"books"];
	return result;
}
	






@end
