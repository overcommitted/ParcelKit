//
//  PKDatastoreStatusMock.m
//  ParcelKit
//
//  Created by Jonathan Younger on 6/19/14.
//  Copyright (c) 2014 Overcommitted, LLC. All rights reserved.
//

#import "PKDatastoreStatusMock.h"

@implementation PKDatastoreStatusMock

+ (instancetype)datastoreStatusWithIncoming:(BOOL)incoming
{
    PKDatastoreStatusMock *datastoreStatus = [[PKDatastoreStatusMock alloc] init];
    datastoreStatus.incoming = incoming;
    return datastoreStatus;
}

@end
