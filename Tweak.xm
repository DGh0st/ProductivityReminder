#include <UIKit/UIKit.h>

#define kIdentifier @"com.dgh0st.productivityreminder"
#define kSettingsChangedNotification (CFStringRef)@"com.dgh0st.productivityreminder/settingschanged"
#define kSettingsPath @"/var/mobile/Library/Preferences/com.dgh0st.productivityreminder.plist"

static BOOL isEnabled = YES;
static NSString *alertMessage = @"You've been on [app] for [min]. Are you sure you couldn't be using your time better?";
static NSString *buttonMessage = @"Thanks for the suggestion!";
static BOOL isSnoozeEnabled = NO;
static BOOL isOverrideEnabled = NO;
static NSString *snoozeMessage = @"Snooze for [min].";
BOOL perAppEnabled = NO;
CGFloat perAppAlertDelay = 600;
CGFloat perAppAlertSnooze = 180;


NSDictionary *prefs = nil;

static void reloadPrefs() {
	if ([NSHomeDirectory() isEqualToString:@"/var/mobile"]) {
		CFArrayRef keyList = CFPreferencesCopyKeyList((CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (keyList) {
			prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, (CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			if (!prefs) {
				prefs = [NSDictionary new];
			}
			CFRelease(keyList);
		}
	} else {
		prefs = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];
	}
}

static BOOL boolValueForKey(NSString *key, BOOL defaultValue) {
	return (prefs && [prefs objectForKey:key]) ? [[prefs objectForKey:key] boolValue] : defaultValue;
}

static CGFloat doubleValuePerApp(NSString *appId, NSString *prefix, CGFloat defaultValue) {
	if (prefs) {
		for (NSString *key in [prefs allKeys]) {
			if ([key hasPrefix:prefix]) {
				NSString *tempId = [key substringFromIndex:[prefix length]];
				if ([tempId isEqualToString:appId]) {
					return [prefs objectForKey:key] ? [[prefs objectForKey:key] floatValue] : defaultValue;
				}
			}
		}
	}
	return defaultValue;
}

static BOOL boolValuePerApp(NSString *appId, NSString *prefix, BOOL defaultValue) {
	if (prefs) {
		for (NSString *key in [prefs allKeys]) {
			if ([key hasPrefix:prefix]) {
				NSString *tempId = [key substringFromIndex:[prefix length]];
				if ([tempId isEqualToString:appId]) {
					return [prefs objectForKey:key] ? [[prefs objectForKey:key] boolValue] : defaultValue;
				}
			}
		}
	}
	return defaultValue;
}

static NSString *stringValueForKey(NSString *key, NSString *defaultValue) {
	return (prefs && [prefs objectForKey:key]) ? [prefs objectForKey:key] : defaultValue;
}

static void preferencesChanged() {
	CFPreferencesAppSynchronize((CFStringRef)kIdentifier);
	reloadPrefs();

	isEnabled = boolValueForKey(@"isEnabled", YES);
	alertMessage = stringValueForKey(@"alertMessage", @"You've been on [app] for [min]. Are you sure you couldn't be using your time better?");
	buttonMessage = stringValueForKey(@"buttonMessage", @"Thanks for the suggestion!");
	isSnoozeEnabled = boolValueForKey(@"isSnoozeEnabled", NO);
	isOverrideEnabled = boolValueForKey(@"isOverrideEnabled", NO);
	snoozeMessage = stringValueForKey(@"snoozeMessage", @"Snooze for [min].");
	perAppEnabled = boolValuePerApp([[NSBundle mainBundle] bundleIdentifier], @"AppEnabled-", NO);
	perAppAlertDelay = doubleValuePerApp([[NSBundle mainBundle] bundleIdentifier], @"AlertDelay-", 0.0f) * 60;
	perAppAlertSnooze = doubleValuePerApp([[NSBundle mainBundle] bundleIdentifier], @"AlertSnooze-", 0.0f) * 60;
}

%group applications
BOOL shouldDisplayAlert = NO;
NSInteger numberOfSnoozes = 0;
UIAlertController *alert = nil;

%hook UIViewController
-(void)viewDidLoad {
	%orig;
	if (perAppEnabled) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startAlertTimer) name:UIApplicationDidBecomeActiveNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopAlertTimer) name:UIApplicationWillResignActiveNotification object:nil];
	}
}

%new
-(void)startAlertTimer {
	if (!shouldDisplayAlert) {
		shouldDisplayAlert = YES;
		numberOfSnoozes = 0;
		[self performSelector:@selector(displayAlert) withObject:nil afterDelay:perAppAlertDelay];
	}
}

%new
-(void)stopAlertTimer {
	if (shouldDisplayAlert) {
		shouldDisplayAlert = NO;
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(displayAlert) object:nil];
	}
	if (alert != nil) {
		[alert dismissViewControllerAnimated:NO completion:nil];
		alert = nil;
	}
}

%new
-(void)displayAlert {
	if (shouldDisplayAlert) {
		shouldDisplayAlert = NO;

		NSString *appName = [[NSBundle bundleWithIdentifier:[[NSBundle mainBundle] bundleIdentifier]] objectForInfoDictionaryKey:@"CFBundleExecutable"];
		NSString *_alertMessage = [alertMessage copy];
		NSString *_snoozeMessage = [snoozeMessage copy];
		NSString *_buttonMessage = [buttonMessage copy];

		// error checking
		if (appName == nil) {
			appName = @"";
		}
		if (_alertMessage == nil) {
			_alertMessage = @"";
		}
		if (_snoozeMessage == nil) {
			_snoozeMessage = @"";
		}
		if (_buttonMessage == nil) {
			_buttonMessage = @"";
		}

		// replace [app] and [min] in _alertMessage
		NSInteger timeInSeconds = perAppAlertDelay + perAppAlertSnooze * numberOfSnoozes;
		NSString *_alertTime = @"";
		if (timeInSeconds / 60 > 0) {
			_alertTime = [_alertTime stringByAppendingString:[NSString stringWithFormat:@"%zd minutes", timeInSeconds / 60]];
			if (timeInSeconds % 60 > 0) {
				_alertTime = [_alertTime stringByAppendingString:[NSString stringWithFormat:@" %zd seconds", timeInSeconds % 60]];
			}
		} else if (timeInSeconds % 60 > 0) {
			_alertTime = [_alertTime stringByAppendingString:[NSString stringWithFormat:@"%zd seconds", timeInSeconds % 60]];
		}

		_alertMessage = [_alertMessage stringByReplacingOccurrencesOfString:@"[app]" withString:appName];
		_alertMessage = [_alertMessage stringByReplacingOccurrencesOfString:@"[min]" withString:_alertTime];

		// replace [min] in _snoozeMessage
		timeInSeconds = perAppAlertSnooze;
		NSString *_snoozeTime = @"";
		if (timeInSeconds / 60 > 0) {
			_snoozeTime = [_snoozeTime stringByAppendingString:[NSString stringWithFormat:@"%zd minutes", timeInSeconds / 60]];
			if (timeInSeconds % 60 > 0) {
				_snoozeTime = [_snoozeTime stringByAppendingString:[NSString stringWithFormat:@" %zd seconds", timeInSeconds % 60]];
			}
		} else if (timeInSeconds % 60 > 0) {
			_snoozeTime = [_snoozeTime stringByAppendingString:[NSString stringWithFormat:@"%zd seconds", timeInSeconds % 60]];
		}

		_snoozeMessage = [_snoozeMessage stringByReplacingOccurrencesOfString:@"[min]" withString:_snoozeTime];

		// create alert
		alert = [%c(UIAlertController) alertControllerWithTitle:_alertMessage message:nil preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:_buttonMessage style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
			alert = nil;
		}];
		UIAlertAction *snoozeAction = [UIAlertAction actionWithTitle:_snoozeMessage style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			numberOfSnoozes++;
			shouldDisplayAlert = YES;
			[self performSelector:@selector(displayAlert) withObject:nil afterDelay:timeInSeconds];
			alert = nil;
		}];

		if (!isSnoozeEnabled || !isOverrideEnabled) {
			[alert addAction:cancelAction];
		}
		if (isSnoozeEnabled) {
			[alert addAction:snoozeAction];
		}
		[self presentViewController:alert animated:YES completion:nil];
	}
}
%end
%end

%ctor {
	preferencesChanged();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)preferencesChanged, kSettingsChangedNotification, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

	if (isEnabled) {
		NSArray *args = [[NSClassFromString(@"NSProcessInfo") processInfo] arguments];
		if (args.count != 0) {
			NSString *execPath = args[0];
			if (execPath && [execPath rangeOfString:@"/Application"].location != NSNotFound) {
				%init(applications);
			}
		}
	}
}