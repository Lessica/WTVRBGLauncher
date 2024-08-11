#import <Foundation/Foundation.h>
#import <Preferences/PSSpecifier.h>

#import "WTVRBGRootListController.h"

@interface LSApplicationProxy : NSObject
+ (LSApplicationProxy *)applicationProxyForIdentifier:(NSString *)bundleIdentifier;
- (BOOL)isInstalled;
@end

@implementation WTVRBGRootListController

static void RemoveSpecifiersWithKey(NSString *key, NSMutableArray *specifiers) {
	NSMutableArray *specifiersToRemove = [NSMutableArray array];
	for (PSSpecifier *specifier in specifiers) {
		if ([[specifier.properties objectForKey:@"key"] isEqualToString:key]) {
			[specifiersToRemove addObject:specifier];
		}
	}
	[specifiers removeObjectsInArray:specifiersToRemove];
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
		NSMutableArray *specifiers = [NSMutableArray arrayWithArray:_specifiers];
		NSInteger installedCount = 0;
		BOOL isWeTypeInstalled = [[LSApplicationProxy applicationProxyForIdentifier:@"com.tencent.wetype"] isInstalled];
		if (!isWeTypeInstalled) {
			RemoveSpecifiersWithKey(@"IsWeTypeEnabled", specifiers);
		} else {
			installedCount++;
		}
		BOOL isBaiduInstalled = [[LSApplicationProxy applicationProxyForIdentifier:@"com.baidu.inputMethod"] isInstalled];
		if (!isBaiduInstalled) {
			RemoveSpecifiersWithKey(@"IsBaiduEnabled", specifiers);
		} else {
			installedCount++;
		}
		BOOL isSogouInstalled = [[LSApplicationProxy applicationProxyForIdentifier:@"com.sogou.sogouinput"] isInstalled];
		if (!isSogouInstalled) {
			RemoveSpecifiersWithKey(@"IsSogouEnabled", specifiers);
		} else {
			installedCount++;
		}
		BOOL isXunFeiInstalled = [[LSApplicationProxy applicationProxyForIdentifier:@"com.iflytek.inputime"] isInstalled];
		if (!isXunFeiInstalled) {
			RemoveSpecifiersWithKey(@"IsXunFeiEnabled", specifiers);
		} else {
			installedCount++;
		}
		if (installedCount > 0) {
			_specifiers = specifiers;
		} else {
			_specifiers = [self loadSpecifiersFromPlistName:@"Empty" target:self];
		}
	}
	return _specifiers;
}

@end
