//
//  MDSArticleDetailViewController.m
//  Meditashayne
//
//  Created by 杨淳引 on 16/2/3.
//  Copyright © 2016年 shayneyeorg. All rights reserved.
//

#import "MDSArticleDetailViewController.h"
#import "SVProgressHUD.h"

@interface MDSArticleDetailViewController ()

@property (strong, nonatomic) NSManagedObjectID *objectID;//当前正在编辑的随笔的id(新建随笔则无值)

@property (weak, nonatomic) IBOutlet UITextField *titleField;
@property (weak, nonatomic) IBOutlet UITextView *contentField;
@property (weak, nonatomic) IBOutlet UIButton *deleteBtn; //删除按钮


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentFieldBottomInset;//随笔内容框与底部的距离
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *seperatorLineHeight;


@end

@implementation MDSArticleDetailViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configViewDetails];
    [self configBackBarBtn];
    [self configSaveBarBtn];
    [self addKeyboardNotification];
}

- (void)dealloc {
    MDSLog(@"dealloc");
    [self removeKeyboardNotification];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Private

- (void)configViewDetails {
    self.seperatorLineHeight.constant = 0.5;
    
    if (self.alteringArticle) {
        //在修改的状态下
        self.titleField.text = self.alteringArticle.title;
        self.contentField.text = [[NSString alloc]initWithData:self.alteringArticle.content encoding:NSUTF8StringEncoding];
        self.objectID = self.alteringArticle.objectID;
        self.deleteBtn.hidden = NO;
        
    } else {
        //新建状态下
        NSDate *now = [NSDate date];
        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
        [formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"zh-CN"]];
        [formatter setDateFormat:@"yyyy-MM-dd "];
        NSString *nowStr = [formatter stringFromDate:now];
        self.titleField.text = nowStr;
        self.deleteBtn.hidden = YES;
    }
}

- (void)configBackBarBtn {
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(0, 0, 44, 44);
    [backBtn setTitle:@"<返回" forState:UIControlStateNormal];
    [backBtn setTitleColor:RGB(50, 50, 50) forState:UIControlStateNormal];
    backBtn.titleLabel.font = [UIFont systemFontOfSize:16.f];
    [backBtn addTarget:self action:@selector(popBack:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = backItem;
}

- (void)configSaveBarBtn {
    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    saveBtn.frame = CGRectMake(0, 0, 44, 44);
    [saveBtn setTitle:@"保存" forState:UIControlStateNormal];
    [saveBtn setTitleColor:RGB(50, 50, 50) forState:UIControlStateNormal];
    saveBtn.titleLabel.font = [UIFont systemFontOfSize:16.f];
    [saveBtn addTarget:self action:@selector(saveArticle:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *saveItem = [[UIBarButtonItem alloc] initWithCustomView:saveBtn];
    self.navigationItem.rightBarButtonItem = saveItem;
}

- (void)popBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)saveArticle:(id)sender {
    [self.view endEditing:YES];
    
    //判断保存内容是否合法
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    if (!self.titleField.text.length) {
        [SVProgressHUD showErrorWithStatus:@"标题不可为空"];
        [self.titleField becomeFirstResponder];
        return;
        
    } else if (!self.contentField.text.length) {
        [SVProgressHUD showErrorWithStatus:@"内容不可为空"];
        [self.contentField becomeFirstResponder];
        return;
    }
    
    //保存
    if (self.alteringArticle) {
        //修改随笔
        [MDSCoreDataAccess updateArticleWithObjectID:self.objectID title:self.titleField.text content:self.contentField.text];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.alteringArticleIndexPath, @"indexPath", self.objectID, @"objectID", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:ARTICLE_ALTER_NOTIFICATION object:nil userInfo:userInfo];
        [SVProgressHUD showSuccessWithStatus:@"修改成功"];
        
    } else {
        //新增随笔
        self.alteringArticle = [MDSCoreDataAccess addArticleWithTitle:self.titleField.text content:self.contentField.text];
        self.objectID = self.alteringArticle.objectID;
        self.alteringArticleIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [[NSNotificationCenter defaultCenter] postNotificationName:ARTICLE_CREATE_NOTIFICATION object:nil userInfo:nil];
        [SVProgressHUD showSuccessWithStatus:@"保存成功"];
        self.deleteBtn.hidden = NO;
    }
}

- (IBAction)deleteArticle:(id)sender {
    //删除随笔
    if (self.alteringArticle) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"删除随笔" message:@"确定删除当前随笔？" preferredStyle:UIAlertControllerStyleActionSheet];
        
        __weak typeof(self) weakSelf = self;
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            MDSLog(@"action");
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
            if ([MDSCoreDataAccess removeArticle:self.alteringArticle]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:ARTICLE_CREATE_NOTIFICATION object:nil userInfo:nil];
                [SVProgressHUD showSuccessWithStatus:@"删除成功"];
                [weakSelf.navigationController popViewControllerAnimated:YES];
                
            } else {
                [SVProgressHUD showErrorWithStatus:@"删除失败"];
            }
        }];
        [alertController addAction:okAction];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:cancelAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}


#pragma mark - Keyboard Notification

- (void)addKeyboardNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)removeKeyboardNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    //获取键盘的y值
    NSDictionary *userInfo = [notification userInfo];
    NSValue *value = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [value CGRectValue];
    CGFloat keyboardHeight = keyboardRect.size.height + 5;
    
    //如果键盘挡住了随笔内容，将内容框缩短
    self.contentFieldBottomInset.constant = keyboardHeight;
}

- (void)keyboardWillHide:(NSNotification *)notification {
    //将随笔内容框恢复原本高度
    self.contentFieldBottomInset.constant = 46;
}

@end
