import Vision

enum DemoImage: String {
    case document = "stairmaster1"
    case licensePlate = "stairmaster2"
}

class OCRReader {
    func performOCR(on url: URL?, recognitionLevel: VNRequestTextRecognitionLevel)  {
        guard let url = url else { return }
        let requestHandler = VNImageRequestHandler(url: url, options: [:])

        let request = VNRecognizeTextRequest  { (request, error) in
            if let error = error {
                print(error)
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }

            for currentObservation in observations {
                let topCandidate = currentObservation.topCandidates(1)
                if let recognizedText = topCandidate.first {
                    print(recognizedText.string)
                }
            }
        }
        request.recognitionLevel = recognitionLevel

        try? requestHandler.perform([request])
    }
}

func url(for image: DemoImage) -> URL? {
    return Bundle.main.url(forResource: image.rawValue, withExtension: "jpg")
}

let ocr = OCRReader()
ocr.performOCR(on: url(for: DemoImage.document), recognitionLevel: VNRequestTextRecognitionLevel.accurate)
