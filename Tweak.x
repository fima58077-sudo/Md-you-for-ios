#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreFoundation/CoreFoundation.h>

#define kTweakDomain CFSTR("com.myrepo.materialyoukit")
#define RELOAD_NOTIFICATION CFSTR("com.myrepo.materialyoukit/reload")
#define OVERLAY_TAG 773177

// Класс дока (SpringBoard), объявляем сами, чтобы код собрался без приватных заголовков
@interface SBDockView : UIView
@end

static BOOL gEnabled  = YES;
static BOOL gTintApps = YES;
static BOOL gSwitches = YES;
static BOOL gDock     = YES;
static UIColor *gAccent;     // основной цвет
static UIColor *gContainer;  // тональный контейнер (светлый оттенок)

static UIColor *HexColor(unsigned int h) {
    return [UIColor colorWithRed:((h >> 16) & 0xFF) / 255.0
                           green:((h >> 8) & 0xFF) / 255.0
                            blue:(h & 0xFF) / 255.0
                           alpha:1.0];
}

static BOOL BoolPref(NSString *key, BOOL def) {
    id v = (__bridge_transfer id)CFPreferencesCopyAppValue((__bridge CFStringRef)key, kTweakDomain);
    return [v isKindOfClass:[NSNumber class]] ? [v boolValue] : def;
}

static NSString *StringPref(NSString *key, NSString *def) {
    id v = (__bridge_transfer id)CFPreferencesCopyAppValue((__bridge CFStringRef)key, DOMAIN);
    return [v isKindOfClass:[NSString class]] ? v : def;
}

static void loadPrefs(void) {
    CFPreferencesAppSynchronize(DOMAIN);
    gEnabled  = BoolPref(@"enabled", YES);
    gTintApps = BoolPref(@"tintApps", YES);
    gSwitches = BoolPref(@"switches", YES);
    gDock     = BoolPref(@"dock", YES);

    // название -> @[основной, контейнер]
    NSDictionary *palette = @{
        @"purple": @[@(0x7E57D1), @(0xEADDFF)],
        @"blue":   @[@(0x4F83F1), @(0xD3E3FD)],
        @"green":  @[@(0x2E9E5B), @(0xC4EED0)],
        @"pink":   @[@(0xD6407A), @(0xFFD8E4)],
        @"orange": @[@(0xE8710A), @(0xFFE0B2)],
        @"teal":   @[@(0x00897B), @(0xC4F0EE)],
        @"red":    @[@(0xD93025), @(0xFAD2CF)],
        @"yellow": @[@(0xF9AB00), @(0xFFF1B0)],
    };
    NSArray *p = palette[StringPref(@"accent", @"purple")] ?: palette[@"purple"];
    gAccent    = HexColor([p[0] unsignedIntValue]);
    gContainer = HexColor([p[1] unsignedIntValue]);
}

static void applyToWindows(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIApplication *app = [UIApplication sharedApplication];
        if (!app) return;
        for (UIWindow *w in app.windows) {
            w.tintColor = (gEnabled && gTintApps) ? gAccent : nil;
        }
    });
}

static void onPrefsChanged(CFNotificationCenterRef center, void *observer, CFNotificationName name, const void *object, CFDictionaryRef userInfo) {
    loadPrefs();
    applyToWindows();
}

// ---- Акцентный цвет во всех приложениях
%hook UIWindow
- (void)makeKeyAndVisible {
    %orig;
    if (gEnabled && gTintApps && gAccent) {
        self.tintColor = gAccent;
    }
}
%end

// ---- Переключатели в стиле Material
%hook UISwitch
- (void)didMoveToWindow {
    %orig;
    if (gEnabled && gSwitches && gAccent) {
        self.onTintColor = gAccent;
        self.thumbTintColor = [UIColor whiteColor];
    }
}
%end

// ---- Док «таблеткой» с тональной подложкой
%hook SBDockView
- (void)layoutSubviews {
    %orig;
    UIView *bg = nil;
    @try { bg = [self valueForKey:@"backgroundView"]; } @catch (NSException *e) { bg = nil; }
    if (![bg isKindOfClass:[UIView class]]) return;

    UIView *ov = [bg viewWithTag:OVERLAY_TAG];
    if (!(gEnabled && gDock)) {
        [ov removeFromSuperview];
        return;
    }
    if (!ov) {
        ov = [[UIView alloc] initWithFrame:bg.bounds];
        ov.tag = OVERLAY_TAG;
        ov.userInteractionEnabled = NO;
        ov.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [bg addSubview:ov];
    }
    ov.frame = bg.bounds;
    ov.backgroundColor = [gContainer colorWithAlphaComponent:0.55];
    bg.clipsToBounds = YES;
    bg.layer.cornerRadius = MIN(bg.bounds.size.height / 2.0, 36.0);
    bg.layer.cornerCurve = kCACornerCurveContinuous;
}
%end

%ctor {
    loadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL,
        onPrefsChanged, RELOAD_NOTIFICATION, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    %init;
}
