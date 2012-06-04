//
//  ViewController.m
//  ContactsDemo
//
//  Created by delacro on 12-5-3.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import <AddressBook/AddressBook.h>
#import "MemberListController.h"
#import "AppDelegate.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    AppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
//    NSArray *peopleArray = (NSArray*)ABAddressBookCopyArrayOfAllPeople(addressBookRef);
    CFArrayRef groupRefArray = ABAddressBookCopyArrayOfAllGroups(appDelegate.addressBookRef);
    groupArray = CFArrayCreateMutableCopy(CFAllocatorGetDefault(), CFArrayGetCount(groupRefArray), groupRefArray);
    ABRecordRef allGroupRef = ABGroupCreate();
    ABRecordSetValue(allGroupRef, kABGroupNameProperty, @"所有联系人", NULL);
    CFArrayInsertValueAtIndex(groupArray, 0, allGroupRef);
    
    NSString *contactListPath = [[NSBundle mainBundle]pathForResource:@"contactList" ofType:@"plist"];
    NSArray *contactArray = [NSArray arrayWithContentsOfFile:contactListPath];
    if (CFArrayGetCount(groupArray)==0) {
        for (NSDictionary *groupDic in contactArray) {
            NSString *groupName = [groupDic objectForKey:@"groupName"];
            NSLog(@"groupName:%@",groupName);
            ABRecordRef groupRef = ABGroupCreate();
            ABRecordSetValue(groupRef, kABGroupNameProperty, groupName, NULL);
            ABAddressBookAddRecord(appDelegate.addressBookRef, groupRef, NULL);
            CFRelease(groupRef);
        }
        ABAddressBookSave(appDelegate.addressBookRef, NULL);
        CFArrayRef groupRefArray = ABAddressBookCopyArrayOfAllGroups(appDelegate.addressBookRef);
        for (NSDictionary *groupDic in contactArray) {
            NSString *groupName = [groupDic objectForKey:@"groupName"];
            //NSLog(@"groupName:%@",groupName);
            for (NSInteger i=0; i<CFArrayGetCount(groupRefArray); i++) {
                ABRecordRef groupRef = CFArrayGetValueAtIndex(groupRefArray, i);
                NSString *groupRefName = (NSString*)ABRecordCopyValue(groupRef, kABGroupNameProperty);
                if ([groupRefName isEqualToString:groupName]) {
                    NSArray *memberArray = [groupDic objectForKey:@"memberArray"];
                    for (NSString *memberName in memberArray) {
                        ABRecordRef memberRef = ABPersonCreate();
                        NSLog(@"memberName:%@",memberName);
                        ABRecordSetValue(memberRef, kABPersonLastNameProperty, memberName, NULL);
                        ABAddressBookAddRecord(appDelegate.addressBookRef, memberRef, NULL);
                        ABAddressBookSave(appDelegate.addressBookRef, NULL);
                        CFErrorRef error =  NULL;
                        BOOL added = ABGroupAddMember(groupRef, memberRef, &error);
                        ABAddressBookSave(appDelegate.addressBookRef, NULL);
                        if (error!=NULL) {
                            NSLog(@"error:%@",(NSString*)CFErrorGetDomain(error));
                        }
                        if (added) {
                            NSLog(@"added");
                        }else {
                            NSLog(@"not added");
                        }
                        CFRelease(memberRef);
                    }
                    break;
                }
            }
        }
    }
    ABAddressBookSave(appDelegate.addressBookRef, NULL);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return CFArrayGetCount(groupArray);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *groupCell = [tableView dequeueReusableCellWithIdentifier:@"groupCell"];
    if (groupCell==nil) {
        groupCell = [[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:@"groupCell"]autorelease];
    }
    ABRecordRef groupRef = CFArrayGetValueAtIndex(groupArray, indexPath.row);
    groupCell.textLabel.text = ABRecordCopyValue(groupRef, kABGroupNameProperty);
    return groupCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    MemberListController *memberListController = [[MemberListController alloc]init];
    ABRecordRef groupRef = CFArrayGetValueAtIndex(groupArray, indexPath.row);
    [memberListController setGroupRef:groupRef];
    [self.navigationController pushViewController:memberListController animated:YES];
    [memberListController release];
}
@end
