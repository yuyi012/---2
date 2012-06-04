//
//  MemberListController.m
//  ContactsDemo
//
//  Created by 俞 億 on 12-5-8.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "MemberListController.h"
#import <AddressBookUI/AddressBookUI.h>
#import "AppDelegate.h"
#import "pinyin.h"
#import "PersonModel.h"

//#define ABPersonCompositeName(ABRecordRef personRef) 

@interface MemberListController ()

@end



@implementation MemberListController

NSString* ABPersonCompositeName(ABRecordRef personRef){
    NSString *firstName = ABRecordCopyValue(personRef, kABPersonFirstNameProperty);
    NSString *lastName = ABRecordCopyValue(personRef, kABPersonLastNameProperty);
    if (firstName==NULL) {
        firstName = @"";
    }
    if (lastName==NULL) {
        lastName = @"";
    }
    NSString *compositName = [NSString stringWithFormat:@"%@%@",lastName,firstName];
    return compositName;
}

- (void)dealloc
{
    CFRelease(groupRef);
    CFRelease(memberArray);
    [toDeleteIndexPath release];
    [searchBar release];
    [filteredSectionArray release];
    [super dealloc];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
                                               initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                               target:self
                                               action:@selector(addPersonToGroup)]autorelease];
    
    searchBar = [[UISearchBar alloc]initWithFrame:CGRectMake(0, 0, 320, 40)];
    searchBar.delegate = self;
    DataTable.tableHeaderView = searchBar;
}

-(void)addPersonToGroup{
    ABNewPersonViewController *newPersonController = [[ABNewPersonViewController alloc]init];
    newPersonController.newPersonViewDelegate = self;
    AppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    newPersonController.addressBook = appDelegate.addressBookRef;
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:newPersonController];
    [self presentModalViewController:nav animated:YES];
    [newPersonController release];
    [nav release];
}

-(void)setGroupRef:(ABRecordRef)theRef{
    groupRef = CFRetain(theRef);
    //NSLog(@"group:%@",ABRecordCopyValue(groupRef, kABGroupNameProperty));
    self.navigationItem.title = ABRecordCopyValue(groupRef, kABGroupNameProperty);
    //NSLog(@"grouId:%i",ABRecordGetRecordID(groupRef));
    ABRecordID groupId = ABRecordGetRecordID(groupRef);
    AppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    if (groupId>0) {
        CFArrayRef memberArrayRef = ABGroupCopyArrayOfAllMembers(groupRef);
        memberArray = CFArrayCreateMutableCopy(CFAllocatorGetDefault(), CFArrayGetCount(memberArrayRef), memberArrayRef);
    }else {
        CFArrayRef memberArrayRef = ABAddressBookCopyArrayOfAllPeople(appDelegate.addressBookRef);
        memberArray = CFArrayCreateMutableCopy(CFAllocatorGetDefault(), CFArrayGetCount(memberArrayRef), memberArrayRef);
    }
    sectionArray = [[NSMutableArray alloc]init];
    for(NSInteger i=0;i<CFArrayGetCount(memberArray);i++){
        ABRecordRef personRef = CFArrayGetValueAtIndex(memberArray, i);
        PersonModel *personModel = [[PersonModel alloc]init];
        personModel.personRef = personRef;
        NSString *compositName = ABPersonCompositeName(personRef);
        //NSLog(@"compositName:%@",compositName);
        if (compositName.length==0) {
            ABMutableMultiValueRef phoneArray = ABRecordCopyValue(personRef, kABPersonPhoneProperty);
            if (ABMultiValueGetCount(phoneArray)>0) {
                compositName = (NSString*)ABMultiValueCopyValueAtIndex(phoneArray, 0);
                NSLog(@"phone:%@",compositName);
            }
        }
        personModel.compositName = compositName;
        NSString *sectionName = [[NSString stringWithFormat:@"%c",pinyinFirstLetter([compositName characterAtIndex:0])]uppercaseString];
        NSMutableDictionary *preSectionDic = nil;
        for (NSMutableDictionary *sectionDic in sectionArray) {
            NSString *sName = [sectionDic objectForKey:@"sectionName"];
            if ([sName isEqualToString:sectionName]) {
                preSectionDic = sectionDic;
                break;
            }
        }
        if (preSectionDic!=nil) {
            NSMutableArray *sectionMemberArray = [preSectionDic objectForKey:@"memberArray"];
            [sectionMemberArray addObject:personModel];
        }else {
            NSMutableArray *sectionMemberArray = [NSMutableArray array];;
            [sectionMemberArray addObject:personModel];
            preSectionDic = [NSMutableDictionary dictionary];
            [preSectionDic setObject:sectionMemberArray forKey:@"memberArray"];
            [preSectionDic setObject:sectionName forKey:@"sectionName"];
            [sectionArray addObject:preSectionDic];
        }
        [personModel release];
        //NSLog(@"sectionName:%@",sectionName);
    }
    NSSortDescriptor *sectionTitleSort = [NSSortDescriptor sortDescriptorWithKey:@"sectionName" ascending:YES];
    [sectionArray sortUsingDescriptors:[NSArray arrayWithObject:sectionTitleSort]];
    [DataTable reloadData];
}

- (void)searchBar:(UISearchBar *)aSearchBar textDidChange:(NSString *)searchText{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"subquery(memberArray,$x,$x.compositName contains[cd] %@).@count>0",searchText];
    [filteredSectionArray release];
    //filteredSectionArray = [[sectionArray filteredArrayUsingPredicate:predicate]copy];
    filteredSectionArray = [[sectionArray filteredArrayUsingPredicate:predicate]copy];
    for (NSMutableDictionary *sectionDic in filteredSectionArray) {
        NSMutableArray *sectionMemberArray = [sectionDic objectForKey:@"memberArray"];
        NSArray *filteredSectionMemberArray = [sectionMemberArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"compositName contains[cd] %@",searchText]];
        [sectionDic setObject:filteredSectionMemberArray forKey:@"memberArray"];
    }
    [DataTable reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar{
    [searchBar resignFirstResponder];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (searchBar.text.length>0) {
        return filteredSectionArray.count;
    }else {
        return sectionArray.count;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSMutableDictionary *sectionDic;
    if (searchBar.text.length>0) {
        sectionDic = [filteredSectionArray objectAtIndex:section];
    }else {
        sectionDic = [sectionArray objectAtIndex:section];
    }
    NSMutableArray *sectionMemberArray = [sectionDic objectForKey:@"memberArray"];
    return sectionMemberArray.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSMutableDictionary *sectionDic;
    if (searchBar.text.length>0) {
        sectionDic = [filteredSectionArray objectAtIndex:section];
    }else {
        sectionDic = [sectionArray objectAtIndex:section];
    }
    return [sectionDic objectForKey:@"sectionName"];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView{
    NSMutableArray *sectionTitleArray = [NSMutableArray array];
    NSMutableDictionary *sectionDic;
    NSArray *loopArray;
    if (searchBar.text.length>0) {
        loopArray = filteredSectionArray;
    }else {
        loopArray = sectionArray;
    }
    for (NSMutableDictionary *sectionDic in loopArray) {
        [sectionTitleArray addObject:[sectionDic objectForKey:@"sectionName"]];
    }
    return sectionTitleArray;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index{
    return index;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *memberCell = [tableView dequeueReusableCellWithIdentifier:@"memberCell"];
    if (memberCell==nil) {
        memberCell = [[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:@"memberCell"]autorelease];
        UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc]initWithTarget:self
                                                                                          action:@selector(swipeToDelete:)];
        [memberCell.contentView addGestureRecognizer:swipeGesture];
        [swipeGesture release];
    }
    NSMutableDictionary *sectionDic;
    if (searchBar.text.length>0) {
        sectionDic = [filteredSectionArray objectAtIndex:indexPath.section];
    }else {
        sectionDic = [sectionArray objectAtIndex:indexPath.section];
    }
    NSMutableArray *sectionMemberArray = [sectionDic objectForKey:@"memberArray"];
    PersonModel *personModel = [sectionMemberArray objectAtIndex:indexPath.row];;
    NSString *compositName = personModel.compositName;
    memberCell.textLabel.text = compositName;
    
    ABMutableMultiValueRef instantMsgMutltiValue = ABRecordCopyValue(personModel.personRef, kABPersonInstantMessageProperty);
    for (NSInteger i=0; i<ABMultiValueGetCount(instantMsgMutltiValue); i++) {
        CFStringRef label = ABMultiValueCopyLabelAtIndex(instantMsgMutltiValue, i);
        CFStringRef value = ABMultiValueCopyValueAtIndex(instantMsgMutltiValue, i);
        NSLog(@"label:%@,value:%@",label,value);
    }
    //NSLog(@"memberCell:%@",memberCell.textLabel.text);
    return memberCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    ABRecordRef personRef = CFArrayGetValueAtIndex(memberArray, indexPath.row);
    ABPersonViewController *personViewController = [[ABPersonViewController alloc]init];
    personViewController.displayedPerson = personRef;
    personViewController.allowsEditing = YES;
    personViewController.displayedProperties = [NSArray arrayWithObjects:[NSNumber numberWithInt:kABPersonFirstNameProperty],[NSNumber numberWithInt:kABPersonLastNameProperty],[NSNumber numberWithInt:kABPersonPhoneProperty],
                                                [NSNumber numberWithInt:kABPersonEmailProperty],nil];
    [self.navigationController pushViewController:personViewController animated:YES];
    [personViewController release];
}

-(void)swipeToDelete:(UISwipeGestureRecognizer*)theSwipe{
    NSIndexPath *indexPath = [DataTable indexPathForCell:(UITableViewCell*)theSwipe.view.superview];
    NSLog(@"row:%d",indexPath.row);
    [toDeleteIndexPath release];
    toDeleteIndexPath = [indexPath retain];
    [DataTable setEditing:YES animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([indexPath isEqual:toDeleteIndexPath]) {
        return YES;
    }else {
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    ABRecordRef personRef = CFArrayGetValueAtIndex(memberArray, indexPath.row);
    AppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    BOOL removeSucess = ABGroupRemoveMember(groupRef, personRef, NULL);
    ABAddressBookSave(appDelegate.addressBookRef, NULL);
    if (!removeSucess) {
        NSLog(@"remove fail");
    }
    CFArrayRemoveValueAtIndex(memberArray, indexPath.row);
    [DataTable reloadData];
}

- (void)newPersonViewController:(ABNewPersonViewController *)newPersonView didCompleteWithNewPerson:(ABRecordRef)person{
    if (person!=NULL) {
        AppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
        ABAddressBookAddRecord(appDelegate.addressBookRef, groupRef, NULL);
        ABAddressBookSave(appDelegate.addressBookRef, NULL);
        CFArrayAppendValue(memberArray, person);
        CFErrorRef error;
        BOOL addMember = ABGroupAddMember(groupRef, person, &error);
        if (!addMember) {
            NSLog(@"addMember Fail");
        }
        NSLog(@"memberArray:%ld",CFArrayGetCount(memberArray));
        ABAddressBookSave(appDelegate.addressBookRef, NULL);
        [DataTable reloadData];
    }
    [newPersonView dismissModalViewControllerAnimated:YES];
}
@end
