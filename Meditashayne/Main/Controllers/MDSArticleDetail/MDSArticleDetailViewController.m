//
//  MDSArticleDetailViewController.m
//  Meditashayne
//
//  Created by 杨淳引 on 16/2/3.
//  Copyright © 2016年 shayneyeorg. All rights reserved.
//

#import "MDSArticleDetailViewController.h"

@interface MDSArticleDetailViewController ()

@property (strong, nonatomic) NSManagedObjectID *objectID;
@property (weak, nonatomic) AppDelegate *appDelegate;

@property (weak, nonatomic) IBOutlet UITextField *titleField;
@property (weak, nonatomic) IBOutlet UITextView *contentField;

@end

@implementation MDSArticleDetailViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configBackBtn];
    [self configDetails];
    [self setPopGestureEnabled:NO];
}

- (void)dealloc {
    MDSLog(@"dealloc");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Private

- (void)setPopGestureEnabled:(BOOL)isEnabled {
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = isEnabled;
    }
}

- (void)configDetails {
    self.appDelegate = kApp;
}

- (void)configBackBtn {
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(0, 0, 44, 44);
    [backBtn setTitle:@"<返回" forState:UIControlStateNormal];
    [backBtn setTitleColor:RGB(50, 50, 50) forState:UIControlStateNormal];
    backBtn.titleLabel.font = [UIFont systemFontOfSize:16.f];
    [backBtn addTarget:self action:@selector(popBack:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = backItem;
}

- (void)popBack:(id)sender {
    if (!self.titleField.text.length) {
        MDSLog(@"标题不可为空");
        
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - UITextFieldAction

- (IBAction)editingChanged:(id)sender {
    [self setPopGestureEnabled:YES];
    
    NSString *newStr = [(UITextField *)sender text];
//    MDSLog(@"%@", newStr);
    if (!newStr.length) {
        [self setPopGestureEnabled:NO];
    }
}

#pragma mark - Core Data

//新增数据
- (void)addArticle {
    NSString *title = self.titleField.text;
    NSString *content = self.contentField.text;
    
    Article *article = [NSEntityDescription insertNewObjectForEntityForName:@"Article" inManagedObjectContext:self.appDelegate.managedObjectContext];
    
    article.title = title;
    article.content = [content dataUsingEncoding:NSUTF8StringEncoding];
    article.createTime = [NSDate date];
    
    NSError *error = nil;
    if ([self.appDelegate.managedObjectContext save:&error]) {
        if (error) MDSLog(@"新增时发生错误:%@,%@",error,[error userInfo]);
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

//修改数据
- (void)alterArticle {
    Article *article = [self.appDelegate.managedObjectContext objectWithID:self.objectID];
    article.title = self.titleField.text;
    article.content = [self.contentField.text dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error = nil;
    if ([self.appDelegate.managedObjectContext save:&error]) MDSLog(@"修改成功");
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
