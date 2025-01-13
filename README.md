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

다만 컨테이너 외부의 문자 같은 세로 1자 씩의 문자는 인식이 되지 않는다.
MLKit 을 사용하면 되긴 하나 동적 라이브러리 사용 제한등의 이유로 해당 cocoapod 을 package 에 추가할 수 없어 따로 구현해야 한다.
