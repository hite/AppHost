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
    self.title = @"控制台";
    self.view.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.tableView];
    
    UIBarButtonItem *closeBar = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(close:)];
    self.navigationItem.leftBarButtonItem = closeBar;
    
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:0].active = YES;
    [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:0].active = YES;
    [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;

    // 导出文件按钮在下面的右边
    UIBarButtonItem *exportBar = [[UIBarButtonItem alloc] initWithTitle:@"日志导出" style:UIBarButtonItemStylePlain target:self action:@selector(export:)];
    // 刷新日志按钮在左边
    UIBarButtonItem *refreshBar = [[UIBarButtonItem alloc] initWithTitle:@"刷新" style:UIBarButtonItemStylePlain target:self action:@selector(refresh:)];
    self.navigationItem.rightBarButtonItems = @[exportBar, refreshBar];
}

#pragma mark -

- (void)onWindowHide
{
    self.navigationController.navigationBarHidden = YES;
    self.view.hidden = YES;
}

- (void)onWindowShow
{
    self.navigationController.navigationBarHidden = NO;
    self.view.hidden = NO;
    if (self.dataSource.count == 0) {
        [self refresh:nil];
    }
}

- (void)showNewLine:(NSArray<NSString *> *)line
{
    self.dataSource = [self.dataSource arrayByAddingObjectsFromArray:line];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}
#pragma mark - event
- (void)close:(UIButton *)button
{
    if ([self.debugViewDelegate respondsToSelector:@selector(onCloseWindow:)]){
        [self.debugViewDelegate onCloseWindow:self];
    }
}

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

#pragma mark - context menu
//允许 Menu菜单
- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

//每个cell都会点击出现Menu菜单
- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(copy:)) {
        return YES;
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(copy:)) {
        [UIPasteboard generalPasteboard].string = [self.dataSource objectAtIndex:indexPath.row];
    }
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
