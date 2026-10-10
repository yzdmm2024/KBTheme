// KBThemeShared.h — 设置面板与 tweak 共用的配置常量
// 仅放 ASCII（键名/常量），中文只出现在各 .m 的 @"..." 里，
// 以免 Windows 本地交叉编译链路丢字。
// 偏好键直接定义为 ObjC 字面量，避免 @宏 的解析歧义。
#ifndef KBT_SHARED_H
#define KBT_SHARED_H

// NSString 版本（CFPreferences / NSUserDefaults suite）
#define KBTHEME_SUITE           @"com.yzdmm.kbtheme"
// C 字符串版本（CFSTR / 文件路径）
#define KBTHEME_NOTI_C          "com.yzdmm.kbtheme.prefschanged"

#pragma mark - 偏好键

// 总开关
#define KBTHEME_KEY_ENABLED         @"enabled"

// 键盘背景
#define KBTHEME_KEY_BG_ENABLED      @"bgEnabled"
#define KBTHEME_KEY_BG_MODE         @"bgMode"          // 1=纯色  2=图片
#define KBTHEME_KEY_BG_COLOR        @"bgColor"         // #RRGGBB / #RRGGBBAA
#define KBTHEME_KEY_BG_IMAGE_DATA   @"bgImageData"     // 背景图 PNG 数据（NSData）
#define KBTHEME_KEY_BG_ALPHA        @"bgAlpha"         // 0.05 ~ 1.0

// 整键盘透明：清掉键盘自带的所有不透明背景层，透出后面的内容；
// 按键底色与按键文字色不受影响（默认仍是黑字）。
#define KBTHEME_KEY_TRANSPARENT     @"keyboardTransparent"

// 按键配色总开关
#define KBTHEME_KEY_KEY_ENABLED     @"keyColorEnabled"

// 四组底色 + 文字 + 高亮
#define KBTHEME_KEY_LETTER_BG       @"keyLetterBg"     // 字母键
#define KBTHEME_KEY_DIGIT_BG        @"keyDigitBg"      // 数字/符号键（数字·符号面板中间的主键）
#define KBTHEME_KEY_FUNC_L_BG       @"keyFuncLeftBg"   // 左侧功能键（大小写/数字/符号…）
#define KBTHEME_KEY_FUNC_R_BG       @"keyFuncRightBg"  // 右侧功能键（删除/中英/发送…）
#define KBTHEME_KEY_SPACE_BG        @"keySpaceBg"      // 空格键
#define KBTHEME_KEY_KEY_TEXT        @"keyTextColor"    // 按键文字色
#define KBTHEME_KEY_KEY_HIGHLIGHT   @"keyHighlightColor" // 按下高亮色

// 26 字母渐变
#define KBTHEME_KEY_GRAD_ENABLED    @"letterGradientEnabled"
#define KBTHEME_KEY_GRAD_FROM       @"letterGradientFrom"
#define KBTHEME_KEY_GRAD_TO         @"letterGradientTo"

// 26 字母逐个上色：NSDictionary { "0".."25" -> "#RRGGBB" }
#define KBTHEME_KEY_LETTER_MAP      @"letterColorMap"

// 按键圆角（pt，0 ~ 22）—— 仅在「按键形状 = 默认圆角」时生效
#define KBTHEME_KEY_CORNER          @"keyCornerRadius"

// 按键形状：0 默认圆角（由 keyCornerRadius 决定）/ 1 圆形 / 2 六边形 / 3 水珠
#define KBTHEME_KEY_SHAPE           @"keyShape"

// 内置皮肤：开启后把键盘渲染成真实「彩虹按键」键帽（百度输入法导出的真·键帽 PNG），
// 关闭则恢复普通按键配色。这是对旧版「程序生成彩虹色」的替代。
#define KBTHEME_KEY_SKIN_ENABLED    @"skinEnabled"
#define KBTHEME_KEY_SKIN_NAME       @"skinName"        // 当前仅内置 "rainbow"

// 皮肤资源在设备上的目录（tweak 从 jbroot 读取）
#define KBTHEME_SKIN_DIR            @"/Library/Application Support/KBTheme/skins"

// 立体键帽：在按键背后垫一层向下的深色「侧壁」，模拟电脑键盘 3D 键帽（纯视觉，不动布局）
#define KBTHEME_KEY_KEYCAP3D        @"keyCap3D"

// 键盘整体上下位移（pt，-80 ~ +80，正值 = 下移）
#define KBTHEME_KEY_OFFSET          @"kbOffset"

// 工具栏布局（仅修布局，不改图标/名字；图标增删/排序走原生「定制工具栏」）
#define KBTHEME_KEY_TB_KEEP_SIZE    @"tbKeepNativeSize"   // 图标保持原生尺寸，不自动缩小
#define KBTHEME_KEY_TB_HSCROLL      @"tbHorizontalScroll" // 超出可视宽度时横向滑动，不挤成一团
#define KBTHEME_KEY_TB_FILL         @"tbFillRow"          // 工具栏紧贴左侧 logo 铺满整行，消除 logo 与首图标间的空白
#define KBTHEME_KEY_TB_EDIT_NOFILL  @"tbEditNoFill"       // 进入定制编辑态时不强制撑满，避免与原生编辑界面重叠

#pragma mark - 默认值

#define KBTHEME_DEF_LETTER_BG     @"#FFFFFF"
#define KBTHEME_DEF_FUNC_L_BG     @"#A8A8A8"
#define KBTHEME_DEF_FUNC_R_BG     @"#A8A8A8"
#define KBTHEME_DEF_SPACE_BG      @"#FFFFFF"
#define KBTHEME_DEF_TEXT          @"#000000"
#define KBTHEME_DEF_HIGHLIGHT     @"#D9D9D9"
#define KBTHEME_DEF_GRAD_FROM     @"#5AC8FA"
#define KBTHEME_DEF_GRAD_TO       @"#AF52DE"
#define KBTHEME_DEF_BG_COLOR      @"#1C1C1E"

// 键盘背景裁剪比例（微信键盘：宽 390pt / 高约 260pt）
#define KBTHEME_KB_ASPECT_W       390.0
#define KBTHEME_KB_ASPECT_H       260.0

#endif
