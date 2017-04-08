//
//  BoilerPlate.swift
//  BackendKitDemo
//
//  Created by Ben Spratling on 1/1/16.
//  Copyright © 2016 benspratling.com. All rights reserved.
//

import Foundation
import SwiftPatterns

/// libraries are useful for template inheritance
open class BoilerPlateLibrary {
	open var boilerPlates:QueuedVar<[String:BoilerPlate]> = QueuedVar<[String:BoilerPlate]>(model:[:])
	open func addBoilerPlate(_ boilerPlate:BoilerPlate, forKey key:String) {
		boilerPlates.readWrite { (boilerPlates) -> () in
			boilerPlates[key] = boilerPlate
			boilerPlate.library = self
		}
	}
	
	public convenience init(templates:[String:String]) {
		self.init()
		for (key, template) in templates {
			addBoilerPlate(BoilerPlate(template: template), forKey: key)
		}
	}
}


/** Create a boilerPlate with a template string.
	This is based on mustache templates, but has a more Swift syntax. 
	You still wrap tags with {{ ... }}, but white space is not allowed.
	Arrays, bools, and entries still begin with a "#" and end with a "/".
	But instead of ^ for "not", use "!".
	Use "//" for a comment tag.
	In an array tag, you can specify a delimiter by adding "|" followed by the delimiter.
	Use "^" to name another template in the same library.
	Use ^[...] to fetch the name of the template from the dictionary entry
*/
open class BoilerPlate {
	open weak var library:BoilerPlateLibrary?
	
	//the original string from the
	let template:String
	
	/// the designated initializer
	public init(template:String) {
		self.template = template
	}
	
	// keeping track of the tag scopes
	lazy var rootTagScope:BoilerPlateTagScope = BoilerPlateTagScope(tags:self.template.allTemplateEntries, fullRange:self.template.startIndex..<self.template.endIndex)
	
	/// create a rendered template with a fullfillment
	open func render(with substitutions:[String:BoilerPlateItem])->String {
		//the top level substitution must be a dictionary
		let scopedReplacments = ScopeReplacement(templateScope: rootTagScope, substitutions: .dict(substitutions))
		return scopedReplacments.recursiveReplacementInBoilerPlate(self)
	}
	
}


//encapsulates the
class ScopeReplacement {
	var superScopeReplacement:ScopeReplacement?
	let templateScope:BoilerPlateTagScope
	let substitutions:BoilerPlateItem
	init(superScopeReplacement:ScopeReplacement? = nil, templateScope:BoilerPlateTagScope, substitutions:BoilerPlateItem) {
		self.superScopeReplacement = superScopeReplacement
		self.templateScope = templateScope
		self.substitutions = substitutions
	}
	
	func itemForKey(_ key:String)->BoilerPlateItem? {
		let dotSeparatedComponents = key.components(separatedBy: ".")
		let first = dotSeparatedComponents.first!
		switch substitutions {
		case .dict(let substitutionDictionary):
			if let substitution = substitutionDictionary[first] {
				if dotSeparatedComponents.count > 1 {
					let remainingKeyComponents = Array<String>(dotSeparatedComponents.dropFirst(1))
					return ScopeReplacement.itemForKeyPath(substitution, path: remainingKeyComponents)
				}
				return substitution
			}
			fallthrough
		default:
			return superScopeReplacement?.itemForKey(first)
		}
	}
	
	class func itemForKeyPath(_ substitutions:BoilerPlateItem, path:[String])->BoilerPlateItem? {
		var keyPath = path
		var foundSubstitution:BoilerPlateItem = substitutions
		while let first = keyPath.first {
			keyPath = Array<String>(keyPath.dropFirst())
			switch foundSubstitution {
			case .dict(let substitutionDictionary):
				if let substitution = substitutionDictionary[first] {
					foundSubstitution = substitution
					continue
				}
				fallthrough
			default:
				return nil
			}
			
		}
		return foundSubstitution
	}
	
	//not yet used?
	var renderingIndex:Int?
	
	func recursiveReplacementInBoilerPlate(_ boilerPlate:BoilerPlate)->String {
	/*	if let boilLibrary = boilerPlate.library where templateScope.startTag!.type == .Partial(false) {
			if let foundPartial = boilLibrary.boilerPlates[templateScope.startTag!.tag] {
				let subReplacement = ScopeReplacement(superScopeReplacement: self, templateScope: foundPartial.rootTagScope, substitutions: substitutions)
				return subReplacement.recursiveReplacementInBoilerPlate(foundPartial)
			} else {
				//problem?
				return ""
			}
		}	*/
		
		switch substitutions {
			case .boolean(let value):
				if templateScope.isPositive == value {
					return ScopeReplacement(superScopeReplacement: self, templateScope: self.templateScope, substitutions: .dict([:])).recursiveReplacementInBoilerPlate(boilerPlate)
				}
				return ""
			case .text(let textValue):
				return textValue
			
			case .dict(_):
				//for each tag in this subrange, append all preceeding text, then append replacement text,
				var preceedingEndIndex = templateScope.startTag!.range.upperBound
				var collectedText = ""
				for aSubScope in templateScope.subscopes {
					let preceedingText = boilerPlate.template.substring(with: preceedingEndIndex..<aSubScope.startTag!.range.lowerBound)
					collectedText.append(preceedingText)
					preceedingEndIndex = aSubScope.startTag!.range.upperBound
					var replacementText = ""
					//if the
					if aSubScope.startTag!.type == .comment {
						//yes, do nothing
					} else if aSubScope.startTag!.type == .partial(false) || aSubScope.startTag!.type == .partial(true) {
						if let boilLibrary = boilerPlate.library {
							let isIndirect = aSubScope.startTag!.type == .partial(true)
							var templateName:String?
							if isIndirect {
								//look up the template name in the variable
								if let templateNameSubstitution = itemForKey(aSubScope.key) {
									switch templateNameSubstitution{
									case .text(let textValue):
										templateName = textValue
									default:
										break
									}
								}
							} else {
								templateName = aSubScope.startTag!.tag
							}
							if let sureTemplateName = templateName, let foundPartial = boilLibrary.boilerPlates.read(work:{ return $0[sureTemplateName] }) {
								let subReplacement = ScopeReplacement(superScopeReplacement: self, templateScope: foundPartial.rootTagScope, substitutions: substitutions)
								//crap, something wrong here... need to just append
								replacementText = subReplacement.recursiveReplacementInBoilerPlate(foundPartial)
							}
						}
						// return ""
					} else if let subSubstitutions = itemForKey(aSubScope.key) {
						let replacement = ScopeReplacement(superScopeReplacement: self, templateScope: aSubScope, substitutions: subSubstitutions)
						replacementText = replacement.recursiveReplacementInBoilerPlate(boilerPlate)
					} else {
						//if no value was found
						if aSubScope.isPositive == false {
							let replacement = ScopeReplacement(superScopeReplacement: self, templateScope: aSubScope, substitutions: .dict([:]))
							replacementText = replacement.recursiveReplacementInBoilerPlate(boilerPlate)
						}
					}
					preceedingEndIndex = aSubScope.endTag!.range.upperBound
					collectedText.append(replacementText)
				}
				let leftOverText = boilerPlate.template.substring( with: preceedingEndIndex..<templateScope.endTag!.range.lowerBound)
				collectedText.append(leftOverText)
				return collectedText
			
			case .array(let subValues):
				if templateScope.isPositive && subValues.count > 0  {
					return subValues.enumerated().map({ (index,anItem) -> String in
						return ScopeReplacement(superScopeReplacement: self, templateScope: self.templateScope, substitutions: anItem).recursiveReplacementInBoilerPlate(boilerPlate)
					}).joined(separator: templateScope.delimiter ?? "")
				} else if !templateScope.isPositive && subValues.count == 0 {
					return ScopeReplacement(superScopeReplacement: self, templateScope: self.templateScope, substitutions: .dict([:])).recursiveReplacementInBoilerPlate(boilerPlate)
				} else {
					return ""
				}
		}
	}
	
}


extension String {
	//Get all the template entries for a given string
	var allTemplateEntries:[BoilerPlateTag] {
		var entries:[BoilerPlateTag] = []
		var searchRange = self.startIndex..<self.endIndex
		while let foundRange = self.range(of: "{{", options: [], range: searchRange) {
			let subRange = foundRange.upperBound ..< self.endIndex
			guard let endRange = self.range(of: "}}", options: [], range: subRange) else { break }
			let tagString = self.substring(with: foundRange.upperBound..<endRange.lowerBound)
			guard let (type, tag) = tagString.templateInfo else { break }
			let tagRange = foundRange.lowerBound ..< endRange.upperBound
			entries.append(BoilerPlateTag(type: type, range: tagRange, tag: tag))
			searchRange = endRange.upperBound..<searchRange.upperBound
			if endRange.upperBound == self.endIndex {
				break	//is this necessary
			}
		}
		return entries
	}
	
	var templateInfo:(type:BoilerPlateTagType, tag:String)? {
		if self.isEmpty { return nil }
		let hasPoundPrefix = self.hasPrefix("#")
		if hasPoundPrefix || self.hasPrefix("!") {
			let secondIndex = self.characters.index(self.startIndex, offsetBy: 1)
			var preDelimiterIndex = self.endIndex
			var delimiter = ""
			if let delimiterRange = self.range(of: "|", options:[.backwards]) {
				delimiter = self.substring(from: delimiterRange.upperBound)
				preDelimiterIndex = delimiterRange.lowerBound
			}
			return (.scopeOpen(delimiter, hasPoundPrefix), self.substring(with: secondIndex..<preDelimiterIndex))
		} else if self.hasPrefix("//") {
			return (.comment, "")
		} else if self.hasPrefix("/") {
			let secondIndex = self.characters.index(self.startIndex, offsetBy: 1)
			return (.scopeClose, self.substring(from: secondIndex))
		} else if self.hasPrefix("^") {
			let secondIndex = self.characters.index(self.startIndex, offsetBy: 1)
			var templateName = self.substring(from: secondIndex)
			//look for a partial key
			let isIndirect = templateName.hasPrefix("[") && templateName.hasSuffix("]")
			if isIndirect {
				templateName = templateName.substring(with: templateName.characters.index(templateName.startIndex, offsetBy: 1)..<templateName.characters.index(templateName.endIndex, offsetBy: -1))
			}
			return (.partial(isIndirect), templateName)
		}
		return (.parameter, self)
	}
}


/// Data which can be entered into a template
public enum BoilerPlateItem {
	case boolean(Bool)
	case text(String)
	case array([BoilerPlateItem])
	case dict([String:BoilerPlateItem])
}

public func Boil(_ string:String)->BoilerPlateItem {
	return BoilerPlateItem.text(string)
}

public func Boil(_ array:[BoilerPlateItem])->BoilerPlateItem {
	return BoilerPlateItem.array(array)
}

public func Boil(_ dict:[String:BoilerPlateItem])->BoilerPlateItem {
	return BoilerPlateItem.dict(dict)
}

public func Boil(_ boolean:Bool)->BoilerPlateItem {
	return BoilerPlateItem.boolean(boolean)
}


extension BoilerPlateItem : ExpressibleByStringLiteral {
	public typealias ExtendedGraphemeClusterLiteralType = String
	public typealias UnicodeScalarLiteralType = String
	public typealias StringLiteralType = String
	public init(stringLiteral value:String) {
		self = .text(value)
	}
	public init(unicodeScalarLiteral value: String) {
		self = .text(value)
	}
	public init(extendedGraphemeClusterLiteral value:String) {
		self = .text(value)
	}
}


extension BoilerPlateItem : ExpressibleByArrayLiteral {
	
	public typealias Element = BoilerPlateItem
	
	/// Creates an instance initialized with the given elements.
	public init(arrayLiteral elements: BoilerPlateItem...) {
		self = .array(elements)
	}
}


extension BoilerPlateItem : ExpressibleByBooleanLiteral {
	
	public typealias BooleanLiteralType = Bool
	
	public init(booleanLiteral value: Bool) {
		self = .boolean(value)
	}
}

//TODO: dict literal


/// What kind of template entry is this
enum BoilerPlateTagType {
	case parameter //{{ ... }}
	case scopeOpen(String, Bool)	// {{# ... }} or {{! ... }}	//value is the delimiter, default i zero-length string, boolean is for whether this is a positive scope or a negative scope
	case comment	// {{// ... }
	case scopeClose	// {{/ ... }}
	case partial(Bool) //{{^ ... }} renders another template from the template library, true if it looks up the name of the template in the scope instead of using the literal value
}

func ==(lhs:BoilerPlateTagType, rhs:BoilerPlateTagType)->Bool {
	switch (lhs, rhs) {
	case (.parameter, .parameter):
		return true
	case (.scopeClose, .scopeClose):
		return true
	case (.comment, .comment):
		return true
	case (.scopeOpen(let lhsDelimiter, let lhsIsTrue), .scopeOpen(let rhsDelimiter, let rhsIsTrue)):
		return lhsDelimiter == rhsDelimiter && lhsIsTrue == rhsIsTrue
	case (.partial(let lhIndirect), .partial(let rhIndirect)):
		return lhIndirect == rhIndirect
	default:
		return false
	}
}

extension BoilerPlateTagType:Equatable {
}

struct BoilerPlateTag {
	let type : BoilerPlateTagType
	let range : Range<String.Index>
	let tag : String
}

/// This represents a nested scope in a template
class BoilerPlateTagScope {
	let superScope:BoilerPlateTagScope?
	let key:String
	let startTag:BoilerPlateTag?
	var endTag:BoilerPlateTag? = nil
	var subscopes:[BoilerPlateTagScope] = []
	var delimiter:String?
	
	
	init(key:String, startTag:BoilerPlateTag?, superScope:BoilerPlateTagScope? = nil) {
		self.key = key
		self.startTag = startTag
		self.superScope = superScope
	}
	
	convenience init(tags:[BoilerPlateTag], fullRange:Range<String.Index>) {
		//create fake start & end tags
		let fakeStartTag = BoilerPlateTag(type: .scopeOpen("",true), range: fullRange.lowerBound..<fullRange.lowerBound, tag: "")
		self.init(key:"", startTag:fakeStartTag)
		self.endTag = BoilerPlateTag(type: .scopeClose, range: fullRange.upperBound..<fullRange.upperBound, tag: "")
		
		var currentScope:BoilerPlateTagScope? = self
		for aTag in tags {
			switch aTag.type {
			case .scopeOpen(let tagDelimiter, _):
				let newScope = BoilerPlateTagScope(key: aTag.tag, startTag: aTag, superScope: currentScope)
				newScope.delimiter = tagDelimiter
				currentScope?.subscopes.append(newScope)
				currentScope = newScope
			case .parameter, .comment, .partial:
				let newScope = BoilerPlateTagScope(key: aTag.tag, startTag: aTag, superScope: currentScope)
				newScope.endTag = aTag
				currentScope?.subscopes.append(newScope)
			case .scopeClose where aTag.tag == currentScope?.key:
				currentScope?.endTag = aTag
				currentScope = currentScope?.superScope
			default:
				//error, we hit a close scope with no matching open scope.... what do we do?
				continue
			}
		}
	}
	
	
	var isPositive:Bool {
		switch startTag!.type {
		case .scopeOpen(_, let truthness):
			return truthness
		case .comment:
			return false
		default:
			return true
		}
	}
	
}




