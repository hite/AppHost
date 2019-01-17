//
//  AHDebugWindow.m
//  AppHost
//
//  Created by admin on 14/1/2019.
//  Copyright © 2019 liang. All rights reserved.
//

#import "AHDebugViewController.h"
#import "AppHostEnum.h"
#import "GCDWebServer.h"

@interface AHDebugViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UIButton *export;
@property (nonatomic, strong) UIButton *refresh;

@property (nonatomic, strong) NSArray<NSString *> *dataSource;

@end

CGFloat kDebugHeadeHeight = 46.f;
@implementation AHDebugViewController

- (instancetype)init
{
    if (self = [super init]) {
        self.dataSource = [NSMutableArray arrayWithCapacity:10];
    }
    return self;
}

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
    // 导出文件按钮在下面的右边
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
    [export.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-15].active = YES;
    // 刷新日志按钮在左边
    UIButton *refresh = [UIButton new];
    refresh.contentEdgeInsets = UIEdgeInsetsMake(2, 5, 2, 5);
    [refresh setTitle:@"刷新" forState:UIControlStateNormal];
    [refresh setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    refresh.backgroundColor = [UIColor grayColor];
    [refresh addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:refresh];
    refresh.hidden = YES;
    self.refresh = refresh;
    
    refresh.translatesAutoresizingMaskIntoConstraints = NO;
    [refresh.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-5].active = YES;
    [refresh.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:15].active = YES;
}

- (void)showNewLine:(NSArray<NSString *> *)line
{
    self.dataSource = [self.dataSource arrayByAddingObjectsFromArray:line];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}
#pragma mark - event
- (void)export:(UIButton *)button
{
    NSLog(@"Export access file");
    NSString *docsdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *logFile = [docsdir stringByAppendingPathComponent:GCDWebServer_accessLogFileName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:logFile]) {
        NSURL *videoURL = [NSURL fileURLWithPath:logFile];
        
        UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[videoURL] applicationActivities:nil];
        UIPopoverPresentationController *popover = activity.popoverPresentationController;
        if (popover) {
            popover.permittedArrowDirections = UIPopoverArrowDirectionUp;
        }
        [self presentViewController:activity animated:YES completion:NULL];
    }
}

- (void)refresh:(UIButton *)button
{
    if ([self.debugViewDelegate respondsToSelector:@selector(fetchData:completion:)]){
        [self.debugViewDelegate fetchData:self completion:^(NSArray<NSString *> * _Nonnull lines) {
            [self showNewLine:lines];
        }];
    }
}

- (void)toggleWin:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if (sender.selected && [self.debugViewDelegate respondsToSelector:@selector(tryExpandWindow:)]) {
        [self.debugViewDelegate tryExpandWindow:self];
        self.export.hidden = NO;
        self.refresh.hidden = NO;
        self.tableView.hidden = NO;
        
        if (self.dataSource.count == 0) {
            [self refresh:nil];
        }
    }
    
    if (!sender.selected && [self.debugViewDelegate respondsToSelector:@selector(tryCollapseWindow:)]) {
        [self.debugViewDelegate tryCollapseWindow:self];
        self.export.hidden = YES;
        self.refresh.hidden = YES;
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
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *kIdentiferOfReuseable = @"kIdentiferOfReuseable";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kIdentiferOfReuseable];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kIdentiferOfReuseable];
        cell.textLabel.numberOfLines = -1;
        
        UIView *label = cell.textLabel, *contentView = cell.contentView;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [label.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:10].active = YES;
        [label.leftAnchor constraintEqualToAnchor:contentView.leftAnchor constant:10].active = YES;
        [label.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor constant:-10].active = YES;
        [label.rightAnchor constraintEqualToAnchor:contentView.rightAnchor constant:-10].active = YES;
    }
    
    if (indexPath.row < self.dataSource.count) {
        cell.textLabel.text = [self.dataSource objectAtIndex:indexPath.row];
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
//        _tableView.separatorColor = [UIColor whiteColor];
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.estimatedRowHeight = 50.f;
        _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.01)];
        _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        //
    }
    return _tableView;
}

@end
