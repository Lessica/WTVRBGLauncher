#import <UIKit/UIKit.h>
#import <HBLog.h>

typedef NS_ENUM(unsigned, SBActivationSetting) {
	SBActivationSettingNotASetting = 0,
	SBActivationSettingNoAnimate = 1,
	SBActivationSettingSuspended = 3,
	SBActivationSettingURL = 5,
	SBActivationSettingSourceIdentifier = 14,
	SBActivationSettingFromBreadcrumb = 42,
};

@interface SBActivationSettings : NSObject
- (id)objectForActivationSetting:(SBActivationSetting)arg1;
- (long long)flagForActivationSetting:(SBActivationSetting)arg1;
- (void)setObject:(id)object forActivationSetting:(SBActivationSetting)activationSetting;
- (void)setFlag:(long long)flag forActivationSetting:(SBActivationSetting)activationSetting;
@end

@interface SBApplication : NSObject
@property (nonatomic, copy, readonly) NSString * bundleIdentifier;
@end

@interface SBApplicationSceneEntity : NSObject
@property (nonatomic, readonly) SBApplication *application;
@property (nonatomic, readonly) SBActivationSettings *activationSettings;
@end

@interface SBWorkspaceTransitionContext : NSObject
@property (nonatomic, copy, readonly) NSSet<SBApplicationSceneEntity *> *entities; 
@property (nonatomic, copy, readonly) NSSet<SBApplicationSceneEntity *> *previousEntities;
@property (nonatomic, weak) id request;
@end

%hook SBActivationSettings

- (void)setFlag:(long long)flag forActivationSetting:(SBActivationSetting)activationSetting {
	HBLogDebug(@"[WTVRBGLauncher] setFlag:%lld forActivationSetting:%u", flag, activationSetting);
	%orig;
}

- (void)setObject:(id)object forActivationSetting:(SBActivationSetting)activationSetting {
	HBLogDebug(@"[WTVRBGLauncher] setObject:%@ forActivationSetting:%u", object, activationSetting);
	%orig;
}

%end

%hook SBWorkspaceTransitionContext

- (BOOL)animationDisabled {
	SBApplicationSceneEntity *prevEntity = self.previousEntities.anyObject;
	SBApplicationSceneEntity *nextEntity = self.entities.anyObject;
	Class SBApplicationSceneEntityCls = %c(SBApplicationSceneEntity);
	if ([prevEntity isKindOfClass:SBApplicationSceneEntityCls] && [nextEntity isKindOfClass:SBApplicationSceneEntityCls]) {
		NSString *prevBundleIdentifier = prevEntity.application.bundleIdentifier;
		NSString *nextBundleIdentifier = nextEntity.application.bundleIdentifier;
		NSString *sourceIdentifier = (NSString *)[nextEntity.activationSettings objectForActivationSetting:SBActivationSettingSourceIdentifier];
		if ([nextBundleIdentifier isEqualToString:@"com.baidu.inputMethod"] && 
			[sourceIdentifier isKindOfClass:[NSString class]] && 
			[sourceIdentifier isEqualToString:@"com.baidu.inputMethod.keyboard"]
		) {
			return YES;
		}
		NSURL *nextURL = [nextEntity.activationSettings objectForActivationSetting:SBActivationSettingURL];
		if ([nextBundleIdentifier isEqualToString:@"com.tencent.wetype"] && 
			[nextURL isKindOfClass:[NSURL class]] && 
			[nextURL.scheme isEqualToString:@"wetype"] 
			&& [nextURL.host isEqualToString:@"WXKBURL_STARTVOICERECORD"]
		) {
			return YES;
		}
		if ([nextBundleIdentifier isEqualToString:@"com.sogou.sogouinput"] && 
			[nextURL isKindOfClass:[NSURL class]] && 
			[nextURL.scheme isEqualToString:@"com.sogou.sogouinput.ext"] && 
			[nextURL.absoluteString containsString:@":path=SpeechInput&"]
		) {
			return YES;
		}
		if ([nextBundleIdentifier isEqualToString:@"com.iflytek.inputime"] &&
			[nextURL isKindOfClass:[NSURL class]] &&
			[nextURL.scheme isEqualToString:@"xfime"] &&
			[nextURL.host isEqualToString:@"activate_for_record"]
		) {
			return YES;
		}
		BOOL isFromBreadcrumb = [nextEntity.activationSettings flagForActivationSetting:SBActivationSettingFromBreadcrumb];
		if (isFromBreadcrumb && (
			[prevBundleIdentifier isEqualToString:@"com.tencent.wetype"] || 
			[prevBundleIdentifier isEqualToString:@"com.baidu.inputMethod"] || 
			[prevBundleIdentifier isEqualToString:@"com.sogou.sogouinput"] || 
			[prevBundleIdentifier isEqualToString:@"com.iflytek.inputime"]
		)) {
			return YES;
		}
	}
	return %orig;
}

%end