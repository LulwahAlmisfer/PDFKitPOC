//
//  PDFViewerView.swift
//  PDFKitPOC
//
//  Created by Lulwah almisfer on 24/01/2025.
//
import SwiftUI
import PDFKit

struct PDFViewerView: View {
    @State private var pdfDocument: PDFDocument? = nil

    var body: some View {
        NavigationView {
            Group {
                if let pdfDocument = pdfDocument {
                    PDFViewer(pdfDocument: pdfDocument)
                        .navigationTitle("PDF Viewer")
                        .padding(.horizontal)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: loadPDF)
    }

    func loadPDF() {
        if let url = Bundle.main.url(forResource: "Sample-Document-to-Sign", withExtension: "pdf") {
            pdfDocument = PDFDocument(url: url)
        }
    }
}

struct PDFViewer: UIViewRepresentable {
    let pdfDocument: PDFDocument?

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.backgroundColor = .clear
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical

        if let document = pdfDocument {
            modifyAnnotations(in: document)
            pdfView.document = document
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = pdfDocument
    }

    func modifyAnnotations(in document: PDFDocument) {
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }

            for annotation in page.annotations {
                if annotation.widgetFieldType == .signature {
                    // remove the default signature annotation
                    page.removeAnnotation(annotation)

                    print(annotation.fieldName ?? "none")
                    
                    // create a custom dashed annotation
                    let bounds = annotation.bounds
                    
                    var annotationProperties: [AnyHashable: Any] = [:]
                    annotationProperties["fieldName"] = annotation.fieldName ?? "---"
                    

                    let dashedAnnotation = CustomPDFAnnotation(
                        bounds: bounds,
                        forType: .square,
                        withProperties: annotationProperties,
                        name: annotation.fieldName
                    )

                    dashedAnnotation.border?.dashPattern = [4]

                    page.addAnnotation(dashedAnnotation)
                }
            }
        }
    }
}

class CustomPDFAnnotation: PDFAnnotation {
    var name : String?
    override init(bounds: CGRect, forType annotationType: PDFAnnotationSubtype, withProperties properties: [AnyHashable: Any]?) {
        super.init(bounds: bounds, forType: annotationType, withProperties: properties)
    }

    init(bounds: CGRect, forType annotationType: PDFAnnotationSubtype, withProperties properties: [AnyHashable: Any]?,name:String?) {
        self.name = name
       super.init(bounds: bounds, forType: annotationType, withProperties: properties)
   }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        super.draw(with: box, in: context)

        // Translate and flip the context to handle PDF coordinate system
        context.translateBy(x: bounds.origin.x, y: bounds.origin.y + bounds.height)
        context.scaleBy(x: 1, y: -1)

        let text = name ?? ""
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.black ,
            .backgroundColor: UIColor.white
        ]

        let textSize = text.size(withAttributes: textAttributes)

        let textRect = CGRect(
            x: 5,
            y: bounds.height - textSize.height - 5,
            width: textSize.width,
            height: textSize.height
        )

        UIGraphicsPushContext(context)
        text.draw(in: textRect, withAttributes: textAttributes)
        UIGraphicsPopContext()

        context.restoreGState()
    }

}

#Preview {
    PDFViewerView()
}
