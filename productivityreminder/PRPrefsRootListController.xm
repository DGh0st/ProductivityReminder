#include "PRPrefsRootListController.h"

#define kSettingsPlist @"/var/mobile/Library/Preferences/com.dgh0st.productivityreminder.plist"

@implementation PRPrefsRootListController

- (id)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"ProductivityReminder" target:self] retain];
	}

	return _specifiers;
}

-(void)email{
	if([MFMailComposeViewController canSendMail]){
		MFMailComposeViewController *email = [[MFMailComposeViewController alloc] initWithNibName:nil bundle:nil];
		[email setSubject:@"ProductivityReminder Support"];
		[email setToRecipients:[NSArray arrayWithObjects:@"deeppwnage@yahoo.com", nil]];
		[email addAttachmentData:[NSData dataWithContentsOfFile:kSettingsPlist] mimeType:@"application/xml" fileName:@"Prefs.plist"];
		#pragma GCC diagnostic push
		#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
		system("/usr/bin/dpkg -l >/tmp/dpkgl.log");
		#pragma GCC diagnostic pop
		[email addAttachmentData:[NSData dataWithContentsOfFile:@"/tmp/dpkgl.log"] mimeType:@"text/plain" fileName:@"dpkgl.txt"];
		[self.navigationController presentViewController:email animated:YES completion:nil];
		[email setMailComposeDelegate:self];
		[email release];
	}
}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated: YES completion: nil];
}

-(void)donate{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=deeppwnage%40yahoo%2ecom&lc=US&item_name=DGh0st&item_number=DGh0st%20Tweak%20Inc%20%28Wow%20I%20own%20a%20company%29&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donate_LG%2egif%3aNonHostedGuest"]];
}

-(void)follow{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://mobile.twitter.com/D_Gh0st"]];
}

-(void)save{
    [self.view endEditing:YES];
}

@end

@implementation PRPrefsAppsController

-(id)init {
	if ((self = [super init])) {
		CGSize size = [[UIScreen mainScreen] bounds].size;

		NSNumber *iconSize = [NSNumber numberWithUnsignedInteger:ALApplicationIconSizeSmall];

		_dataSource = [[ALApplicationTableDataSource alloc] init];
		_dataSource.sectionDescriptors = [NSArray arrayWithObjects:
			[NSDictionary dictionaryWithObjectsAndKeys:
				@"System Applications", ALSectionDescriptorTitleKey,
				@"ALDisclosureIndicatedCell", ALSectionDescriptorCellClassNameKey,
				iconSize, ALSectionDescriptorIconSizeKey,
				@YES, ALSectionDescriptorSuppressHiddenAppsKey,
				@"isSystemApplication = TRUE", ALSectionDescriptorPredicateKey
			, nil],
			[NSDictionary dictionaryWithObjectsAndKeys:
				@"User Applications", ALSectionDescriptorTitleKey,
				@"ALDisclosureIndicatedCell", ALSectionDescriptorCellClassNameKey,
				iconSize, ALSectionDescriptorIconSizeKey,
				@YES, ALSectionDescriptorSuppressHiddenAppsKey,
				@"isSystemApplication = FALSE", ALSectionDescriptorPredicateKey
			, nil]
		, nil];

		_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height) style:UITableViewStyleGrouped];
		_tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_tableView.delegate = self;
		_tableView.dataSource = _dataSource;
		_dataSource.tableView = _tableView;

		[_tableView reloadData];
	}
	return self;
}

-(void)viewDidLoad {
	((UIViewController *)self).title = @"Applications";
	[self.view addSubview:_tableView];
	[super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

-(void)dealloc {
	_tableView.delegate = nil;
	[super dealloc];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = (UITableViewCell *)[_tableView cellForRowAtIndexPath:indexPath];
	NSString *appName = cell.textLabel.text;
	NSString *appIdentifier = [_dataSource displayIdentifierForIndexPath:indexPath];

	PRPrefsPerAppController *controller = [[PRPrefsPerAppController alloc] initWithAppName:appName displayIdentifier:appIdentifier];
	controller.rootController = self.rootController;
	controller.parentController = self;

	[self pushController:controller];
	[tableView deselectRowAtIndexPath:indexPath animated:true];
}

@end

@implementation PRPrefsPerAppController

-(id)specifiers {
	if (!_specifiers) {
		NSMutableArray *specifiers = (NSMutableArray *)[[self loadSpecifiersFromPlistName:@"PerApp" target:self] retain];
		for (PSSpecifier *spec in specifiers) {
			[spec setProperty:[NSString stringWithFormat:@"%@-%@", [spec propertyForKey:@"key"], _displayIdentifier] forKey:@"key"];
		}

		_specifiers = specifiers;
	}

	return _specifiers;
}

-(id)init {
	return self = [super init];
}

- (id)initWithAppName:(NSString *)appName displayIdentifier:(NSString *)displayIdentifier {
	_appName = appName;
	_displayIdentifier = displayIdentifier;
	return [self init];
}

-(void)viewDidLoad {
	((UIViewController *)self).title = _appName;
	[self specifiers];
}

-(void)save{
    [self.view endEditing:YES];
}

@end