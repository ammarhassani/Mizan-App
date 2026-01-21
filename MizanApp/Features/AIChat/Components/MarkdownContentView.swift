//
//  MarkdownContentView.swift
//  Mizan
//
//  Rich markdown rendering for AI messages
//  Supports headers, code blocks, lists, bold/italic, and links
//

import SwiftUI

/// Rich markdown content renderer for AI messages
struct MarkdownContentView: View {
    @EnvironmentObject var themeManager: ThemeManager

    /// The markdown content to render
    let content: String

    var body: some View {
        // In RTL: .leading = RIGHT side
        VStack(alignment: .leading, spacing: MZSpacing.xs) {
            ForEach(parseBlocks(content), id: \.id) { block in
                renderBlock(block)
            }
        }
    }

    // MARK: - Block Rendering

    @ViewBuilder
    private func renderBlock(_ block: MarkdownBlock) -> some View {
        switch block.type {
        case .paragraph:
            paragraphView(block.content)

        case .header1:
            headerView(block.content, font: MZTypography.titleLarge, spacing: MZSpacing.sm)

        case .header2:
            headerView(block.content, font: MZTypography.titleMedium, spacing: MZSpacing.xs)

        case .header3:
            headerView(block.content, font: MZTypography.bodyLarge.bold(), spacing: MZSpacing.xxs)

        case .codeBlock:
            codeBlockView(block.content, language: block.language)

        case .bulletList:
            bulletListView(block.items)

        case .numberedList:
            numberedListView(block.items)
        }
    }

    // MARK: - Paragraph

    private func paragraphView(_ text: String) -> some View {
        Text(attributedText(text))
            .font(MZTypography.bodyMedium)
            .foregroundColor(themeManager.textPrimaryColor)
            .multilineTextAlignment(.leading)  // .leading = RIGHT in RTL
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
    }

    // MARK: - Headers

    private func headerView(_ text: String, font: Font, spacing: CGFloat) -> some View {
        Text(attributedText(text))
            .font(font)
            .foregroundColor(themeManager.textPrimaryColor)
            .multilineTextAlignment(.leading)  // .leading = RIGHT in RTL
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, spacing)
    }

    // MARK: - Code Block

    private func codeBlockView(_ code: String, language: String?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with language and copy button
            HStack {
                if let lang = language, !lang.isEmpty {
                    Text(lang)
                        .font(MZTypography.labelSmall)
                        .foregroundColor(themeManager.textTertiaryColor)
                }
                Spacer()
                CopyButtonCompact(textToCopy: code)
            }
            .padding(.horizontal, MZSpacing.sm)
            .padding(.vertical, MZSpacing.xs)
            .background(themeManager.surfaceSecondaryColor.opacity(0.7))

            // Code content
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(themeManager.textPrimaryColor)
                    .textSelection(.enabled)
                    .padding(MZSpacing.sm)
            }
            .background(themeManager.surfaceSecondaryColor.opacity(0.5))
        }
        .clipShape(RoundedRectangle(cornerRadius: themeManager.cornerRadius(.small)))
        .overlay(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius(.small))
                .stroke(themeManager.textTertiaryColor.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Lists

    private func bulletListView(_ items: [String]) -> some View {
        // In RTL: .leading = RIGHT, first HStack item goes to RIGHT
        VStack(alignment: .leading, spacing: MZSpacing.xxs) {
            ForEach(items.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: MZSpacing.xs) {
                    // Bullet FIRST (appears on RIGHT in RTL)
                    Text("•")
                        .font(MZTypography.bodyMedium)
                        .foregroundColor(themeManager.primaryColor)
                    // Text SECOND (appears on LEFT in RTL)
                    Text(attributedText(items[index]))
                        .font(MZTypography.bodyMedium)
                        .foregroundColor(themeManager.textPrimaryColor)
                }
            }
        }
        .padding(.leading, MZSpacing.xs)
    }

    private func numberedListView(_ items: [String]) -> some View {
        // In RTL: .leading = RIGHT, first HStack item goes to RIGHT
        VStack(alignment: .leading, spacing: MZSpacing.xxs) {
            ForEach(items.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: MZSpacing.xs) {
                    // Number FIRST (appears on RIGHT in RTL)
                    Text("\(index + 1).")
                        .font(MZTypography.bodyMedium)
                        .foregroundColor(themeManager.primaryColor)
                        .frame(minWidth: 20, alignment: .trailing)
                    // Text SECOND (appears on LEFT in RTL)
                    Text(attributedText(items[index]))
                        .font(MZTypography.bodyMedium)
                        .foregroundColor(themeManager.textPrimaryColor)
                }
            }
        }
        .padding(.leading, MZSpacing.xs)
    }

    // MARK: - Attributed Text (Bold, Italic, Code, Links)

    private func attributedText(_ text: String) -> AttributedString {
        do {
            var attributed = try AttributedString(markdown: text)

            // Apply link color
            for run in attributed.runs {
                if run.link != nil {
                    let range = run.range
                    attributed[range].foregroundColor = themeManager.primaryColor
                    attributed[range].underlineStyle = .single
                }
            }

            return attributed
        } catch {
            return AttributedString(text)
        }
    }

    // MARK: - Markdown Parsing

    private func parseBlocks(_ markdown: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = markdown.components(separatedBy: "\n")
        var index = 0

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Empty line - skip
            if trimmed.isEmpty {
                index += 1
                continue
            }

            // Header detection
            if trimmed.hasPrefix("### ") {
                blocks.append(MarkdownBlock(type: .header3, content: String(trimmed.dropFirst(4))))
                index += 1
                continue
            }
            if trimmed.hasPrefix("## ") {
                blocks.append(MarkdownBlock(type: .header2, content: String(trimmed.dropFirst(3))))
                index += 1
                continue
            }
            if trimmed.hasPrefix("# ") {
                blocks.append(MarkdownBlock(type: .header1, content: String(trimmed.dropFirst(2))))
                index += 1
                continue
            }

            // Code block detection
            if trimmed.hasPrefix("```") {
                let language = String(trimmed.dropFirst(3))
                var codeLines: [String] = []
                index += 1

                while index < lines.count && !lines[index].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(lines[index])
                    index += 1
                }

                blocks.append(MarkdownBlock(
                    type: .codeBlock,
                    content: codeLines.joined(separator: "\n"),
                    language: language.isEmpty ? nil : language
                ))
                index += 1
                continue
            }

            // Bullet list detection
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                var items: [String] = []

                while index < lines.count {
                    let listLine = lines[index].trimmingCharacters(in: .whitespaces)
                    if listLine.hasPrefix("- ") {
                        items.append(String(listLine.dropFirst(2)))
                        index += 1
                    } else if listLine.hasPrefix("* ") {
                        items.append(String(listLine.dropFirst(2)))
                        index += 1
                    } else if listLine.isEmpty {
                        index += 1
                        break
                    } else {
                        break
                    }
                }

                blocks.append(MarkdownBlock(type: .bulletList, items: items))
                continue
            }

            // Numbered list detection
            if let _ = trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                var items: [String] = []

                while index < lines.count {
                    let listLine = lines[index].trimmingCharacters(in: .whitespaces)
                    if let range = listLine.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                        items.append(String(listLine[range.upperBound...]))
                        index += 1
                    } else if listLine.isEmpty {
                        index += 1
                        break
                    } else {
                        break
                    }
                }

                blocks.append(MarkdownBlock(type: .numberedList, items: items))
                continue
            }

            // Default: paragraph (collect consecutive non-empty, non-special lines)
            var paragraphLines: [String] = []

            while index < lines.count {
                let pLine = lines[index]
                let pTrimmed = pLine.trimmingCharacters(in: .whitespaces)

                // Stop at empty line or special block start
                if pTrimmed.isEmpty ||
                   pTrimmed.hasPrefix("#") ||
                   pTrimmed.hasPrefix("```") ||
                   pTrimmed.hasPrefix("- ") ||
                   pTrimmed.hasPrefix("* ") ||
                   pTrimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil {
                    break
                }

                paragraphLines.append(pLine)
                index += 1
            }

            if !paragraphLines.isEmpty {
                blocks.append(MarkdownBlock(type: .paragraph, content: paragraphLines.joined(separator: " ")))
            }
        }

        return blocks
    }
}

// MARK: - Data Models

private struct MarkdownBlock: Identifiable {
    let id = UUID()
    let type: BlockType
    var content: String = ""
    var items: [String] = []
    var language: String?

    enum BlockType {
        case paragraph
        case header1
        case header2
        case header3
        case codeBlock
        case bulletList
        case numberedList
    }
}

// MARK: - Preview

#Preview("Markdown Content") {
    ScrollView {
        MarkdownContentView(content: """
        # عنوان رئيسي

        هذا نص عادي مع **نص غامق** و *نص مائل*.

        ## عنوان فرعي

        - عنصر أول
        - عنصر ثاني
        - عنصر ثالث

        ### عنوان صغير

        1. خطوة أولى
        2. خطوة ثانية
        3. خطوة ثالثة

        ```swift
        struct Task {
            let title: String
            let duration: Int
        }
        ```

        هذا رابط [ميزان](https://mizan.app) للمزيد من المعلومات.
        """)
        .padding()
    }
    .environmentObject(ThemeManager())
}
