//
//  ContentView.swift
//  StickyNotes
//
//  Created on 2025-01-21
//

import SwiftUI

struct ContentView: View {
    @StateObject private var notesViewModel = NotesViewModel()
    @State private var showNewNoteSheet = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Toolbar
                NotesToolbarView(viewModel: notesViewModel)

                // Notes List
                NotesListView(viewModel: notesViewModel)
            }
            .navigationTitle("StickyNotes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showNewNoteSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .help("Create new note")
                }
            }
        }
        .sheet(isPresented: $showNewNoteSheet) {
            NewNoteSheet(viewModel: notesViewModel, isPresented: $showNewNoteSheet)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

struct NotesToolbarView: View {
    @ObservedObject var viewModel: NotesViewModel

    var body: some View {
        HStack {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search notes...", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(8)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal)

            Spacer()

            // Color filter
            Menu {
                Button("All Colors") {
                    viewModel.setColorFilter(nil)
                }

                Divider()

                ForEach(NoteColor.allCases, id: \.self) { color in
                    Button {
                        viewModel.setColorFilter(color)
                    } label: {
                        HStack {
                            Circle()
                                .fill(color.color)
                                .frame(width: 12, height: 12)
                            Text(color.displayName)
                        }
                    }
                }
            } label: {
                HStack {
                    if let selectedColor = viewModel.selectedColorFilter {
                        Circle()
                            .fill(selectedColor.color)
                            .frame(width: 12, height: 12)
                        Text(selectedColor.displayName)
                    } else {
                        Text("All Colors")
                    }
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
            }
            .menuStyle(BorderlessButtonMenuStyle())
            .padding(.trailing)
        }
        .padding(.vertical, 8)
        .background(Color(.windowBackgroundColor))
        .shadow(color: Color.black.opacity(0.1), radius: 1, y: 1)
    }
}

struct NotesListView: View {
    @ObservedObject var viewModel: NotesViewModel

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 250, maximum: 300))], spacing: 16) {
                ForEach(viewModel.filteredNotes) { note in
                    NoteCardView(note: note, viewModel: viewModel)
                        .contextMenu {
                            Button("Open Note") {
                                openNoteWindow(for: note)
                            }
                            Button("Duplicate") {
                                viewModel.duplicateNote(note)
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                viewModel.deleteNote(note)
                            }
                        }
                }
            }
            .padding()

            // Load more indicator
            if viewModel.hasMoreNotes && !viewModel.isLoading {
                ProgressView()
                    .onAppear {
                        viewModel.loadMoreNotes()
                    }
                    .padding()
            }
        }
        .background(Color(.controlBackgroundColor))
    }

    private func openNoteWindow(for note: Note) {
        WindowManager.shared.createNoteWindow(for: note)
    }
}

struct NoteCardView: View {
    let note: Note
    @ObservedObject var viewModel: NotesViewModel
    @State private var cachedPreview: NotePreview?

    private let cacheService = CacheService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(displayTitle)
                .font(.headline)
                .lineLimit(1)
                .foregroundColor(.primary)

            // Preview text (cached)
            Text(displayPreviewText)
                .font(.body)
                .lineLimit(3)
                .foregroundColor(.primary.opacity(0.8))

            Spacer()

            // Footer
            HStack {
                // Color indicator
                Circle()
                    .fill(note.color.color)
                    .frame(width: 8, height: 8)

                Spacer()

                // Date
                Text(note.modifiedAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.primary.opacity(0.7))
            }
        }
        .padding()
        .frame(height: 120)
        .background(note.color.color.opacity(0.6))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(note.color.borderColor.opacity(0.5), lineWidth: 1)
        )
        .onTapGesture {
            viewModel.selectNote(note)
            openNoteWindow(for: note)
        }
        .onAppear {
            loadCachedPreview()
        }
    }

    private var displayTitle: String {
        cachedPreview?.title ?? note.displayTitle
    }

    private var displayPreviewText: String {
        cachedPreview?.previewText ?? note.previewText
    }

    private func loadCachedPreview() {
        if let cached = cacheService.getPreview(for: note.id) {
            cachedPreview = cached
        } else {
            // Generate and cache preview
            let preview = NotePreview(
                title: note.displayTitle,
                previewText: note.previewText,
                color: note.color,
                lastModified: note.modifiedAt
            )
            cacheService.cachePreview(for: note, preview: preview)
            cachedPreview = preview
        }
    }

    private func openNoteWindow(for note: Note) {
        WindowManager.shared.createNoteWindow(for: note)
    }
}

struct NewNoteSheet: View {
    @ObservedObject var viewModel: NotesViewModel
    @Binding var isPresented: Bool
    @State private var title = ""
    @State private var selectedColor: NoteColor = .yellow

    var body: some View {
        VStack(spacing: 20) {
            Text("Create New Note")
                .font(.title2)
                .bold()

            VStack(alignment: .leading, spacing: 12) {
                TextField("Note title", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Text("Color:")
                    .font(.headline)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(NoteColor.allCases, id: \.self) { color in
                        ColorButton(color: color, isSelected: selectedColor == color) {
                            selectedColor = color
                        }
                    }
                }
            }

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("Create") {
                    let note = viewModel.createNote(title: title.isEmpty ? "New Note" : title, color: selectedColor)
                    isPresented = false
                    // Open the note window
                    openNoteWindow(for: note)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, minHeight: 300)
    }

    private func openNoteWindow(for note: Note) {
        WindowManager.shared.createNoteWindow(for: note)
    }
}

struct ColorButton: View {
    let color: NoteColor
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color.color)
                    .frame(width: 40, height: 40)

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.caption)
                        .bold()
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}