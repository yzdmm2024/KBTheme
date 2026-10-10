// KBThemeCommon.h — 设置面板公共基类与读写工具
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>
#import <UIKit/UIKit.h>
#import "../src/KBThemeShared.h"

// 取色器回调（iOS 14+）
@protocol KBThemeColorDelegate <UIColorPickerViewControllerDelegate>
@end

@interface KBThemeBaseListController : PSListController <UIColorPickerViewControllerDelegate>

@property (nonatomic, strong) PSSpecifier *kbtPendingSpec;

+ (void)kbthemeNotifyChanged;

// 各种控件构造器
- (PSSpecifier *)kbtSwitch:(NSString *)name key:(NSString *)key def:(BOOL)def;
- (PSSpecifier *)kbtLink:(NSString *)name detailClass:(NSString *)cls;
- (PSSpecifier *)kbtChoice:(NSString *)name key:(NSString *)key def:(id)def
                     values:(NSArray *)values titles:(NSArray *)titles;
- (PSSpecifier *)kbtColorRow:(NSString *)name key:(NSString *)key def:(NSString *)def;
- (PSSpecifier *)kbtLetterRow:(NSString *)letter index:(NSInteger)index;
- (PSSpecifier *)kbtButton:(NSString *)name action:(SEL)action;
- (PSSpecifier *)kbtSlider:(NSString *)name key:(NSString *)key def:(double)def
                        min:(double)min max:(double)max;

// 由 KBThemeColorCell 调起：弹出系统取色器，按 specifier 决定写哪个键/哪枚字母
- (void)kbtOpenColorPickerForSpecifier:(PSSpecifier *)spec;

@end

// 颜色行单元格（PSTableCell 子类，带色块预览；点击弹取色器）
@interface KBThemeColorCell : PSTableCell
@end

// 读写助手（C 函数，单元格也直接调用）
id  KBThemeGetPref(NSString *key);
void KBThemeSetPref(NSString *key, id value);
UIColor *KBThemeColorFromHex(NSString *hex);
NSString *KBThemeHexFromColor(UIColor *color);
NSString *KBThemeLetterColor(NSInteger index);
void KBThemeSetLetterColor(NSInteger index, NSString *hex);
