//
//  MemberListController.h
//  ContactsDemo
//
//  Created by 俞 億 on 12-5-8.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>

@interface MemberListController : UIViewController<UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate>{
    ABRecordRef groupRef;
    CFMutableArrayRef memberArray;
    IBOutlet UITableView *DataTable;
    NSIndexPath *toDeleteIndexPath;
    NSMutableArray *sectionArray;
    UISearchBar *searchBar;
    NSMutableArray *filteredSectionArray;
}
-(void)setGroupRef:(ABRecordRef)theRef;
@end
