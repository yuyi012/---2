//
//  PersonModel.m
//  ContactsDemo
//
//  Created by 俞 億 on 12-5-9.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PersonModel.h"

@implementation PersonModel
@synthesize compositName;
@synthesize personRef;
- (void)dealloc
{
    [compositName release];
    [super dealloc];
}
@end
