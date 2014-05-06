// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Author.h instead.

#import <CoreData/CoreData.h>


extern const struct AuthorAttributes {
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *syncID;
} AuthorAttributes;

extern const struct AuthorRelationships {
	__unsafe_unretained NSString *books;
} AuthorRelationships;

extern const struct AuthorFetchedProperties {
} AuthorFetchedProperties;

@class NSManagedObject;




@interface AuthorID : NSManagedObjectID {}
@end

@interface _Author : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (AuthorID*)objectID;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* syncID;



//- (BOOL)validateSyncID:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSOrderedSet *books;

- (NSMutableOrderedSet*)booksSet;





@end

@interface _Author (CoreDataGeneratedAccessors)

- (void)addBooks:(NSOrderedSet*)value_;
- (void)removeBooks:(NSOrderedSet*)value_;
- (void)addBooksObject:(NSManagedObject*)value_;
- (void)removeBooksObject:(NSManagedObject*)value_;

@end

@interface _Author (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSString*)primitiveSyncID;
- (void)setPrimitiveSyncID:(NSString*)value;





- (NSMutableOrderedSet*)primitiveBooks;
- (void)setPrimitiveBooks:(NSMutableOrderedSet*)value;


@end
