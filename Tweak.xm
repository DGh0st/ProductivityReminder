#include <UIKit/UIKit.h>

#define kIdentifier @"com.dgh0st.productivityreminder"
#define kSettingsChangedNotification (CFStringRef)@"com.dgh0st.productivityreminder/settingschanged"
#define kSettingsPath @"/var/mobile/Library/Preferences/com.dgh0st.productivityreminder.plist"
#define kIsEnabled @"isEnabled"
#define kAlertMessage @"alertMessage"
#define kButtonMessage @"buttonMessage"
#define kAlertDelayPrefix @"AlertDelay-"

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

static NSString *stringValueForKey(NSString *key, NSString *defaultValue) {
	return (prefs && [prefs objectForKey:key]) ? [prefs objectForKey:key] : defaultValue;
}

%group applications
BOOL shouldDisplayAlert = NO;

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
		[self performSelector:@selector(displayAlert) withObject:nil afterDelay:doubleValuePerApp([[NSBundle mainBundle] bundleIdentifier], kAlertDelayPrefix, 0.0f) * 60];
	}
}

%new
-(void)stopAlertTimer {
	if (shouldDisplayAlert) {
		shouldDisplayAlert = NO;
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(displayAlert) object:nil];
	}
}

%new
-(void)displayAlert {
	if (shouldDisplayAlert) {
		shouldDisplayAlert = NO;

		NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
		NSString *alertMessage = stringValueForKey(kAlertMessage, @"You've been on [app] for [min] minutes. Are you sure you couldn't be using your time better?");
		NSString *buttonMessage = stringValueForKey(kButtonMessage, @"Thanks for the suggestion");
		alertMessage = [alertMessage stringByReplacingOccurrencesOfString:@"[app]" withString:appName];
		alertMessage = [alertMessage stringByReplacingOccurrencesOfString:@"[min]" withString:[NSString stringWithFormat:@"%f", doubleValuePerApp([[NSBundle mainBundle] bundleIdentifier], kAlertDelayPrefix, 0.0f)]];

		UIAlertController *alert = [%c(UIAlertController) alertControllerWithTitle:alertMessage message:nil preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:buttonMessage style:UIAlertActionStyleCancel handler:nil];

		[alert addAction:cancelAction];
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
				if (doubleValuePerApp([[NSBundle mainBundle] bundleIdentifier], kAlertDelayPrefix, 0.0f) != 0) {
					%init(applications);
				}
			}
		}
	}
}