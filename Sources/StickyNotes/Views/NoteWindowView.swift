//
//  NoteWindowView.swift
//  StickyNotes
//
//  Created on 2025-01-21
//

import SwiftUI

struct NoteWindowView: View {
    @StateObject private var viewModel: NoteViewModel
    @State private var isHovering = false

    init(note: Note) {
        _viewModel = StateObject(wrappedValue: NoteViewModel(note: note))
    }

    var body: some View {
        ZStack {
            // Background
            viewModel.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Title bar
                NoteTitleBar(viewModel: viewModel, isHovering: $isHovering)

                // Content area
                NoteContentArea(viewModel: viewModel)
            }
        }
        .frame(width: viewModel.note.size.width, height: viewModel.note.size.height)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        .onHover { hovering in
            isHovering = hovering
        }
        .gesture(
            DragGesture()
                .onChanged { _ in
                    // Handle window dragging - this would be implemented with NSWindow
                    print("Dragging window")
                }
        )
    }
}

struct NoteTitleBar: View {
    @ObservedObject var viewModel: NoteViewModel
    @Binding var isHovering: Bool
    @State private var showColorPicker = false

    var body: some View {
        HStack(spacing: 8) {
            // Title field
            TextField("", text: Binding(
                get: { viewModel.note.title },
                set: { viewModel.updateTitle($0) }
            ))
            .textFieldStyle(PlainTextFieldStyle())
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.primary)
            .opacity(isHovering ? 1 : 0.7)

            Spacer()

            // Toolbar buttons
            HStack(spacing: 4) {
                // Color picker button
                Button {
                    showColorPicker.toggle()
                } label: {
                    Image(systemName: "paintpalette")
                        .font(.system(size: 12))
                }
                .buttonStyle(PlainButtonStyle())
                .popover(isPresented: $showColorPicker) {
                    ColorPickerView(selectedColor: viewModel.note.color) { color in
                        viewModel.updateColor(color)
                        showColorPicker = false
                    }
                }

                // Markdown toggle
                Button {
                    viewModel.toggleMarkdown()
                } label: {
                    Image(systemName: viewModel.note.isMarkdown ? "text.badge.checkmark" : "text.badge.minus")
                        .font(.system(size: 12))
                }
                .buttonStyle(PlainButtonStyle())

                // Close button
                Button {
                    // Close window - implementation depends on window management
                    print("Closing note window")
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .opacity(isHovering ? 1 : 0.3)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
    }
}

struct NoteContentArea: View {
    @ObservedObject var viewModel: NoteViewModel

    var body: some View {
        ZStack {
            if viewModel.note.isMarkdown {
                MarkdownEditorView(viewModel: viewModel)
            } else {
                RichTextEditorView(viewModel: viewModel)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
}

struct RichTextEditorView: View {
    @ObservedObject var viewModel: NoteViewModel

    var body: some View {
        EnhancedRichTextEditor(viewModel: viewModel)
    }
}

struct MarkdownEditorView: View {
    @ObservedObject var viewModel: NoteViewModel
    @State private var markdownContent = ""

    var body: some View {
        VStack(spacing: 0) {
            // Markdown editor
            TextEditor(text: $markdownContent)
                .font(.system(size: 14, design: .monospaced))
                .background(Color.clear)
                .onChange(of: markdownContent) { newValue in
                    let attributedString = NSAttributedString(string: newValue)
                    viewModel.updateContent(attributedString)
                }
                .onAppear {
                    markdownContent = viewModel.note.content.string
                }
        }
    }
}

struct ColorPickerView: View {
    let selectedColor: NoteColor
    let onColorSelected: (NoteColor) -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Choose Color")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(NoteColor.allCases, id: \.self) { color in
                    ColorPickerButton(color: color, isSelected: color == selectedColor) {
                        onColorSelected(color)
                    }
                }
            }
        }
        .padding()
        .frame(width: 200)
    }
}

struct ColorPickerButton: View {
    let color: NoteColor
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.color)
                    .frame(height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                    )

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                }

                VStack(spacing: 2) {
                    Spacer()
                    Text(color.displayName)
                        .font(.caption)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 1)
                }
                .padding(.bottom, 4)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NoteWindowView_Previews: PreviewProvider {
    static var previews: some View {
        NoteWindowView(note: Note(
            title: "Sample Note",
            content: NSAttributedString(string: "This is a sample note with some content."),
            color: .yellow
        ))
        .frame(width: 300, height: 200)
    }
}
