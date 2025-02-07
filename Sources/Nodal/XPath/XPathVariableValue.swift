import Foundation
import pugixml

internal protocol XPathVariableValue {
    func define(in variableSet: inout pugi.xpath_variable_set, for key: String)
}

extension String: XPathVariableValue {
    func define(in variableSet: inout pugi.xpath_variable_set, for key: String) {
        variableSet.set(key, self)
    }
}

extension Int: XPathVariableValue {
    func define(in variableSet: inout pugi.xpath_variable_set, for key: String) {
        variableSet.set(key, Double(self))
    }
}

extension Double: XPathVariableValue {
    func define(in variableSet: inout pugi.xpath_variable_set, for key: String) {
        variableSet.set(key, self)
    }
}

extension Bool: XPathVariableValue {
    func define(in variableSet: inout pugi.xpath_variable_set, for key: String) {
        variableSet.set(key, self)
    }
}
