//
//  ViewController.m
//  CameraAndAlbum
//
//  Created by admin on 2018/11/2.
//  Copyright © 2018 admin. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

#define kScreenWidth    [UIScreen mainScreen].bounds.size.width
#define kScreenHeight   [UIScreen mainScreen].bounds.size.height

#define ScanX           (kScreenWidth-200)/2
#define ScanY           (kScreenHeight-200)/2
#define ScanWidth       200.0f

@interface ViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate, AVCaptureMetadataOutputObjectsDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *avatar;

@property (nonatomic, strong) UIImagePickerController *imagePickerController;

//扫描二维码
@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, strong) AVCaptureDeviceInput *input;
@property (nonatomic, strong) AVCaptureMetadataOutput *output;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preview;
@property (nonatomic, strong) UIView *borderView;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, assign) NSInteger tag;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.avatar.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAvatar)];
    [self.avatar addGestureRecognizer:tap];
}

- (void)startScan {
    self.avatar.hidden = YES;
    [self.view insertSubview:self.borderView belowSubview:self.avatar];
//    [self.view insertSubview:self.lineView belowSubview:self.avatar];
    [self.view.layer insertSublayer:self.preview atIndex:0];

     [self.session startRunning];
}

- (void)tapAvatar {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction *QRCode = [UIAlertAction actionWithTitle:@"QRCode" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.tag = 0;
        [self checkCameraPermission];//检查相机权限
    }];
    UIAlertAction *camera = [UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.tag = 1;
        [self checkCameraPermission];//检查相机权限
    }];
    UIAlertAction *album = [UIAlertAction actionWithTitle:@"Album" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
         [self checkAlbumPermission];//检查相册权限
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];

    [alert addAction:QRCode];
    [alert addAction:camera];
    [alert addAction:album];
    [alert addAction:cancel];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [info valueForKey:UIImagePickerControllerEditedImage];
    self.avatar.image = image;
}

#pragma mark - Camera
- (void)checkCameraPermission {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                if (self.tag == 0) {
                    [self startScan];
                } else {
                    [self takePhoto];
                }
            }
        }];
    } else if (status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
        [self alertCamear];
    } else {
        if (self.tag == 0) {
            [self startScan];
        } else {
            [self takePhoto];
        }
    }
}

- (void)takePhoto {
    //判断相机是否可用，防止模拟器点击【相机】导致崩溃
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:self.imagePickerController animated:YES completion:^{

        }];
    } else {
        NSLog(@"不能使用模拟器进行拍照");
    }
}

- (void)alertCamear {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"请在设置中打开相机" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Album
- (void)checkAlbumPermission {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (status == PHAuthorizationStatusAuthorized) {
                    [self selectAlbum];
                }
            });
        }];
    } else if (status == PHAuthorizationStatusDenied || status == PHAuthorizationStatusRestricted) {
        [self alertAlbum];
    } else {
        [self selectAlbum];
    }
}

- (void)selectAlbum {
    //判断相册是否可用
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:self.imagePickerController animated:YES completion:^{

        }];
    }
}

- (void)alertAlbum {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"请在设置中打开相册" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects.count > 0) {
        [self.session stopRunning];

        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex:0];
        NSString *stringValue = metadataObject.stringValue;
        NSLog(@"stringValue: %@", stringValue);
    }
}

#pragma mark - lazy load
- (UIImagePickerController *)imagePickerController {
    if (_imagePickerController == nil) {
        _imagePickerController = [[UIImagePickerController alloc] init];
        _imagePickerController.delegate = self; //delegate遵循了两个代理
        _imagePickerController.allowsEditing = YES;
    }
    return _imagePickerController;
}

- (AVCaptureDevice *)device {
    if (_device == nil) {
        _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    return _device;
}

- (AVCaptureDeviceInput *)input {
    if (_input == nil) {
        NSError *error;
        _input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
        if (error) {
            NSLog(@"error: %@", error);
        }
    }
    return _input;
}

- (AVCaptureMetadataOutput *)output {
    if (_output == nil) {
        _output = [[AVCaptureMetadataOutput alloc] init];

        //设置代理
        [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];

        //rectOfInterest 扫描区域  (y, x, height, width)
        _output.rectOfInterest = CGRectMake(ScanY/kScreenHeight, ScanX/kScreenWidth, ScanWidth/kScreenHeight, ScanWidth/kScreenWidth);
    }
    return _output;
}

- (AVCaptureSession *)session {
    if (_session == nil) {
        _session = [[AVCaptureSession alloc] init];
        if ([_session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
            [_session setSessionPreset:AVCaptureSessionPresetHigh];
        }
        if ([_session canAddInput:self.input]) {
            [_session addInput:self.input];
        }
        if ([_session canAddOutput:self.output]) {
            [_session addOutput:self.output];

            //设置扫码支持的编码格式
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                //放在[_session addOutput:self.output];之后
                self.output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
            } else {
                NSLog(@"不能使用模拟器扫描二维码");
            }
        }
    }
    return _session;
}

- (AVCaptureVideoPreviewLayer *)preview {
    if (_preview == nil) {
        _preview = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
        _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;

        //拍照区域
        _preview.frame = self.view.layer.bounds;
//        _preview.frame = CGRectMake(CGRectGetMidX(self.view.frame) - 100, CGRectGetMidY(self.view.frame) - 100, 200, 200);
    }
    return _preview;
}

- (UIView *)borderView {
    if (_borderView == nil) {
        _borderView = [[UIView alloc] initWithFrame:CGRectMake(ScanX, ScanY, ScanWidth, ScanWidth)];
        _borderView.backgroundColor = [UIColor clearColor];
        _borderView.layer.borderWidth = 2.0f;
        _borderView.layer.borderColor = [UIColor greenColor].CGColor;
    }
    return _borderView;
}

- (UIView *)lineView {
    if (_lineView == nil) {
        _lineView = [[UIView alloc] initWithFrame:CGRectMake(ScanX, ScanY + 5, ScanWidth, 2)];
        _lineView.backgroundColor = [UIColor orangeColor];
    }
    return _lineView;
}


@end
