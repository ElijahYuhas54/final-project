import SwiftUI

struct MarkdownText: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(parseMarkdown(), id: \.id) { element in
                element.view
            }
        }
    }
    
    private func parseMarkdown() -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        let lines = text.components(separatedBy: .newlines)
        var id = 0
        
        for line in lines {
            id += 1
            
            if line.isEmpty {
                elements.append(MarkdownElement(id: id, view: AnyView(Spacer().frame(height: 4))))
                continue
            }
            
            // Headers (##)
            if line.hasPrefix("## ") {
                let headerText = line.replacingOccurrences(of: "## ", with: "")
                elements.append(MarkdownElement(
                    id: id,
                    view: AnyView(
                        Text(headerText)
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.top, 8)
                    )
                ))
            }
            // Headers (#)
            else if line.hasPrefix("# ") {
                let headerText = line.replacingOccurrences(of: "# ", with: "")
                elements.append(MarkdownElement(
                    id: id,
                    view: AnyView(
                        Text(headerText)
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top, 12)
                    )
                ))
            }
            // Bullet points
            else if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("• ") {
                let bulletText = line
                    .replacingOccurrences(of: "- ", with: "")
                    .replacingOccurrences(of: "* ", with: "")
                    .replacingOccurrences(of: "• ", with: "")
                
                elements.append(MarkdownElement(
                    id: id,
                    view: AnyView(
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            formatInlineMarkdown(bulletText)
                        }
                        .padding(.leading, 8)
                    )
                ))
            }
            // Regular text
            else {
                elements.append(MarkdownElement(
                    id: id,
                    view: AnyView(formatInlineMarkdown(line))
                ))
            }
        }
        
        return elements
    }
    
    private func formatInlineMarkdown(_ text: String) -> Text {
        var result = Text("")
        var currentText = ""
        var isBold = false
        var i = text.startIndex
        
        while i < text.endIndex {
            if i < text.index(text.endIndex, offsetBy: -1) &&
               text[i] == "*" && text[text.index(after: i)] == "*" {
                // Found **
                if !currentText.isEmpty {
                    if isBold {
                        result = result + Text(currentText).bold()
                    } else {
                        result = result + Text(currentText)
                    }
                    currentText = ""
                }
                isBold.toggle()
                i = text.index(i, offsetBy: 2)
            } else {
                currentText.append(text[i])
                i = text.index(after: i)
            }
        }
        
        // Add remaining text
        if !currentText.isEmpty {
            if isBold {
                result = result + Text(currentText).bold()
            } else {
                result = result + Text(currentText)
            }
        }
        
        return result
    }
}

struct MarkdownElement {
    let id: Int
    let view: AnyView
}
