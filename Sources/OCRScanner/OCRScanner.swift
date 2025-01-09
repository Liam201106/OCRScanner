// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit

public class OCRScanner : UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private var originalImage: UIImage?
    private var cropView: UIView!
    private var imageView: UIImageView!

    public var onTextRecognized: (([String]) -> Void)?

    private let captureButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("촬영", for: .normal)
        button.addTarget(OCRScanner.self, action: #selector(didTapCaptureButton), for: .touchUpInside)
        return button
    }()

    private let cropButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("크롭 및 OCR", for: .normal)
        button.addTarget(OCRScanner.self, action: #selector(didTapCropButton), for: .touchUpInside)
        return button
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }

    private func setupUI() {
        captureButton.frame = CGRect(x: (view.frame.width - 200) / 2, y: view.frame.height - 100, width: 200, height: 50)
        self.view.addSubview(captureButton)

        cropButton.frame = CGRect(x: (view.frame.width - 200) / 2, y: view.frame.height - 150, width: 200, height: 50)
        self.view.addSubview(cropButton)

        // 이미지 뷰 및 크롭 영역 설정
        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height - 200))
        imageView.contentMode = .scaleAspectFit
        self.view.addSubview(imageView)

        // 크롭 영역 설정
        cropView = UIView()
        cropView.layer.borderColor = UIColor.red.cgColor
        cropView.layer.borderWidth = 2
        cropView.frame = CGRect(x: 50, y: 100, width: 200, height: 200)
        self.view.addSubview(cropView)

        // 크롭 영역 이동 제스처 추가
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        cropView.addGestureRecognizer(panGesture)
        cropView.isUserInteractionEnabled = true
    }

    @objc private func didTapCaptureButton() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .camera
            imagePicker.delegate = self
            imagePicker.allowsEditing = false
            present(imagePicker, animated: true, completion: nil)
        }
    }

    @objc private func didTapCropButton() {
        guard let image = originalImage else { return }

        // 크롭된 영역을 기준으로 이미지 자르기
        let cropRect = cropView.frame
        if let croppedImage = ImageCropper.cropImage(image: image, cropRect: cropRect) {
            // OCR 수행
            ImageCropper.performOCR(on: croppedImage) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let recognizedText):
                        // 텍스트 결과 콜백
                        self?.onTextRecognized?(recognizedText)
                        self?.dismiss(animated: true, completion: nil)
                    case .failure(let error):
                        print("OCR Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }
        
        originalImage = image
        imageView.image = image
        dismiss(animated: true, completion: nil)
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
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
}

