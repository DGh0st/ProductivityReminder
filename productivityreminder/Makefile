include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = ProductivityReminder
ProductivityReminder_FILES = PRPrefsRootListController.m
ProductivityReminder_INSTALL_PATH = /Library/PreferenceBundles
ProductivityReminder_FRAMEWORKS = UIKit MessageUI
ProductivityReminder_PRIVATE_FRAMEWORKS = Preferences
ProductivityReminder_LIBRARIES = applist

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/ProductivityReminder.plist$(ECHO_END)
