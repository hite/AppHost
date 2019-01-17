//
//  AHDebugWindow.m
//  AppHost
//
//  Created by admin on 14/1/2019.
//  Copyright © 2019 liang. All rights reserved.
//

#import "AHDebugViewController.h"
#import "AppHostEnum.h"

@interface AHDebugViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UIButton *export;
@end

CGFloat kDebugHeadeHeight = 50.f;
@implementation AHDebugViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:self.tableView];
    self.tableView.hidden = YES;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:kDebugHeadeHeight].active = YES;
    [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:kDebugHeadeHeight].active = YES;
    [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
    
    UIButton *toggle = [UIButton new];
    toggle.contentEdgeInsets = UIEdgeInsetsMake(2, 5, 2, 5);
    [toggle setTitle:@"展开" forState:UIControlStateNormal];
    [toggle setTitle:@"收起" forState:UIControlStateSelected];
    [toggle setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    toggle.backgroundColor = [UIColor grayColor];
    [toggle addTarget:self action:@selector(toggleWin:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:toggle];
    
    toggle.translatesAutoresizingMaskIntoConstraints = NO;
    [toggle.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:10].active = YES;
    [toggle.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor constant:0].active = YES;
    // 导出文件按钮
    UIButton *export = [UIButton new];
    export.contentEdgeInsets = UIEdgeInsetsMake(2, 5, 2, 5);
    [export setTitle:@"导出服务器日志" forState:UIControlStateNormal];
    [export setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    export.backgroundColor = [UIColor grayColor];
    [export addTarget:self action:@selector(export:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:export];
    export.hidden = YES;
    self.export = export;
    
    export.translatesAutoresizingMaskIntoConstraints = NO;
    [export.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-5].active = YES;
    [export.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor constant:0].active = YES;
}

#pragma mark - event
- (void)export:(UIButton *)button
{
    NSLog(@"Export access file");
}

- (void)toggleWin:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if (sender.selected && [self.debugViewDelegate respondsToSelector:@selector(tryExpandWindow:)]) {
        [self.debugViewDelegate tryExpandWindow:self];
        self.export.hidden = NO;
        self.tableView.hidden = NO;
    }
    
    if (!sender.selected && [self.debugViewDelegate respondsToSelector:@selector(tryCollapseWindow:)]) {
        [self.debugViewDelegate tryCollapseWindow:self];
        self.export.hidden = YES;
        self.tableView.hidden = YES;
    }
}

#pragma mark - tableView Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *kIdentiferOfReuseable = @"kIdentiferOfReuseable";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kIdentiferOfReuseable];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kIdentiferOfReuseable];
        cell.textLabel.text = @"what does happened?";
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - getter

- (UITableView *)tableView{
    if (_tableView == nil) {
        
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth| UIViewAutoresizingFlexibleHeight;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = AHColorFromRGB(0xF8F8F8);
        _tableView.separatorColor = [UIColor whiteColor];
        _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.01)];
        _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        //
    }
    return _tableView;
}

@end
