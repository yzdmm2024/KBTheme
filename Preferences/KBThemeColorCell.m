// KBThemeColorCell.m — 带色块预览的颜色行；点击弹系统取色器。
// 必须继承 PSTableCell（满足「PSCustomCell 的 cellClass 必须继承 PSTableCell」的硬性要求，
// 否则点面板入口会闪退 SIGABRT）。
#import "KBThemeCommon.h"
#import <Preferences/PSTableCell.h>

@implementation KBThemeColorCell {
    UIView *_swatch;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier
                    specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _swatch = [[UIView alloc] init];
        _swatch.layer.cornerRadius = 6;
        _swatch.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
        _swatch.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1].CGColor;
        _swatch.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_swatch];
        [NSLayoutConstraint activateConstraints:@[
            [_swatch.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
            [_swatch.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_swatch.widthAnchor constraintEqualToConstant:29],
            [_swatch.heightAnchor constraintEqualToConstant:29],
        ]];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
            initWithTarget:self action:@selector(_openPicker)];
        [self.contentView addGestureRecognizer:tap];
    }
    return self;
}

- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
    [super refreshCellContentsWithSpecifier:specifier];
    self.textLabel.text = specifier.name;
    UIColor *c = nil;
    if ([[specifier propertyForKey:@"KBThemeMode"] isEqualToString:@"letter"]) {
        NSInteger idx = [[specifier propertyForKey:@"KBThemeLetterIndex"] integerValue];
        NSString *h = KBThemeLetterColor(idx) ?: [specifier propertyForKey:@"KBThemeDefault"];
        c = KBThemeColorFromHex(h);
    } else {
        NSString *h = KBThemeGetPref([specifier propertyForKey:@"KBThemeKey"])
            ?: [specifier propertyForKey:@"KBThemeDefault"];
        c = KBThemeColorFromHex(h);
    }
    _swatch.backgroundColor = c ?: [UIColor clearColor];
}

- (void)_openPicker {
    UIResponder *r = self;
    while (r) {
        if ([r isKindOfClass:[KBThemeBaseListController class]]) {
            [(KBThemeBaseListController *)r kbtOpenColorPickerForSpecifier:self.specifier];
            break;
        }
        r = r.nextResponder;
    }
}

@end
