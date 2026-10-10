// KBThemePhotoController.m — 从相册选背景图，按键盘比例裁剪后存为本地数据
#import "KBThemeCommon.h"
#import <PhotosUI/PhotosUI.h>

@interface KBThemePhotoController : KBThemeBaseListController <PHPickerViewControllerDelegate>
@end

@implementation KBThemePhotoController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"背景图片";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _specifiers = nil;
    [self reloadSpecifiers];
}

- (NSArray *)specifiers {
    if (_specifiers) return _specifiers;
    NSMutableArray *s = [NSMutableArray array];
    PSSpecifier *g = [PSSpecifier groupSpecifierWithName:@"从相册选择"];
    [g setProperty:@"选一张图作键盘背景，自动按键盘比例（390×260）居中横向裁剪。图片存为本地数据，不上传。"
            forKey:@"footerText"];
    [s addObject:g];
    [s addObject:[self kbtButton:@"从相册选择背景图" action:@selector(pickImage:)]];
    [s addObject:[self kbtButton:@"清除背景图" action:@selector(clearImage:)]];
    _specifiers = s;
    return _specifiers;
}

- (void)pickImage:(id)sender {
    if (@available(iOS 14.0, *)) {
        PHPickerConfiguration *cfg = [[PHPickerConfiguration alloc] initWithPhotoLibrary:nil];
        cfg.selectionLimit = 1;
        cfg.filter = [PHPickerFilter imagesFilter];
        PHPickerViewController *p = [[PHPickerViewController alloc] initWithConfiguration:cfg];
        p.delegate = self;
        [self presentViewController:p animated:YES completion:nil];
    } else {
        UIAlertController *a = [UIAlertController alertControllerWithTitle:@"提示"
            message:@"相册选择器需要 iOS 14 及以上。" preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:a animated:YES completion:nil];
    }
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (results.count == 0) return;
    [results.firstObject.itemProvider loadObjectOfClass:[UIImage class]
                                  completionHandler:^(__kindof id obj, NSError *err) {
        if (![obj isKindOfClass:[UIImage class]]) return;
        UIImage *img = [self cropToKeyboardAspect:obj];
        NSData *png = UIImagePNGRepresentation(img);
        if (png) {
            KBThemeSetPref(KBTHEME_KEY_BG_IMAGE_DATA, png);
            [[self class] kbthemeNotifyChanged];
            dispatch_async(dispatch_get_main_queue(), ^{ [self reloadSpecifiers]; });
        }
    }];
}

- (void)clearImage:(id)sender {
    KBThemeSetPref(KBTHEME_KEY_BG_IMAGE_DATA, nil);
    [[self class] kbthemeNotifyChanged];
    [self reloadSpecifiers];
}

- (UIImage *)cropToKeyboardAspect:(UIImage *)src {
    CGFloat W = KBTHEME_KB_ASPECT_W * 2.0;   // 2x 渲染
    CGFloat H = KBTHEME_KB_ASPECT_H * 2.0;
    CGFloat scale = MAX(W / src.size.width, H / src.size.height);
    CGSize scaled = CGSizeMake(src.size.width * scale, src.size.height * scale);
    CGRect draw = CGRectMake((W - scaled.width) / 2.0, (H - scaled.height) / 2.0,
                            scaled.width, scaled.height);
    UIGraphicsImageRenderer *r = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(W, H)];
    return [r imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull ctx) {
        [src drawInRect:draw];
    }];
}

@end
