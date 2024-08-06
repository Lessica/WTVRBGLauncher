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
            gFrozenAppSceneIdentifier = prevBundleIdentifier;
            return YES;
        }
        NSURL *nextURL = [nextEntity.activationSettings objectForActivationSetting:SBActivationSettingURL];
        if ([nextBundleIdentifier isEqualToString:@"com.tencent.wetype"] && 
            [nextURL isKindOfClass:[NSURL class]] && 
            [nextURL.scheme isEqualToString:@"wetype"] 
            && [nextURL.host isEqualToString:@"WXKBURL_STARTVOICERECORD"]
        ) {
            gFrozenAppSceneIdentifier = prevBundleIdentifier;
            return YES;
        }
        if ([nextBundleIdentifier isEqualToString:@"com.sogou.sogouinput"] && 
            [nextURL isKindOfClass:[NSURL class]] && 
            [nextURL.scheme isEqualToString:@"com.sogou.sogouinput.ext"] && 
            [nextURL.absoluteString containsString:@":path=SpeechInput&"]
        ) {
            gFrozenAppSceneIdentifier = prevBundleIdentifier;
            return YES;
        }
        if ([nextBundleIdentifier isEqualToString:@"com.iflytek.inputime"] &&
            [nextURL isKindOfClass:[NSURL class]] &&
            [nextURL.scheme isEqualToString:@"xfime"] &&
            [nextURL.host isEqualToString:@"activate_for_record"]
        ) {
            gFrozenAppSceneIdentifier = prevBundleIdentifier;
            return YES;
        }
        BOOL isFromBreadcrumb = [nextEntity.activationSettings flagForActivationSetting:SBActivationSettingFromBreadcrumb];
        if (isFromBreadcrumb && (
            [prevBundleIdentifier isEqualToString:@"com.tencent.wetype"] || 
            [prevBundleIdentifier isEqualToString:@"com.baidu.inputMethod"] || 
            [prevBundleIdentifier isEqualToString:@"com.sogou.sogouinput"] || 
            [prevBundleIdentifier isEqualToString:@"com.iflytek.inputime"]
        )) {
            gFrozenAppSceneIdentifier = nil;
            return YES;
        }
    }
    return %orig;
}

%end

%hook SBApplicationSceneView

- (void)layoutSubviews
{
    %orig;
    if (self.application.bundleIdentifier) {
        if ([gFrozenAppSceneIdentifier isEqualToString:self.application.bundleIdentifier]) {
            if (!gSnapshotView) {
                UIWindow *window = self.window;
                gSnapshotView = [window snapshotViewAfterScreenUpdates:NO];
                gSnapshotView.frame = window.bounds;
                gSnapshotView.userInteractionEnabled = NO;
                [window addSubview:gSnapshotView];
            }
        }
        if (!gFrozenAppSceneIdentifier && gSnapshotView) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                gFrozenAppSceneIdentifier = nil;
                [gSnapshotView removeFromSuperview];
                gSnapshotView = nil;
            });
        }
    }
}

%end