include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = betterhudprefs
betterhudprefs_FILES = BHPRootListController.m
betterhudprefs_INSTALL_PATH = /Library/PreferenceBundles
betterhudprefs_FRAMEWORKS = UIKit
betterhudprefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/betterhudprefs.plist$(ECHO_END)
