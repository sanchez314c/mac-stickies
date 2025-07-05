//
//  RichTextEditor.swift
//  StickyNotes
//
//  Created on 2025-01-21
//

import AppKit
import SwiftUI

struct RichTextEditor: NSViewRepresentable {
    @Binding var attributedString: NSAttributedString
    var isEditable: Bool = true
    var font: NSFont = .systemFont(ofSize: 14)

    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isEditable = isEditable
        textView.isRichText = true
        textView.font = font
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.backgroundColor = .clear
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false

        // Configure text view appearance
        textView.drawsBackground = false
        textView.textContainer?.lineFragmentPadding = 0

        return textView
    }

    func updateNSView(_ nsView: NSTextView, context _: Context) {
        if nsView.attributedString() != attributedString {
            nsView.textStorage?.setAttributedString(attributedString)
        }
        nsView.isEditable = isEditable
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditor

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.attributedString = textView.attributedString()
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            // Handle custom keyboard shortcuts
            if commandSelector == #selector(NSResponder.insertTab(_:)) {
                // Insert tab instead of changing focus
                textView.insertText("\t", replacementRange: textView.selectedRange())
                return true
            }
            return false
        }
    }
}

// MARK: - Rich Text Formatting Toolbar

struct RichTextToolbar: View {
    @Binding var attributedString: NSAttributedString
    @State private var selectedRange: NSRange = .init(location: 0, length: 0)

    var body: some View {
        HStack(spacing: 8) {
            // Font size controls
            Button {
                changeFontSize(delta: 1)
            } label: {
                Image(systemName: "textformat.size.larger")
            }
            .buttonStyle(.borderless)

            Button {
                changeFontSize(delta: -1)
            } label: {
                Image(systemName: "textformat.size.smaller")
            }
            .buttonStyle(.borderless)

            Divider()

            // Style buttons
            Button {
                toggleBold()
            } label: {
                Image(systemName: "bold")
            }
            .buttonStyle(.borderless)

            Button {
                toggleItalic()
            } label: {
                Image(systemName: "italic")
            }
            .buttonStyle(.borderless)

            Button {
                toggleUnderline()
            } label: {
                Image(systemName: "underline")
            }
            .buttonStyle(.borderless)

            Divider()

            // Alignment
            Button {
                setAlignment(.left)
            } label: {
                Image(systemName: "text.alignleft")
            }
            .buttonStyle(.borderless)

            Button {
                setAlignment(.center)
            } label: {
                Image(systemName: "text.aligncenter")
            }
            .buttonStyle(.borderless)

            Button {
                setAlignment(.right)
            } label: {
                Image(systemName: "text.alignright")
            }
            .buttonStyle(.borderless)

            Button {
                setAlignment(.justified)
            } label: {
                Image(systemName: "text.alignnatural")
            }
            .buttonStyle(.borderless)

            Divider()

            // Lists
            Button {
                insertBulletList()
            } label: {
                Image(systemName: "list.bullet")
            }
            .buttonStyle(.borderless)

            Button {
                insertNumberedList()
            } label: {
                Image(systemName: "list.number")
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(6)
    }

    private func changeFontSize(delta: CGFloat) {
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let fullRange = NSRange(location: 0, length: mutableString.length)

        mutableString.enumerateAttribute(.font, in: fullRange, options: []) { value, range, _ in
            if let font = value as? NSFont {
                let newSize = max(8, min(72, font.pointSize + delta))
                let newFont = NSFont(descriptor: font.fontDescriptor, size: newSize)
                mutableString.addAttribute(.font, value: newFont!, range: range)
            }
        }

        attributedString = mutableString
    }

    private func toggleBold() {
        toggleFontTrait(.boldFontMask)
    }

    private func toggleItalic() {
        toggleFontTrait(.italicFontMask)
    }

    private func toggleFontTrait(_ trait: NSFontTraitMask) {
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let fullRange = NSRange(location: 0, length: mutableString.length)

        mutableString.enumerateAttribute(.font, in: fullRange, options: []) { value, range, _ in
            if let font = value as? NSFont {
                var newFont: NSFont
                if font.fontDescriptor.symbolicTraits.contains(trait) {
                    // Remove trait
                    let traits = font.fontDescriptor.symbolicTraits.subtracting(trait)
                    newFont = NSFont(descriptor: font.fontDescriptor.withSymbolicTraits(traits), size: font.pointSize) ?? font
                } else {
                    // Add trait
                    let traits = font.fontDescriptor.symbolicTraits.union(trait)
                    newFont = NSFont(descriptor: font.fontDescriptor.withSymbolicTraits(traits), size: font.pointSize) ?? font
                }
                mutableString.addAttribute(.font, value: newFont, range: range)
            }
        }

        attributedString = mutableString
    }

    private func toggleUnderline() {
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let fullRange = NSRange(location: 0, length: mutableString.length)

        mutableString.enumerateAttribute(.underlineStyle, in: fullRange, options: []) { value, range, _ in
            if let style = value as? NSNumber, style.intValue > 0 {
                // Remove underline
                mutableString.removeAttribute(.underlineStyle, range: range)
            } else {
                // Add underline
                mutableString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            }
        }

        attributedString = mutableString
    }

    private func setAlignment(_ alignment: NSTextAlignment) {
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let style = NSMutableParagraphStyle()
        style.alignment = alignment

        let fullRange = NSRange(location: 0, length: mutableString.length)
        mutableString.addAttribute(.paragraphStyle, value: style, range: fullRange)

        attributedString = mutableString
    }

    private func insertBulletList() {
        // This is a simplified implementation
        let bulletString = "• "
        let mutableString = NSMutableAttributedString(attributedString: attributedString)

        // Insert bullet at the beginning of each line
        let text = mutableString.string
        let lines = text.components(separatedBy: .newlines)

        var newString = ""
        for (index, line) in lines.enumerated() {
            if !line.isEmpty, !line.hasPrefix("• ") {
                newString += "• " + line
            } else {
                newString += line
            }

            if index < lines.count - 1 {
                newString += "\n"
            }
        }

        attributedString = NSAttributedString(string: newString)
    }

    private func insertNumberedList() {
        // This is a simplified implementation
        let mutableString = NSMutableAttributedString(attributedString: attributedString)

        // Insert numbers at the beginning of each line
        let text = mutableString.string
        let lines = text.components(separatedBy: .newlines)

        var newString = ""
        for (index, line) in lines.enumerated() {
            if !line.isEmpty, !line.hasPrefix("\(index + 1). ") {
                newString += "\(index + 1). " + line
            } else {
                newString += line
            }

            if index < lines.count - 1 {
                newString += "\n"
            }
        }

        attributedString = NSAttributedString(string: newString)
    }
}

// MARK: - Enhanced Rich Text Editor View

struct EnhancedRichTextEditor: View {
    @ObservedObject var viewModel: NoteViewModel
    @State private var showToolbar = false

    var body: some View {
        VStack(spacing: 0) {
            // Optional toolbar
            if showToolbar {
                RichTextToolbar(attributedString: $viewModel.note.content)
                    .transition(.move(edge: .top))
            }

            // Text editor
            RichTextEditor(attributedString: $viewModel.note.content)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                showToolbar = hovering
            }
        }
    }
}
