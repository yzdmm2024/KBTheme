// KBTheme Tweak.xm v1.0.0
// iOS 原生键盘换皮肤：5 个预设主题 + 自定义圆角/间距/颜色
//
// hook UIKBKeyplaneView.layoutSubviews（整体位移）+ UIKBKeyView.layoutSubviews（逐键换肤）
// 偏好走 /var/jb/var/mobile/Library/Preferences/com.yzdmm.kbtheme.plist
// darwin 通知 com.yzdmm.kbtheme.prefschanged → 刷新键盘
//
// 注入目标：Classes 模式 → UIKeyboardImpl / UIKeyboardDockView（覆盖所有弹系统键盘的 App）

#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <objc/runtime.h>

#define KBT_SUITE @"com.yzdmm.kbtheme"
#define KBT_NOTI   "com.yzdmm.kbtheme.prefschanged"

@interface UIKBKeyView : UIView @end
@interface UIKBKeyplaneView : UIView @end

#pragma mark - 偏好读取（直读 jbroot，绕开 cfprefsd）

static NSDictionary *KBTPrefDict(void) {
    static NSDictionary *cached = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSString *p = @"/var/jb/var/mobile/Library/Preferences/com.yzdmm.kbtheme.plist";
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:p])
            p = @"/var/mobile/Library/Preferences/com.yzdmm.kbtheme.plist";
        cached = [NSDictionary dictionaryWithContentsOfFile:p] ?: @{};
    });
    return cached;
}

// 偏好变化时刷新缓存（收到 darwin 通知后调）
static void KBTInvalidateCache(void) {
    // 用新指针替换
    NSString *p = @"/var/jb/var/mobile/Library/Preferences/com.yzdmm.kbtheme.plist";
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:p])
        p = @"/var/mobile/Library/Preferences/com.yzdmm.kbtheme.plist";
    NSDictionary *fresh = [NSDictionary dictionaryWithContentsOfFile:p] ?: @{};
    // 替换全局缓存（用 dispatch_once + 新值）
    extern NSDictionary *kbt_cached_prefs;
    kbt_cached_prefs = fresh;
}

// 简化：每次直读（偏好变化频率低，磁盘 IO 可接受）
// 改成：不用缓存，每次直读（KBCustomize 的做法）
static CGFloat KBTFloat(NSString *key, CGFloat def) {
    NSString *p = @"/var/jb/var/mobile/Library/Preferences/com.yzdmm.kbtheme.plist";
    if (![[NSFileManager defaultManager] fileExistsAtPath:p])
        p = @"/var/mobile/Library/Preferences/com.yzdmm.kbtheme.plist";
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:p] ?: @{};
    id v = d[key];
    if (v == nil) return def;
    if ([v isKindOfClass:[NSNumber class]]) return [v floatValue];
    if ([v isKindOfClass:[NSString class]]) return [(NSString *)v floatValue];
    return def;
}

static BOOL KBTBool(NSString *key, BOOL def) {
    NSString *p = @"/var/jb/var/mobile/Library/Preferences/com.yzdmm.kbtheme.plist";
    if (![[NSFileManager defaultManager] fileExistsAtPath:p])
        p = @"/var/mobile/Library/Preferences/com.yzdmm.kbtheme.plist";
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:p] ?: @{};
    id v = d[key];
    if (v == nil) return def;
    if ([v isKindOfClass:[NSNumber class]]) return [v boolValue];
    if ([v isKindOfClass:[NSString class]]) return [(NSString *)v boolValue];
    return def;
}

static NSString *KBTString(NSString *key, NSString *def) {
    NSString *p = @"/var/jb/var/mobile/Library/Preferences/com.yzdmm.kbtheme.plist";
    if (![[NSFileManager defaultManager] fileExistsAtPath:p])
        p = @"/var/mobile/Library/Preferences/com.yzdmm.kbtheme.plist";
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:p] ?: @{};
    id v = d[key];
    if ([v isKindOfClass:[NSString class]]) return v;
    return def;
}

#pragma mark - 预设主题（5 个）

// 预设主题名 → keyR/G/B/A + corner + gapX/gapY
static void KBTPresetTheme(NSString *theme, CGFloat *r, CGFloat *g, CGFloat *b, CGFloat *a, CGFloat *corner) {
    if ([theme isEqualToString:@"classic"]) {
        // 经典橙
        *r = 1.0; *g = 0.55; *b = 0.10; *a = 0.95; *corner = 8.0;
    } else if ([theme isEqualToString:@"dark"]) {
        // 暗黑
        *r = 0.18; *g = 0.18; *b = 0.20; *a = 0.92; *corner = 10.0;
    } else if ([theme isEqualToString:@"violet"]) {
        // 紫罗兰
        *r = 0.45; *g = 0.30; *b = 0.80; *a = 0.92; *corner = 12.0;
    } else if ([theme isEqualToString:@"ocean"]) {
        // 海洋
        *r = 0.15; *g = 0.55; *b = 0.85; *a = 0.92; *corner = 10.0;
    } else if ([theme isEqualToString:@"sunset"]) {
        // 日落
        *r = 0.95; *g = 0.35; *b = 0.35; *a = 0.92; *corner = 14.0;
    } else {
        // 自定义（走用户设置的 RGBA）
        *r = KBTFloat(@"keyR", 1.0);
        *g = KBTFloat(@"keyG", 0.55);
        *b = KBTFloat(@"keyB", 0.10);
        *a = KBTFloat(@"keyA", 0.95);
        *corner = KBTFloat(@"corner", 8.0);
    }
}

#pragma mark - 给单个按键换肤

static void KBTStyleKey(UIKBKeyView *v) {
    if (!v) return;
    @try {
        if (!KBTBool(@"enabled", YES)) {
            v.layer.cornerRadius = 0;
            v.layer.masksToBounds = NO;
            return;
        }
        // gap（间隔）
        CGFloat gx = KBTFloat(@"gapX", 8.0);
        CGFloat gy = KBTFloat(@"gapY", 6.0);
        CGRect f = v.frame;
        f = CGRectInset(f, gx / 2.0, gy / 2.0);
        if (f.size.width > 1.0 && f.size.height > 1.0) v.frame = f;

        // 颜色 + 圆角（走预设主题）
        CGFloat r, g, b, a, corner;
        NSString *theme = KBTString(@"theme", @"classic");
        KBTPresetTheme(theme, &r, &g, &b, &a, &corner);

        v.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:a];
        v.layer.cornerRadius = corner;
        v.layer.masksToBounds = YES;
    } @catch (NSException *e) {}
}

#pragma mark - Hook：整体位移（键面）

%hook UIKBKeyplaneView

- (void)layoutSubviews {
    %orig;
    @try {
        if (!KBTBool(@"enabled", YES)) {
            self.transform = CGAffineTransformIdentity;
            return;
        }
        self.transform = CGAffineTransformMakeTranslation(0.0, KBTFloat(@"offsetY", 40.0));
    } @catch (NSException *e) {}
}

%end

#pragma mark - Hook：单键换肤

%hook UIKBKeyView

- (void)layoutSubviews {
    %orig;
    KBTStyleKey(self);
}

%end

#pragma mark - 通知：面板改值 → 刷新键盘

static void KBTNotificationCB(CFNotificationCenterRef center, void *observer,
                              CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            UIApplication *app = [UIApplication sharedApplication];
            NSArray *wins = nil;
            if (@available(iOS 13.0, *)) {
                NSMutableArray *a = [NSMutableArray array];
                for (UIScene *s in app.connectedScenes)
                    if ([s isKindOfClass:[UIWindowScene class]])
                        [a addObjectsFromArray:((UIWindowScene *)s).windows];
                wins = a;
            }
            if (wins.count == 0) wins = app.windows;
            for (UIWindow *w in wins) {
                for (UIView *sub in w.subviews) {
                    [sub setNeedsLayout];
                    for (UIView *ss in sub.subviews) [ss setNeedsLayout];
                }
            }
        } @catch (NSException *e) {}
    });
}

__attribute__((constructor))
static void _kbt_init(void) {
    // 延迟 2 秒注册通知（避免 constructor 阻塞）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{
        @autoreleasepool {
            CFNotificationCenterAddObserver(
                CFNotificationCenterGetDarwinNotifyCenter(), NULL,
                KBTNotificationCB, CFSTR(KBT_NOTI), NULL,
                CFNotificationSuspensionBehaviorDeliverImmediately);
            NSLog(@"[KBTheme] loaded v1.0.0");
        }
    });
}
