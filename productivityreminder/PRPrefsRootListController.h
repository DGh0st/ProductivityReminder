#import <Preferences/Preferences.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <AppList/AppList.h>
#import <UIKit/UIKit.h>

@interface PSListController (ProductivityReminder)
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion;
- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion;
- (UINavigationController*)navigationController;
@end

@interface PRPrefsRootListController : PSListController <MFMailComposeViewControllerDelegate>

@end

@interface PRPrefsAppsController : PSViewController <UITableViewDelegate> {
	UITableView *_tableView;
	ALApplicationTableDataSource *_dataSource;
}
@end

@interface PRPrefsPerAppController : PSListController {
	NSString *_appName;
	NSString *_displayIdentifier;
}
- (id)initWithAppName:(NSString *)appName displayIdentifier:(NSString *)displayIdentifier;
@end