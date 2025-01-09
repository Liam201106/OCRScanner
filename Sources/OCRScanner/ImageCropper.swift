//
//  File.swift
//  OCRScanner
//
//  Created by Liam on 1/9/25.
//

import UIKit
import Vision

public class ImageCropper {
    
    /// 이미지 크롭 함수
    public static func cropImage(image: UIImage, cropRect: CGRect) -> UIImage? {
        let scale = image.size.width / image.size.width
        let scaledCropRect = CGRect(x: cropRect.origin.x * scale, y: cropRect.origin.y * scale,
                                    width: cropRect.size.width * scale, height: cropRect.size.height * scale)
        
        guard let cgImage = image.cgImage?.cropping(to: scaledCropRect) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    /// Vision을 이용한 OCR 함수
    public static func performOCR(on image: UIImage, completion: @escaping (Result<[String], Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(NSError(domain: "ImageCropper", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid Image"])))
            return
        }
        
        // Vision Request 생성
        let request = VNRecognizeTextRequest { (request, error) in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            // 결과를 문자열 배열로 추출
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "ImageCropper", code: 2, userInfo: [NSLocalizedDescriptionKey: "No text observations found."])))
                }
                return
            }
            
            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            
            // 메인 스레드에서 completion 호출
            DispatchQueue.main.async {
                completion(.success(recognizedStrings))
            }
        }
        
        // 요청 설정 (고해상도 정확도 사용)
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        // 텍스트 인식에 필요한 언어 설정 (영어, 한글 모두 지원)
        request.recognitionLanguages = ["en"] // 영어(en), 지원
        
        // Vision Request Handler 실행
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

}

