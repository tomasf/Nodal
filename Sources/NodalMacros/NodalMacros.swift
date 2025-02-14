import Foundation

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

@main
struct NodalMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        XMLEncodableMacro.self,
        XMLDecodableMacro.self,
        XMLCodableMacro.self,
        MarkerMacro.self,
    ]
}

/// Macro for automatically generating `XMLElementEncodable` conformance.
public struct XMLEncodableMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        var encodeStatements: [String] = []

        var hasAddedElements = false
        var hasAddedTextContent = false

        for property in declaration.variableDeclarations {
            guard let binding = property.bindings.first,
                  let propertyName = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
            else { continue }

            if let macro = property.attribute(named: "Element") {
                var elementName = macro.firstMacroArgument ?? "\"" + propertyName + "\""
                let containedIn = macro.macroArgument(named: "containedIn")
                let containedInPart = containedIn.map { ", containedIn: \($0)" } ?? ""

                if let namespace = macro.macroArgument(named: "namespace") {
                    elementName = "ExpandedName(namespaceName: \(namespace), localName: \(elementName))"
                }

                guard !hasAddedTextContent else {
                    throw MacroError.conflictingChildProperties
                }

                encodeStatements.append("element.encode(\(propertyName), elementName: \(elementName)\(containedInPart))")
                hasAddedElements = true

            } else if property.attribute(named: "TextContent") != nil {
                guard !hasAddedElements else {
                    throw MacroError.conflictingChildProperties
                }
                guard !hasAddedTextContent else {
                    throw MacroError.multipleTextContentProperties
                }

                encodeStatements.append("element.setContent(\(propertyName))")
                hasAddedTextContent = true

            } else {
                var attributeName = "\"" + propertyName + "\""
                if let macro = property.attribute(named: "Attribute") {
                    if let firstArg = macro.firstMacroArgument {
                        attributeName = firstArg
                    }

                    if let namespace = macro.macroArgument(named: "namespace") {
                        attributeName = "ExpandedName(namespaceName: \(namespace), localName: \(attributeName))"
                    }
                }

                encodeStatements.append("element.setValue(\(propertyName), forAttribute: \(attributeName))")
            }
        }

        return [
            DeclSyntax("""
                func encode(to element: Node) {
                    \(raw: encodeStatements.joined(separator: "\n    "))
                }
                """)
        ]
    }

    /// Adds an extension to conform to `XMLElementCodable`.
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        return try [
            ExtensionDeclSyntax("extension \(type.trimmed): XMLElementEncodable {}")
        ]
    }
}


/// Macro for automatically generating `XMLElementDecodable` conformance.
public struct XMLDecodableMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        var initStatements: [String] = []

        var hasAddedElements = false
        var hasAddedTextContent = false

        for property in declaration.variableDeclarations {
            guard let binding = property.bindings.first,
                  let propertyName = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
            else { continue }

            if let macro = property.attribute(named: "Element") {
                var elementName = macro.firstMacroArgument ?? "\"" + propertyName + "\""
                let containedIn = macro.macroArgument(named: "containedIn")
                let containedInPart = containedIn.map { ", containedIn: \($0)" } ?? ""

                if let namespace = macro.macroArgument(named: "namespace") {
                    elementName = "ExpandedName(namespaceName: \(namespace), localName: \(elementName))"
                }

                guard !hasAddedTextContent else {
                    throw MacroError.conflictingChildProperties
                }

                initStatements.append("\(propertyName) = try element.decode(elementName: \(elementName)\(containedInPart))")
                hasAddedElements = true

            } else if property.attribute(named: "TextContent") != nil {
                guard !hasAddedElements else {
                    throw MacroError.conflictingChildProperties
                }
                guard !hasAddedTextContent else {
                    throw MacroError.multipleTextContentProperties
                }

                initStatements.append("\(propertyName) = try element.content()")
                hasAddedTextContent = true

            } else {
                var attributeName = "\"" + propertyName + "\""
                if let macro = property.attribute(named: "Attribute") {
                    if let firstArg = macro.firstMacroArgument {
                        attributeName = firstArg
                    }

                    if let namespace = macro.macroArgument(named: "namespace") {
                        attributeName = "ExpandedName(namespaceName: \(namespace), localName: \(attributeName))"
                    }
                }

                initStatements.append("\(propertyName) = try element.value(forAttribute: \(attributeName))")
            }
        }

        return [
            DeclSyntax("""
                init(from element: Node) throws {
                    \(raw: initStatements.joined(separator: "\n    "))
                }
                """),
        ]
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        return try [
            ExtensionDeclSyntax("extension \(type.trimmed): XMLElementDecodable {}")
        ]
    }
}


/// Macro combining XMLEncodableMacro + XMLDecodableMacro
public struct XMLCodableMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try XMLEncodableMacro.expansion(of: node, providingMembersOf: declaration, in: context)
        + XMLDecodableMacro.expansion(of: node, providingMembersOf: declaration, in: context)
    }

    /// Adds an extension to conform to `XMLElementCodable`.
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        try XMLEncodableMacro.expansion(of: node, attachedTo: declaration, providingExtensionsOf: type, conformingTo: protocols, in: context)
        + XMLDecodableMacro.expansion(of: node, attachedTo: declaration, providingExtensionsOf: type, conformingTo: protocols, in: context)
    }
}

extension DeclGroupSyntax {
    var variableDeclarations: [VariableDeclSyntax] {
        memberBlock.members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .filter { $0.bindingSpecifier.tokenKind == .keyword(.var) }
    }
}

extension AttributeSyntax {
    var firstMacroArgument: String? {
        arguments?.as(LabeledExprListSyntax.self)?.first?.expression.description
    }

    func macroArgument(named label: String) -> String? {
        arguments?.as(LabeledExprListSyntax.self)?.first {
            $0.label?.text == label
        }?.expression.description
    }
}

extension VariableDeclSyntax {
    var attributeNames: [String] {
        attributes.compactMap { $0.as(AttributeSyntax.self) }.map(\.attributeName.description)
    }

    func attribute(named label: String) -> AttributeSyntax? {
        attributes.compactMap { $0.as(AttributeSyntax.self) }.first {
            $0.attributeName.description.trimmingCharacters(in: .whitespaces) == label
        }
    }
}

public struct MarkerMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}

public enum MacroError: Error, DiagnosticMessage {
    case conflictingChildProperties
    case multipleTextContentProperties

    public var message: String {
        switch self {
        case .conflictingChildProperties:
            "There can be either one or more @Element properties OR a single @TextContent property, not both"
        case .multipleTextContentProperties:
            "There can only be a single @TextContent property"
        }
    }

    public var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
    public var diagnosticID: SwiftDiagnostics.MessageID { .init(domain: "NodalMacros", id: "\(Self.self)") }
}
