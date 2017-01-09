#include <UIKit/UIKit.h>

#define kIdentifier @"com.dgh0st.productivityreminder"
#define kSettingsChangedNotification (CFStringRef)@"com.dgh0st.productivityreminder/settingschanged"
#define kSettingsPath @"/var/mobile/Library/Preferences/com.dgh0st.productivityreminder.plist"
#define kIsEnabled @"isEnabled"
#define kAlertMessage @"alertMessage"
#define kButtonMessage @"buttonMessage"
#define kAlertDelayPrefix @"AlertDelay-"
#define kAppEnabledPrefix @"AppEnabled-"
#define kAlertSnoozePrefix @"AlertSnooze-"
#define kIsSnoozeEnabled @"isSnoozeEnabled"
#define kIsOverrideEnabled @"isOverrideEnabled"
#define kSnoozeMessage @"snoozeMessage"

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

static void preferencesChanged() {
	CFPreferencesAppSynchronize((CFStringRef)kIdentifier);
	reloadPrefs();
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

%group applications
BOOL shouldDisplayAlert = NO;
NSInteger numberOfSnoozes = 0;
UIAlertController *alert = nil;

%hook UIViewController
-(void)viewDidLoad {
	%orig;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startAlertTimer) name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopAlertTimer) name:UIApplicationWillResignActiveNotification object:nil];
}

%new
-(void)startAlertTimer {
	if (!shouldDisplayAlert) {
		shouldDisplayAlert = YES;
		numberOfSnoozes = 0;
		[self performSelector:@selector(displayAlert) withObject:nil afterDelay:doubleValuePerApp([[NSBundle mainBundle] bundleIdentifier], kAlertDelayPrefix, 0.0f) * 60];
	}
}

%new
-(void)stopAlertTimer {
	if (shouldDisplayAlert) {
		shouldDisplayAlert = NO;
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(displayAlert) object:nil];
	}
	[alert dismissViewControllerAnimated:YES completion:nil];
	alert = nil;
}

%new
-(void)displayAlert {
	if (shouldDisplayAlert) {
		shouldDisplayAlert = NO;

		NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
		NSString *alertMessage = stringValueForKey(kAlertMessage, @"You've been on [app] for [min]. Are you sure you couldn't be using your time better?");
		NSString *buttonMessage = stringValueForKey(kButtonMessage, @"Thanks for the suggestion");
		NSString *snoozeMessage = stringValueForKey(kSnoozeMessage, @"Snooze for [min].");

		// replace [app] and [min] in alertMessage
		NSInteger timeInSeconds = doubleValuePerApp([[NSBundle mainBundle] bundleIdentifier], kAlertDelayPrefix, 0.0f) * 60 + doubleValuePerApp([[NSBundle mainBundle] bundleIdentifier], kAlertSnoozePrefix, 0.0f) * 60 * numberOfSnoozes;
		NSString *time = @"";
		if (timeInSeconds / 60 > 0) {
			time = [time stringByAppendingString:[NSString stringWithFormat:@"%zd minutes", timeInSeconds / 60]];
			if (timeInSeconds % 60 > 0) {
				time = [time stringByAppendingString:[NSString stringWithFormat:@" %zd seconds", timeInSeconds % 60]];
			}
		} else if (timeInSeconds % 60 > 0) {
			time = [time stringByAppendingString:[NSString stringWithFormat:@"%zd seconds", timeInSeconds % 60]];
		}

		alertMessage = [alertMessage stringByReplacingOccurrencesOfString:@"[app]" withString:appName];
		alertMessage = [alertMessage stringByReplacingOccurrencesOfString:@"[min]" withString:time];

		// replace [min] in snoozeMessage
		timeInSeconds = doubleValuePerApp([[NSBundle mainBundle] bundleIdentifier], kAlertSnoozePrefix, 0.0f) * 60;
		time = @"";
		if (timeInSeconds / 60 > 0) {
			time = [time stringByAppendingString:[NSString stringWithFormat:@"%zd minutes", timeInSeconds / 60]];
			if (timeInSeconds % 60 > 0) {
				time = [time stringByAppendingString:[NSString stringWithFormat:@" %zd seconds", timeInSeconds % 60]];
			}
		} else if (timeInSeconds % 60 > 0) {
			time = [time stringByAppendingString:[NSString stringWithFormat:@"%zd seconds", timeInSeconds % 60]];
		}

		snoozeMessage = [snoozeMessage stringByReplacingOccurrencesOfString:@"[min]" withString:time];

		// create alert
		alert = [%c(UIAlertController) alertControllerWithTitle:alertMessage message:nil preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:buttonMessage style:UIAlertActionStyleCancel handler:nil];
		UIAlertAction *snoozeAction = [UIAlertAction actionWithTitle:snoozeMessage style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			numberOfSnoozes++;
			shouldDisplayAlert = YES;
			[self performSelector:@selector(displayAlert) withObject:nil afterDelay:timeInSeconds];
		}];

		if (boolValueForKey(kIsSnoozeEnabled, NO) && !boolValueForKey(kIsOverrideEnabled, NO)) {
			[alert addAction:cancelAction];
		}
		if (boolValueForKey(kIsSnoozeEnabled, NO)) {
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

	if (boolValueForKey(kIsEnabled, true)) {
		NSArray *args = [[NSClassFromString(@"NSProcessInfo") processInfo] arguments];
		if (args.count != 0) {
			NSString *execPath = args[0];
			if (execPath && [execPath rangeOfString:@"/Application"].location != NSNotFound) {
				if (boolValuePerApp([[NSBundle mainBundle] bundleIdentifier], kAppEnabledPrefix, NO)) {
					%init(applications);
				}
			}
		}
	}
}