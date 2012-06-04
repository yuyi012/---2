//
//  ViewController.h
//  ContactsDemo
//
//  Created by delacro on 12-5-3.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>{
    CFMutableArrayRef groupArray;
}
@end
