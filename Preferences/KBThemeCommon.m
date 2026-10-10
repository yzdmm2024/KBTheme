// KBThemeCommon.m — 设置面板公共基类：偏好读写、hex<->UIColor、
// 颜色预设、26 字母存储、各类控件构造器、系统取色器代理、darwin 通知。
#import "KBThemeCommon.h"
#import <Preferences/PSTableCell.h>

#pragma mark - 偏好读写

id KBThemeGetPref(NSString *key) {
    if (!key) return nil;
    NSUserDefaults *ud = [[NSUserDefaults alloc] initWithSuiteName:KBTHEME_SUITE];
    return [ud objectForKey:key];
}

void KBThemeSetPref(NSString *key, id value) {
    if (!key) return;
    NSUserDefaults *ud = [[NSUserDefaults alloc] initWithSuiteName:KBTHEME_SUITE];
    if (value == nil || value == [NSNull null])
        [ud removeObjectForKey:key];
    else
        [ud setObject:value forKey:key];
    [ud synchronize];
}

#pragma mark - 颜色转换

UIColor *KBThemeColorFromHex(NSString *hex) {
    if (!hex) return nil;
    NSString *h = [hex stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if (h.length == 3) { // #RGB
        h = [NSString stringWithFormat:@"%c%c%c%c%c%c",
             [h characterAtIndex:0],[h characterAtIndex:0],
             [h characterAtIndex:1],[h characterAtIndex:1],
             [h characterAtIndex:2],[h characterAtIndex:2]];
    }
    if (h.length != 6 && h.length != 8) return nil;
    unsigned int r=0,g=0,b=0,a=255;
    [[NSScanner scannerWithString:[h substringWithRange:NSMakeRange(0,2)]] scanHexInt:&r];
    [[NSScanner scannerWithString:[h substringWithRange:NSMakeRange(2,2)]] scanHexInt:&g];
    [[NSScanner scannerWithString:[h substringWithRange:NSMakeRange(4,2)]] scanHexInt:&b];
    if (h.length == 8) [[NSScanner scannerWithString:[h substringWithRange:NSMakeRange(6,2)]] scanHexInt:&a];
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a/255.0];
}

NSString *KBThemeHexFromColor(UIColor *color) {
    if (!color) return @"#000000";
    CGFloat r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    int ri=(int)round(r*255), gi=(int)round(g*255), bi=(int)round(b*255), ai=(int)round(a*255);
    if (ai < 255)
        return [NSString stringWithFormat:@"#%02X%02X%02X%02X", ri,gi,bi,ai];
    return [NSString stringWithFormat:@"#%02X%02X%02X", ri,gi,bi];
}

#pragma mark - 26 字母逐个配色

NSString *KBThemeLetterColor(NSInteger index) {
    NSDictionary *m = KBThemeGetPref(KBTHEME_KEY_LETTER_MAP);
    if (![m isKindOfClass:[NSDictionary class]]) return nil;
    return m[[NSString stringWithFormat:@"%ld", (long)index]];
}

void KBThemeSetLetterColor(NSInteger index, NSString *hex) {
    NSMutableDictionary *m = [NSMutableDictionary dictionaryWithDictionary:
        (KBThemeGetPref(KBTHEME_KEY_LETTER_MAP) ?: @{})];
    NSString *k = [NSString stringWithFormat:@"%ld", (long)index];
    if (hex) m[k] = hex; else [m removeObjectForKey:k];
    KBThemeSetPref(KBTHEME_KEY_LETTER_MAP, m);
}

#pragma mark - 通知

@implementation KBThemeBaseListController

+ (void)kbthemeNotifyChanged {
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFSTR(KBTHEME_NOTI_C), NULL, NULL, YES);
}

#pragma mark 通用 set/get（统一走 KBThemeGetPref/SetPref + 通知）

- (id)_kbtGetValueForSpecifier:(PSSpecifier *)spec {
    NSString *key = [spec propertyForKey:@"KBThemeKey"];
    id def = [spec propertyForKey:@"KBThemeDefault"];
    id v = KBThemeGetPref(key);
    return v ?: def;
}

- (void)_kbtSetValue:(id)value forSpecifier:(PSSpecifier *)spec {
    NSString *key = [spec propertyForKey:@"KBThemeKey"];
    KBThemeSetPref(key, value);
    [[self class] kbthemeNotifyChanged];
}

#pragma mark 控件构造器

- (PSSpecifier *)kbtSwitch:(NSString *)name key:(NSString *)key def:(BOOL)def {
    PSSpecifier *s = [PSSpecifier preferenceSpecifierNamed:name
        target:self set:@selector(_kbtSetValue:forSpecifier:) get:@selector(_kbtGetValueForSpecifier:)
        detail:nil cell:PSSwitchCell edit:nil];
    [s setProperty:key forKey:@"KBThemeKey"];
    [s setProperty:@(def) forKey:@"KBThemeDefault"];
    return s;
}

- (PSSpecifier *)kbtLink:(NSString *)name detailClass:(NSString *)cls {
    PSSpecifier *s = [PSSpecifier preferenceSpecifierNamed:name
        target:self set:nil get:nil detail:NSClassFromString(cls)
        cell:PSLinkCell edit:nil];
    return s;
}

- (PSSpecifier *)kbtChoice:(NSString *)name key:(NSString *)key def:(id)def
                     values:(NSArray *)values titles:(NSArray *)titles {
    PSSpecifier *s = [PSSpecifier preferenceSpecifierNamed:name
        target:self set:@selector(_kbtSetValue:forSpecifier:) get:@selector(_kbtGetValueForSpecifier:)
        detail:nil cell:PSSegmentCell edit:nil];
    [s setProperty:key forKey:@"KBThemeKey"];
    [s setProperty:def forKey:@"KBThemeDefault"];
    [s setProperty:values forKey:@"validValues"];
    [s setProperty:titles forKey:@"validTitles"];
    return s;
}

- (PSSpecifier *)kbtColorRow:(NSString *)name key:(NSString *)key def:(NSString *)def {
    PSSpecifier *s = [PSSpecifier preferenceSpecifierNamed:name
        target:self set:nil get:nil detail:nil cell:PSStaticTextCell edit:nil];
    [s setProperty:@"KBThemeColorCell" forKey:@"cellClass"];
    [s setProperty:@"key" forKey:@"KBThemeMode"];
    [s setProperty:key forKey:@"KBThemeKey"];
    [s setProperty:def forKey:@"KBThemeDefault"];
    return s;
}

- (PSSpecifier *)kbtLetterRow:(NSString *)letter index:(NSInteger)index {
    PSSpecifier *s = [PSSpecifier preferenceSpecifierNamed:letter
        target:self set:nil get:nil detail:nil cell:PSStaticTextCell edit:nil];
    [s setProperty:@"KBThemeColorCell" forKey:@"cellClass"];
    [s setProperty:@"letter" forKey:@"KBThemeMode"];
    [s setProperty:@(index) forKey:@"KBThemeLetterIndex"];
    [s setProperty:KBTHEME_DEF_LETTER_BG forKey:@"KBThemeDefault"];
    return s;
}

- (PSSpecifier *)kbtButton:(NSString *)name action:(SEL)action {
    PSSpecifier *s = [PSSpecifier preferenceSpecifierNamed:name
        target:self set:nil get:nil detail:nil cell:PSButtonCell edit:nil];
    [s setButtonAction:action];
    return s;
}

- (PSSpecifier *)kbtSlider:(NSString *)name key:(NSString *)key def:(double)def
                        min:(double)min max:(double)max {
    PSSpecifier *s = [PSSpecifier preferenceSpecifierNamed:name
        target:self set:@selector(_kbtSetValue:forSpecifier:) get:@selector(_kbtGetValueForSpecifier:)
        detail:nil cell:PSSliderCell edit:nil];
    [s setProperty:key forKey:@"KBThemeKey"];
    [s setProperty:@(def) forKey:@"KBThemeDefault"];
    [s setProperty:@(min) forKey:@"min"];
    [s setProperty:@(max) forKey:@"max"];
    return s;
}

#pragma mark 取色器

- (UIColor *)_kbtColorForSpec:(PSSpecifier *)spec {
    if ([[spec propertyForKey:@"KBThemeMode"] isEqualToString:@"letter"]) {
        NSInteger idx = [[spec propertyForKey:@"KBThemeLetterIndex"] integerValue];
        NSString *h = KBThemeLetterColor(idx) ?: [spec propertyForKey:@"KBThemeDefault"];
        return KBThemeColorFromHex(h);
    }
    NSString *h = KBThemeGetPref([spec propertyForKey:@"KBThemeKey"]) ?: [spec propertyForKey:@"KBThemeDefault"];
    return KBThemeColorFromHex(h);
}

- (void)_kbtCommitColor:(UIColor *)color forSpec:(PSSpecifier *)spec {
    NSString *hex = KBThemeHexFromColor(color);
    if ([[spec propertyForKey:@"KBThemeMode"] isEqualToString:@"letter"]) {
        NSInteger idx = [[spec propertyForKey:@"KBThemeLetterIndex"] integerValue];
        KBThemeSetLetterColor(idx, hex);
    } else {
        KBThemeSetPref([spec propertyForKey:@"KBThemeKey"], hex);
    }
    [[self class] kbthemeNotifyChanged];
}

- (void)kbtOpenColorPickerForSpecifier:(PSSpecifier *)spec {
    if (@available(iOS 14.0, *)) {
        self.kbtPendingSpec = spec;
        UIColorPickerViewController *p = [[UIColorPickerViewController alloc] init];
        p.delegate = self;
        p.selectedColor = [self _kbtColorForSpec:spec] ?: [UIColor whiteColor];
        p.supportsAlpha = YES;
        [self presentViewController:p animated:YES completion:nil];
    } else {
        UIAlertController *a = [UIAlertController alertControllerWithTitle:@"提示"
            message:@"系统取色器需要 iOS 14 及以上。" preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:a animated:YES completion:nil];
    }
}

- (void)colorPickerViewControllerDidSelectColor:(UIColorPickerViewController *)viewController {
    if (self.kbtPendingSpec) [self _kbtCommitColor:viewController.selectedColor forSpec:self.kbtPendingSpec];
}

- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)viewController {
    if (self.kbtPendingSpec) [self _kbtCommitColor:viewController.selectedColor forSpec:self.kbtPendingSpec];
    self.kbtPendingSpec = nil;
    _specifiers = nil;
    [self reloadSpecifiers];
}

@end
