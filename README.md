Add Package .. 로 https://github.com/Liam201106/OCRScanner.git 을 입력하여 사용할 타겟에 추가한다.

타겟의 Info.plist 에 Privacy - Camera Usage Description 추가.

- 사용방법

  import OCRScanner

        let cameraVC = OCRScanner()
        cameraVC.onTextRecognized = { recognizedText in
            print("OCR 결과: \(recognizedText)")
        }
        
        cameraVC.onCancel = {
            // 취소 시의 처리 코드
            print("OCR 취소 버튼이 눌렸습니다.")
        }
        
        // scannerVC를 present로 화면에 띄움
        self.viewController?.present(cameraVC, animated: true, completion: nil)


- onTextRecognized : 스캔한 결과 Array를 " " 띄어쓰기 하여 전체 String 값을 리턴 
- onCancel : 사용자가 취소 버튼을 눌렀을 때 리턴
  
  화면에 crop 할 빨간색 테두리를 확장/축소, 이동 할수 있고 촬영 버튼을 누르면 해당 테두리 안의 화면을 캡쳐하여 OCR로 문자로 인식하여 리턴받는다.
