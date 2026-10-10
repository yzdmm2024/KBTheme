// KBThemeSettingsController.m — 「原生输入法增强」设置面板根页
#import "KBThemeCommon.h"

@interface KBThemeSettingsController : KBThemeBaseListController
@end

@implementation KBThemeSettingsController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _specifiers = nil;               // 子页返回后刷新当前值
    [self reloadSpecifiers];
}

- (NSArray *)specifiers {
    if (_specifiers) return _specifiers;
    NSMutableArray *s = [NSMutableArray array];
    PSSpecifier *g;

    // ---- 总开关 ----
    g = [PSSpecifier groupSpecifierWithName:@"总开关"];
    [g setProperty:@"改动即时生效（键盘会刷新）。关总开关恢复系统原样。" forKey:@"footerText"];
    [s addObject:g];
    [s addObject:[self kbtSwitch:@"启用原生输入法增强" key:KBTHEME_KEY_ENABLED def:YES]];

    // ---- 键盘背景 ----
    g = [PSSpecifier groupSpecifierWithName:@"键盘背景"];
    [g setProperty:@"「整键盘透明」会清掉键盘自带的背景层，透出后面的内容；"
                  @"按键底色与按键文字色不受影响，默认仍是黑字。"
                  @"「图片」请到「背景图片」里从相册选，会按键盘比例自动横向裁剪。"
            forKey:@"footerText"];
    [s addObject:g];
    [s addObject:[self kbtSwitch:@"启用自定义背景" key:KBTHEME_KEY_BG_ENABLED def:NO]];
    [s addObject:[self kbtSwitch:@"整键盘透明" key:KBTHEME_KEY_TRANSPARENT def:NO]];
    [s addObject:[self kbtChoice:@"背景类型" key:KBTHEME_KEY_BG_MODE def:@1
                           values:@[@1, @2]
                           titles:@[@"纯色", @"图片"]]];
    [s addObject:[self kbtColorRow:@"背景颜色" key:KBTHEME_KEY_BG_COLOR def:KBTHEME_DEF_BG_COLOR]];
    [s addObject:[self kbtLink:@"背景图片" detailClass:@"KBThemePhotoController"]];
    [s addObject:[self kbtSlider:@"背景透明度" key:KBTHEME_KEY_BG_ALPHA def:1.0 min:0.05 max:1.0]];

    // ---- 按键配色 ----
    g = [PSSpecifier groupSpecifierWithName:@"按键配色"];
    [g setProperty:@"点每一行用系统颜色面板选色。五组底色分别对应：字母键 / 数字·符号键（数字符号面板中间的主键）/ 左侧功能键（大小写·数字·符号）/ 右侧功能键（删除·中英切换·发送）/ 空格。"
            forKey:@"footerText"];
    [s addObject:g];
    [s addObject:[self kbtSwitch:@"启用自定义配色" key:KBTHEME_KEY_KEY_ENABLED def:NO]];
    [s addObject:[self kbtColorRow:@"字母键底色" key:KBTHEME_KEY_LETTER_BG def:KBTHEME_DEF_LETTER_BG]];
    [s addObject:[self kbtColorRow:@"数字/符号键底色" key:KBTHEME_KEY_DIGIT_BG def:@"#FFD166"]];
    [s addObject:[self kbtColorRow:@"左侧功能键底色" key:KBTHEME_KEY_FUNC_L_BG def:KBTHEME_DEF_FUNC_L_BG]];
    [s addObject:[self kbtColorRow:@"右侧功能键底色" key:KBTHEME_KEY_FUNC_R_BG def:KBTHEME_DEF_FUNC_R_BG]];
    [s addObject:[self kbtColorRow:@"空格键底色" key:KBTHEME_KEY_SPACE_BG def:KBTHEME_DEF_SPACE_BG]];
    [s addObject:[self kbtColorRow:@"按键文字色" key:KBTHEME_KEY_KEY_TEXT def:KBTHEME_DEF_TEXT]];
    [s addObject:[self kbtColorRow:@"按下高亮色" key:KBTHEME_KEY_KEY_HIGHLIGHT def:KBTHEME_DEF_HIGHLIGHT]];

    // ---- 内置皮肤（彩虹按键）----
    g = [PSSpecifier groupSpecifierWithName:@"内置皮肤（彩虹按键）"];
    [g setProperty:@"开启后把键盘渲染成内置的「彩虹按键」真实皮肤（来自百度输入法导出的真·键帽图），"
                  @"替代旧版程序生成的彩虹色。关闭则恢复上方普通按键配色。皮肤图片缺失时自动退回普通配色。"
            forKey:@"footerText"];
    [s addObject:g];
    [s addObject:[self kbtSwitch:@"启用彩虹按键皮肤" key:KBTHEME_KEY_SKIN_ENABLED def:NO]];

    // ---- 字母键进阶 ----
    g = [PSSpecifier groupSpecifierWithName:@"字母键进阶"];
    [g setProperty:@"字母键支持 A→Z 渐变，以及 26 字母逐个单独上色（优先级最高，覆盖渐变与普通底色）。"
            forKey:@"footerText"];
    [s addObject:g];
    [s addObject:[self kbtSwitch:@"启用字母渐变" key:KBTHEME_KEY_GRAD_ENABLED def:NO]];
    [s addObject:[self kbtColorRow:@"渐变起始色" key:KBTHEME_KEY_GRAD_FROM def:KBTHEME_DEF_GRAD_FROM]];
    [s addObject:[self kbtColorRow:@"渐变结束色" key:KBTHEME_KEY_GRAD_TO def:KBTHEME_DEF_GRAD_TO]];
    [s addObject:[self kbtLink:@"26 字母逐个配色" detailClass:@"KBThemeLetterColors"]];

    // ---- 配色预设 ----
    g = [PSSpecifier groupSpecifierWithName:@"配色预设（一键套用）"];
    [g setProperty:@"点一下即套用整套配色，之后仍可在上方逐项微调。"
            forKey:@"footerText"];
    [s addObject:g];
    for (NSString *nm in @[@"极光", @"莫兰迪", @"暗夜", @"清新"]) {
        PSSpecifier *b = [self kbtButton:[NSString stringWithFormat:@"应用「%@」", nm]
                                  action:@selector(applyPreset:)];
        [b setProperty:nm forKey:@"KBThemePreset"];
        [s addObject:b];
    }

    // ---- 按键形状 ----
    g = [PSSpecifier groupSpecifierWithName:@"按键形状 / 立体键帽"];
    [g setProperty:@"「默认圆角」由下方滑块决定；「圆形 / 六边形 / 水珠」会忽略圆角滑块，"
                  @"直接把按键裁成对应形状（只用图层蒙版裁剪背景，不动键盘布局）。"
                  @"「立体键帽」在按键底下垫一层深色侧壁，模拟电脑键盘 3D 键帽。"
            forKey:@"footerText"];
    [s addObject:g];
    [s addObject:[self kbtChoice:@"按键形状" key:KBTHEME_KEY_SHAPE def:@0
                           values:@[@0, @1, @2, @3]
                           titles:@[@"默认圆角", @"圆形", @"六边形", @"水珠"]]];
    [s addObject:[self kbtSwitch:@"立体键帽（电脑键盘风）" key:KBTHEME_KEY_KEYCAP3D def:NO]];
    [s addObject:[self kbtSlider:@"按键圆角" key:KBTHEME_KEY_CORNER def:0.0 min:0.0 max:22.0]];

    // ---- 工具栏布局 ----
    g = [PSSpecifier groupSpecifierWithName:@"工具栏布局"];
    [g setProperty:@"本插件只修工具栏「布局」，不改图标与名字——图标增删/左右排序请在微信输入法里"
                  @"长按工具栏进入「定制工具栏」操作（之前的「功能显隐」面板已移除）。"
                  @"下方四项控制：图标保持原生尺寸、超出时横滑、紧贴左侧 logo 铺满整行、编辑态不强制撑满。"
            forKey:@"footerText"];
    [s addObject:g];
    [s addObject:[self kbtSwitch:@"图标保持原生尺寸（不缩小）" key:KBTHEME_KEY_TB_KEEP_SIZE def:YES]];
    [s addObject:[self kbtSwitch:@"超出时横向滑动（不挤成一团）" key:KBTHEME_KEY_TB_HSCROLL def:YES]];
    [s addObject:[self kbtSwitch:@"紧贴左侧 logo 铺满整行" key:KBTHEME_KEY_TB_FILL def:YES]];
    [s addObject:[self kbtSwitch:@"进入定制编辑态时不强制撑满" key:KBTHEME_KEY_TB_EDIT_NOFILL def:YES]];

    // ---- 键盘位置 ----
    g = [PSSpecifier groupSpecifierWithName:@"键盘位置（整体位移）"];
    [g setProperty:[NSString stringWithFormat:
                        @"整体上移 / 下移键盘（正在输入的这块），改动立即生效。"
                        @"当前偏移：%.0fpt（正数 = 下移，范围 ±80）。",
                        [self kbOffsetValue]]
            forKey:@"footerText"];
    [s addObject:g];
    [s addObject:[self kbtButton:@"上移 5pt" action:@selector(kbUp:)]];
    [s addObject:[self kbtButton:@"下移 5pt" action:@selector(kbDown:)]];
    [s addObject:[self kbtButton:@"重置为 0" action:@selector(kbReset:)]];

    _specifiers = s;
    return _specifiers;
}

#pragma mark - 键盘位置

- (double)kbOffsetValue {
    id v = KBThemeGetPref(KBTHEME_KEY_OFFSET);
    double d = [v respondsToSelector:@selector(doubleValue)] ? [v doubleValue] : 0.0;
    if (d < -80.0 || d > 80.0) d = 0.0;
    return d;
}

- (void)setKbOffset:(double)off {
    if (off < -80.0) off = -80.0;
    if (off > 80.0) off = 80.0;
    KBThemeSetPref(KBTHEME_KEY_OFFSET, @(off));
    [[self class] kbthemeNotifyChanged];
    _specifiers = nil;
    [self reloadSpecifiers];
}

- (void)kbUp:(id)sender   { [self setKbOffset:[self kbOffsetValue] - 5]; }
- (void)kbDown:(id)sender { [self setKbOffset:[self kbOffsetValue] + 5]; }
- (void)kbReset:(id)sender{ [self setKbOffset:0]; }

#pragma mark - 配色预设（一键套用）

- (NSDictionary *)presetTable {
    return @{
        @"极光": @{
            KBTHEME_KEY_KEY_ENABLED: @YES,
            KBTHEME_KEY_GRAD_ENABLED: @YES,
            KBTHEME_KEY_LETTER_BG: @"#101826",
            KBTHEME_KEY_FUNC_L_BG: @"#0E1524",
            KBTHEME_KEY_FUNC_R_BG: @"#0E1524",
            KBTHEME_KEY_SPACE_BG: @"#101826",
            KBTHEME_KEY_KEY_TEXT: @"#FFFFFF",
            KBTHEME_KEY_KEY_HIGHLIGHT: @"#7C3AED",
            KBTHEME_KEY_GRAD_FROM: @"#22D3EE",
            KBTHEME_KEY_GRAD_TO: @"#A855F7"
        },
        @"莫兰迪": @{
            KBTHEME_KEY_KEY_ENABLED: @YES,
            KBTHEME_KEY_GRAD_ENABLED: @NO,
            KBTHEME_KEY_LETTER_BG: @"#D8CFC4",
            KBTHEME_KEY_FUNC_L_BG: @"#C9BFB2",
            KBTHEME_KEY_FUNC_R_BG: @"#C9BFB2",
            KBTHEME_KEY_SPACE_BG: @"#D8CFC4",
            KBTHEME_KEY_KEY_TEXT: @"#5B534A",
            KBTHEME_KEY_KEY_HIGHLIGHT: @"#B7A99A"
        },
        @"暗夜": @{
            KBTHEME_KEY_KEY_ENABLED: @YES,
            KBTHEME_KEY_GRAD_ENABLED: @NO,
            KBTHEME_KEY_LETTER_BG: @"#2B2B2E",
            KBTHEME_KEY_FUNC_L_BG: @"#1F1F22",
            KBTHEME_KEY_FUNC_R_BG: @"#1F1F22",
            KBTHEME_KEY_SPACE_BG: @"#2B2B2E",
            KBTHEME_KEY_KEY_TEXT: @"#FFFFFF",
            KBTHEME_KEY_KEY_HIGHLIGHT: @"#3A3A3C"
        },
        @"清新": @{
            KBTHEME_KEY_KEY_ENABLED: @YES,
            KBTHEME_KEY_GRAD_ENABLED: @NO,
            KBTHEME_KEY_LETTER_BG: @"#E8F5E9",
            KBTHEME_KEY_FUNC_L_BG: @"#C8E6C9",
            KBTHEME_KEY_FUNC_R_BG: @"#C8E6C9",
            KBTHEME_KEY_SPACE_BG: @"#E8F5E9",
            KBTHEME_KEY_KEY_TEXT: @"#2E7D32",
            KBTHEME_KEY_KEY_HIGHLIGHT: @"#A5D6A7"
        }
    };
}

- (void)applyPreset:(id)sender {
    NSString *pid = nil;
    if ([sender isKindOfClass:[PSSpecifier class]])
        pid = [(PSSpecifier *)sender propertyForKey:@"KBThemePreset"];
    NSDictionary *preset = pid ? [self presetTable][pid] : nil;
    if (!preset) return;
    for (NSString *k in preset) KBThemeSetPref(k, preset[k]);
    [[self class] kbthemeNotifyChanged];

    UIAlertController *a = [UIAlertController
        alertControllerWithTitle:@"已应用"
                   message:[NSString stringWithFormat:@"「%@」配色已套用，收起键盘再弹出即可生效。", pid]
                   preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

@end
