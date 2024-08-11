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

@interface SBApplicationSceneView : UIView
@property (nonatomic, readonly) SBApplication *application;
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

static NSString *gFrozenAppSceneIdentifier = nil;
static UIView *gSnapshotView = nil;

static BOOL gIsEnabled = NO;
static BOOL gIsWeTypeEnabled = NO;
static BOOL gIsBaiduEnabled = NO;
static BOOL gIsSogouEnabled = NO;
static BOOL gIsXunFeiEnabled = NO;

static NSTimeInterval gAnimationInterval = 0.3;
static NSTimeInterval gAnimationDelay = 0.3;

static void ReloadPrefs() {
    static NSUserDefaults *prefs = nil;
    if (!prefs) {
        prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.82flex.wtvrbgprefs"];
    }

    NSDictionary *settings = [prefs dictionaryRepresentation];

	gIsEnabled = settings[@"IsEnabled"] ? [settings[@"IsEnabled"] boolValue] : YES;
    gIsWeTypeEnabled = settings[@"IsWeTypeEnabled"] ? [settings[@"IsWeTypeEnabled"] boolValue] : YES;
    gIsBaiduEnabled = settings[@"IsBaiduEnabled"] ? [settings[@"IsBaiduEnabled"] boolValue] : YES;
    gIsSogouEnabled = settings[@"IsSogouEnabled"] ? [settings[@"IsSogouEnabled"] boolValue] : YES;
    gIsXunFeiEnabled = settings[@"IsXunFeiEnabled"] ? [settings[@"IsXunFeiEnabled"] boolValue] : YES;
    gAnimationInterval = settings[@"AnimationInterval"] ? [settings[@"AnimationInterval"] doubleValue] / 1000.0 : 0.3;
    gAnimationDelay = settings[@"AnimationDelay"] ? [settings[@"AnimationDelay"] doubleValue] / 1000.0 : 0.3;

    HBLogDebug(@"[WTVRBGLauncher] ReloadPrefs: %@", settings);
}

%hook SBWorkspaceTransitionContext

- (BOOL)animationDisabled {
    BOOL disabled = %orig;
    if (!gIsEnabled) {
        return disabled;
    }
    SBApplicationSceneEntity *prevEntity = self.previousEntities.anyObject;
    SBApplicationSceneEntity *nextEntity = self.entities.anyObject;
    Class SBApplicationSceneEntityCls = %c(SBApplicationSceneEntity);
    if ([prevEntity isKindOfClass:SBApplicationSceneEntityCls] && [nextEntity isKindOfClass:SBApplicationSceneEntityCls]) {
        NSString *prevBundleIdentifier = prevEntity.application.bundleIdentifier;
        NSString *nextBundleIdentifier = nextEntity.application.bundleIdentifier;
        NSString *sourceIdentifier = (NSString *)[nextEntity.activationSettings objectForActivationSetting:SBActivationSettingSourceIdentifier];
        if (gIsBaiduEnabled &&
            [nextBundleIdentifier isEqualToString:@"com.baidu.inputMethod"] && 
            [sourceIdentifier isKindOfClass:[NSString class]] && 
            [sourceIdentifier isEqualToString:@"com.baidu.inputMethod.keyboard"]
        ) {
            gFrozenAppSceneIdentifier = prevBundleIdentifier;
            return YES;
        }
        NSURL *nextURL = [nextEntity.activationSettings objectForActivationSetting:SBActivationSettingURL];
        if (gIsWeTypeEnabled &&
            [nextBundleIdentifier isEqualToString:@"com.tencent.wetype"] && 
            [nextURL isKindOfClass:[NSURL class]] && 
            [nextURL.scheme isEqualToString:@"wetype"] &&
            [nextURL.host isEqualToString:@"WXKBURL_STARTVOICERECORD"]
        ) {
            gFrozenAppSceneIdentifier = prevBundleIdentifier;
            return YES;
        }
        if (gIsSogouEnabled && 
            [nextBundleIdentifier isEqualToString:@"com.sogou.sogouinput"] && 
            [nextURL isKindOfClass:[NSURL class]] && 
            [nextURL.scheme isEqualToString:@"com.sogou.sogouinput.ext"] && 
            [nextURL.absoluteString containsString:@":path=SpeechInput&"]
        ) {
            gFrozenAppSceneIdentifier = prevBundleIdentifier;
            return YES;
        }
        if (gIsXunFeiEnabled &&
            [nextBundleIdentifier isEqualToString:@"com.iflytek.inputime"] &&
            [nextURL isKindOfClass:[NSURL class]] &&
            [nextURL.scheme isEqualToString:@"xfime"] &&
            [nextURL.host isEqualToString:@"activate_for_record"]
        ) {
            gFrozenAppSceneIdentifier = prevBundleIdentifier;
            return YES;
        }
        BOOL isFromBreadcrumb = [nextEntity.activationSettings flagForActivationSetting:SBActivationSettingFromBreadcrumb];
        if (isFromBreadcrumb && (
            (gIsWeTypeEnabled && [prevBundleIdentifier isEqualToString:@"com.tencent.wetype"]) || 
            (gIsBaiduEnabled && [prevBundleIdentifier isEqualToString:@"com.baidu.inputMethod"]) || 
            (gIsSogouEnabled && [prevBundleIdentifier isEqualToString:@"com.sogou.sogouinput"]) || 
            (gIsXunFeiEnabled && [prevBundleIdentifier isEqualToString:@"com.iflytek.inputime"])
        )) {
            return YES;
        }
    }
    return disabled;
}

%end

%hook SBApplicationSceneView

- (void)layoutSubviews
{
    %orig;
    if (!gIsEnabled) {
        return;
    }
    if (self.application.bundleIdentifier) {
        if ([gFrozenAppSceneIdentifier isEqualToString:self.application.bundleIdentifier]) {
            gFrozenAppSceneIdentifier = nil;
            if (!gSnapshotView) {
                UIWindow *window = self.window;
                gSnapshotView = [window snapshotViewAfterScreenUpdates:NO];
                gSnapshotView.frame = window.bounds;
                gSnapshotView.userInteractionEnabled = NO;
                [window addSubview:gSnapshotView];
                return;
            }
        }
        if (gSnapshotView) {
            UIView *viewToRemove = gSnapshotView;
            gSnapshotView = nil;
            [UIView animateWithDuration:gAnimationInterval 
                delay:gAnimationDelay 
                options:kNilOptions 
                animations:^{
                    viewToRemove.alpha = 0;
                } 
                completion:^(BOOL finished) {
                    [viewToRemove removeFromSuperview];
                }];
        }
    }
}

%end

%ctor {
    ReloadPrefs();
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(), 
        NULL, 
        (CFNotificationCallback)ReloadPrefs, 
        CFSTR("com.82flex.wtvrbgprefs/saved"), 
        NULL, 
        CFNotificationSuspensionBehaviorCoalesce
    );
}