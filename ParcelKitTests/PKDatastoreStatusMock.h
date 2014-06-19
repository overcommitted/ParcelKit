//
//  PKDatastoreStatusMock.h
//  ParcelKit
//
//  Created by Jonathan Younger on 6/19/14.
//  Copyright (c) 2014 Overcommitted, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PKDatastoreStatusMock : NSObject
@property (nonatomic) BOOL connected;
@property (nonatomic) BOOL downloading;
@property (nonatomic) BOOL uploading;
@property (nonatomic) BOOL incoming;
@property (nonatomic) BOOL outgoing;

+ (instancetype)datastoreStatusWithIncoming:(BOOL)incoming;
@end
