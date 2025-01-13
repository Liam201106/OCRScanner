// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit
import AVFoundation

public class OCRScanner: UIViewController, AVCapturePhotoCaptureDelegate {

    private var captureSession: AVCaptureSession!
    private var photoOutput: AVCapturePhotoOutput!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    var captureDevice: AVCaptureDevice?

    private var cropView: UIView!
    private var recognizedTextLabel: UILabel!
    private var recognizedText: [String] = [] // OCR 결과 저장
    
    public var onTextRecognized: (([String]) -> Void)?
    public var onCancel: (() -> Void)?
    
    private let captureButton: UIButton = {
        let button = UIButton(type: .system)
        let cameraImage = UIImage(systemName: "camera.circle") // 시스템 이미지
        button.setImage(cameraImage, for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(didTapCaptureButton), for: .touchUpInside)
        return button
    }()
    
    private let confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("확인", for: .normal)
        button.tintColor = .green
        button.addTarget(self, action: #selector(didTapConfirmButton), for: .touchUpInside)
        return button
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("취소", for: .normal)
        button.addTarget(self, action: #selector(didTapCancelButton), for: .touchUpInside)
        return button
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait // 세로 고정
    }
    
    private func setupCamera() {
        // 1. Capture Session 설정
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        // 2. 기본 카메라 장치 가져오기
        guard let backCamera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            print("카메라를 사용할 수 없습니다.")
            return
        }

        // 3. 세션에 입력 추가
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        // 4. 출력 설정
        photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }

        // 5. 카메라 프리뷰 설정
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer)

        // 줌 설정
        setZoomFactor(zoomFactor: 1.2)

        // 오토포커스 설정
        setAutoFocus()
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }

    // 줌 설정 함수
    func setZoomFactor(zoomFactor: CGFloat) {
        guard let captureDevice = captureDevice else { return }

        do {
            try captureDevice.lockForConfiguration()

            // 줌 비율 설정
            captureDevice.videoZoomFactor = zoomFactor

            captureDevice.unlockForConfiguration()
        } catch {
            print("줌 설정 실패: \(error)")
        }
    }

    // 오토포커스 설정 함수
    func setAutoFocus() {
        guard let captureDevice = captureDevice else { return }

        do {
            try captureDevice.lockForConfiguration()

            // 오토포커스 활성화
            if captureDevice.isFocusModeSupported(.autoFocus) {
                captureDevice.focusMode = .autoFocus
            }

            // 포커스 지점 설정 (화면 중앙)
            captureDevice.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
            captureDevice.unlockForConfiguration()
        } catch {
            print("오토포커스 설정 실패: \(error)")
        }
    }
    
    private func setupUI() {
        
        // 촬영 버튼 중앙 배치
        let buttonSize: CGFloat = 100 // 더 큰 사이즈
        captureButton.frame = CGRect(x: (view.frame.width - buttonSize) / 2,
                                     y: view.frame.height - 180,
                                     width: buttonSize,
                                     height: buttonSize)
        captureButton.backgroundColor = UIColor.white // 배경 색상
        captureButton.layer.cornerRadius = buttonSize / 2  // 동그랗게
        captureButton.clipsToBounds = true

        // 시스템 이미지 설정 (이미지가 버튼 크기를 채우도록 설정)
        let largeConfig = UIImage.SymbolConfiguration(pointSize: buttonSize * 0.5, weight: .bold)
        let cameraImage = UIImage(systemName: "camera.circle.fill", withConfiguration: largeConfig)
        captureButton.setImage(cameraImage, for: .normal)
        captureButton.tintColor = .white // 이미지 색상
        captureButton.imageView?.contentMode = .scaleAspectFit // 이미지가 버튼 크기 안에서 비율 유지하며 꽉 차도록
        self.view.addSubview(captureButton)

        // 확인 버튼 추가 (촬영 버튼 오른쪽)
        confirmButton.frame = CGRect(x: captureButton.frame.maxX + 20,
                                     y: captureButton.frame.midY - 25,
                                     width: 80,
                                     height: 50)
        confirmButton.isHidden = true // 처음에는 숨김
        confirmButton.backgroundColor = UIColor.systemGreen // 색상 예시
        confirmButton.setTitle("확인", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.layer.cornerRadius = 10
        self.view.addSubview(confirmButton)

        // 취소 버튼 추가 (촬영 버튼 왼쪽)
        cancelButton.frame = CGRect(x: captureButton.frame.minX - 100,
                                    y: captureButton.frame.midY - 25,
                                    width: 80,
                                    height: 50)
        cancelButton.backgroundColor = UIColor.systemRed // 색상 예시
        cancelButton.setTitle("취소", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.layer.cornerRadius = 10
        self.view.addSubview(cancelButton)

        // OCR 결과 표시 Label 추가 (촬영 버튼 위)
        recognizedTextLabel = UILabel()
        recognizedTextLabel.frame = CGRect(x: 20, y: captureButton.frame.minY - 60, width: view.frame.width - 40, height: 50)
        recognizedTextLabel.textAlignment = .center
        recognizedTextLabel.textColor = .white
        recognizedTextLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        recognizedTextLabel.layer.cornerRadius = 8
        recognizedTextLabel.clipsToBounds = true
        recognizedTextLabel.numberOfLines = 2
        recognizedTextLabel.isHidden = true // 초기에는 숨김
        self.view.addSubview(recognizedTextLabel)
        
        // 크롭 영역 설정: 가로는 화면 크기의 절반, 세로는 화면 크기의 70%
        let cropWidth = view.frame.width / 2
        let cropHeight = view.frame.height * 0.7
        let cropX = (view.frame.width - cropWidth) / 2
        let cropY = (view.frame.height - cropHeight) / 2

        cropView = UIView()
        cropView.layer.borderColor = UIColor.red.cgColor
        cropView.layer.borderWidth = 2
        cropView.frame = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
        self.view.addSubview(cropView)

        // 크롭 영역 이동 제스처 추가
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        cropView.addGestureRecognizer(panGesture)
        cropView.isUserInteractionEnabled = true
        
        // 크롭 영역 크기 조정 제스처 추가
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        cropView.addGestureRecognizer(pinchGesture)
    }

    @objc private func didTapCaptureButton() {
        // 사진 촬영
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    @objc private func didTapConfirmButton() {
        onTextRecognized?(recognizedText)
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func didTapCancelButton() {
            // 취소 버튼 눌렀을 때의 동작
            print("촬영이 취소되었습니다.")
            
            // 클로저 호출 (취소 시)
            onCancel?()

            // 예시: 카메라 세션을 멈추고 이전 화면으로 돌아가기
            captureSession.stopRunning()
            self.dismiss(animated: true, completion: nil)
        }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            print("이미지 캡처 실패")
            return
        }
        print("이미지가 성공적으로 캡처되었습니다.")
        print("Original Image size: \(image.size)") // 원본 해상도 출력

        // 이미지의 회전 각도 확인
        guard let fixedImage = fixImageOrientation(image) else {
            print("이미지 회전 처리 실패")
            return
        }
        
        // 스크린 좌표계에서 크롭뷰의 frame 가져오기
        let cropRectInScreen = cropView.frame

        // 이미지와 스크린 사이의 스케일 비율 계산
        let scaleX = image.size.width / view.bounds.width
        let scaleY = image.size.height / view.bounds.height

        // 스크린 좌표를 이미지 좌표로 변환
        let cropRectInImage = CGRect(
            x: cropRectInScreen.origin.x * scaleX,
            y: cropRectInScreen.origin.y * scaleY,
            width: cropRectInScreen.width * scaleX,
            height: cropRectInScreen.height * scaleY
        )

        print("Crop Rect in Image: \(cropRectInImage)")

        // 이미지 크롭
        if let croppedImage = ImageCropper.cropImage(image: fixedImage, cropRect: cropRectInImage) {
            // OCR 수행
            ImageCropper.performOCR(on: croppedImage) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let recognizedText):
                        // OCR 수행
                        self!.recognizedTextLabel.text = recognizedText.joined(separator: "\n")
                        self!.recognizedTextLabel.isHidden = false
                        self!.confirmButton.isHidden = false

                    case .failure(let error):
                        print("OCR Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    // 이미지 회전 처리 함수
    func fixImageOrientation(_ image: UIImage) -> UIImage? {
        if image.imageOrientation == .up { return image }

        UIGraphicsBeginImageContext(image.size)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let fixedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return fixedImage
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.view)
        var newX = cropView.center.x + translation.x
        var newY = cropView.center.y + translation.y
        
        // 화면 밖으로 나가지 않도록 제한
        newX = min(max(newX, cropView.frame.size.width / 2), view.frame.size.width - cropView.frame.size.width / 2)
        newY = min(max(newY, cropView.frame.size.height / 2), view.frame.size.height - cropView.frame.size.height / 2 - 50)
        
        cropView.center = CGPoint(x: newX, y: newY)
        gesture.setTranslation(.zero, in: self.view)
    }

    @objc private func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        let scale = gesture.scale
        let newWidth = cropView.frame.size.width * scale
        let newHeight = cropView.frame.size.height * scale

        // 최소/최대 크기 제한 설정
        let minSize: CGFloat = 100
        let maxSize: CGFloat = view.frame.size.width * 0.9

        // 크기 조정: 좌우 및 상하 모두 변경
        if newWidth > minSize && newWidth < maxSize {
            cropView.frame.size.width = newWidth
        }

        if newHeight > minSize && newHeight < maxSize {
            cropView.frame.size.height = newHeight
        }

        // 크기 변경 후, 크롭뷰의 위치도 다시 계산
        cropView.center = CGPoint(x: cropView.center.x, y: cropView.center.y)

        gesture.scale = 1 // 스케일 초기화
    }

}
