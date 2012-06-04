//
//  PersonModel.h
//  ContactsDemo
//
//  Created by 俞 億 on 12-5-9.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@interface PersonModel : NSObject
@property(nonatomic,retain) NSString *compositName;
@property(nonatomic,readwrite) ABRecordRef personRef;
@end
