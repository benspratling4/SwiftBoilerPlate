//
//  BoilerPlateTests.swift
//  BoilerPlateTests
//
//  Created by Ben Spratling on 9/30/16.
//  Copyright © 2016 benspratling.com. All rights reserved.
//

import XCTest
@testable import SwiftBoilerPlate

class BoilerPlateTests: XCTestCase {
	
	func testTagNone() {
		//No tag found
		let noTag = ""
		XCTAssertNil(noTag.templateInfo)
	}
	
	func testEntryTypeEquals() {
		XCTAssertTrue(BoilerPlateTagType.comment == BoilerPlateTagType.comment)
		XCTAssertFalse(BoilerPlateTagType.comment == BoilerPlateTagType.partial(true))
		
		XCTAssertTrue(BoilerPlateTagType.parameter == BoilerPlateTagType.parameter)
		XCTAssertFalse(BoilerPlateTagType.parameter == BoilerPlateTagType.scopeClose)
		XCTAssertFalse(BoilerPlateTagType.parameter == BoilerPlateTagType.scopeOpen("", true))
		XCTAssertFalse(BoilerPlateTagType.parameter == BoilerPlateTagType.comment)
		XCTAssertFalse(BoilerPlateTagType.parameter == BoilerPlateTagType.partial(true))
		
		XCTAssertTrue(BoilerPlateTagType.scopeClose == BoilerPlateTagType.scopeClose)
		XCTAssertFalse(BoilerPlateTagType.scopeClose == BoilerPlateTagType.parameter)
		XCTAssertFalse(BoilerPlateTagType.scopeClose == BoilerPlateTagType.scopeOpen("", true))
		XCTAssertFalse(BoilerPlateTagType.scopeClose == BoilerPlateTagType.comment)
		XCTAssertFalse(BoilerPlateTagType.scopeClose == BoilerPlateTagType.partial(true))
		
		XCTAssertTrue(BoilerPlateTagType.scopeOpen("", true) == BoilerPlateTagType.scopeOpen("", true))
		XCTAssertFalse(BoilerPlateTagType.scopeOpen("", true) == BoilerPlateTagType.scopeClose)
		XCTAssertFalse(BoilerPlateTagType.scopeOpen("", true) == BoilerPlateTagType.parameter)
		XCTAssertFalse(BoilerPlateTagType.scopeOpen("", true) == BoilerPlateTagType.scopeOpen("", false))
		XCTAssertFalse(BoilerPlateTagType.scopeOpen("", true) == BoilerPlateTagType.scopeOpen("a", true))
		XCTAssertFalse(BoilerPlateTagType.scopeOpen("", true) == BoilerPlateTagType.comment)
		XCTAssertFalse(BoilerPlateTagType.scopeOpen("", true) == BoilerPlateTagType.partial(true))
		
		XCTAssertTrue(BoilerPlateTagType.partial(true) == BoilerPlateTagType.partial(true))
		XCTAssertFalse(BoilerPlateTagType.partial(true) == BoilerPlateTagType.partial(false))
	}
	
	
	func testSimpleTag() {
		let simpleTag = "tagname"
		let (type, tagName) = simpleTag.templateInfo!
		XCTAssertEqual(type, BoilerPlateTagType.parameter)
		XCTAssertEqual(tagName, "tagname")
	}
	
	
	func testPartialTag() {
		let simpleTag = "^tagname"
		let (type, tagName) = simpleTag.templateInfo!
		XCTAssertEqual(type, BoilerPlateTagType.partial(false))
		XCTAssertEqual(tagName, "tagname")
	}
	
	func testPartialIndirectTag() {
		let simpleTag = "^[tagname]"
		let (type, tagName) = simpleTag.templateInfo!
		XCTAssertEqual(type, BoilerPlateTagType.partial(true))
		XCTAssertEqual(tagName, "tagname")
	}
	
	func testShortTagName() {
		let simpleTag = "a"
		let (type, tagName) = simpleTag.templateInfo!
		XCTAssertEqual(type, BoilerPlateTagType.parameter)
		XCTAssertEqual(tagName, "a")
	}
	
	func testCommentTag() {
		let simpleTag = "//tagname"
		let (type, _) = simpleTag.templateInfo!
		XCTAssertEqual(type, BoilerPlateTagType.comment)
	}
	
	func testTagScopeOpen() {
		let simpleTag = "#tagname"
		let (type, tagName) = simpleTag.templateInfo!
		XCTAssertEqual(type, BoilerPlateTagType.scopeOpen("",true))
		XCTAssertEqual(tagName, "tagname")
	}
	
	func testTagScopeOpenFalse() {
		let simpleTag = "!tagname"
		let (type, tagName) = simpleTag.templateInfo!
		XCTAssertEqual(type, BoilerPlateTagType.scopeOpen("",false))
		XCTAssertEqual(tagName, "tagname")
	}
	
	func testTagScopeClose() {
		let simpleTag = "/tagname"
		let (type, tagName) = simpleTag.templateInfo!
		XCTAssertEqual(type, BoilerPlateTagType.scopeClose)
		XCTAssertEqual(tagName, "tagname")
	}
	
	func testFindParameter() {
		let testString = "{{tagName}}"
		let tags:[BoilerPlateTag] = testString.allTemplateEntries
		XCTAssertEqual(tags.count, 1)
		let firstTag = tags.first!
		XCTAssertEqual(firstTag.type, BoilerPlateTagType.parameter)
		XCTAssertEqual(firstTag.tag, "tagName")
		//TODO: check range
	}
	
	func testFindOpen() {
		let testString = "{{#tagName}}"
		let tags:[BoilerPlateTag] = testString.allTemplateEntries
		XCTAssertEqual(tags.count, 1)
		let firstTag = tags.first!
		XCTAssertEqual(firstTag.type, BoilerPlateTagType.scopeOpen("",true))
		XCTAssertEqual(firstTag.tag, "tagName")
		//TODO: check range
	}
	
	func testFindClose() {
		let testString = "{{/tagName}}"
		let tags:[BoilerPlateTag] = testString.allTemplateEntries
		XCTAssertEqual(tags.count, 1)
		let firstTag = tags.first!
		XCTAssertEqual(firstTag.type, BoilerPlateTagType.scopeClose)
		XCTAssertEqual(firstTag.tag, "tagName")
		//TODO: check range
	}
	
	func testFindLoop() {
		let testString = "regular text for before text{{#tagName}}text inside the loop, {{/tagName}}"
		let tags:[BoilerPlateTag] = testString.allTemplateEntries
		XCTAssertEqual(tags.count, 2)
		let firstTag = tags.first!
		XCTAssertEqual(firstTag.type, BoilerPlateTagType.scopeOpen("",true))
		XCTAssertEqual(firstTag.tag, "tagName")
		
		let secondTag = tags.last!
		XCTAssertEqual(secondTag.type, BoilerPlateTagType.scopeClose)
		XCTAssertEqual(secondTag.tag, "tagName")
		//TODO: check range
	}
	
	func testTextReplacement() {
		let plate = BoilerPlate(template: "{{tagName}}")
		let rendered = plate.render(with:["tagName":"Result"])
		XCTAssertEqual(rendered, "Result")
	}
	
	func testDictReplacement() {
		let plate = BoilerPlate(template: "A{{tagName}}C{{tag2}}E")
		let rendered = plate.render(with:["tagName":"B","tag2":"D"])
		XCTAssertEqual(rendered, "ABCDE")
	}
	
	func testDictPeriodReplacement() {
		let plate = BoilerPlate(template: "A{{super.tag}}C")
		let rendered = plate.render(with:["super":Boil(["tag":Boil("B")])])
		XCTAssertEqual(rendered, "ABC")
	}
	
	func testEmptyArrayReplacement() {
		let plate = BoilerPlate(template: "A{{#tagName}}C{{/tagName}}E")
		let substitutions:[String:BoilerPlateItem] = ["tagName":[]]
		let rendered = plate.render(with:substitutions)
		XCTAssertEqual(rendered, "AE")
	}
	
	func testArrayReplacement() {
		let plate = BoilerPlate(template: "A{{#tagName}}{{subTag}}{{super}}{{/tagName}}E")
		let substitutions:[String:BoilerPlateItem] = ["tagName":.array([.dict(["subTag" : "A"]), .dict(["subTag" : "B"])]), "super":"D"]
		let rendered = plate.render(with:substitutions)
		XCTAssertEqual(rendered, "AADBDE")
	}
	
	/*
	func testArrayIndexes() {
	let plate = BoilerPlate(template: "A{{#tagName}}{{.}}:{{subTag}}{{super}}{{/tagName}}E")
	let substitutions = ["tagName":BoilerPlateItem.array([BoilerPlateItem.dict(["subTag" : BoilerPlateItem.text("A")]), BoilerPlateItem.dict(["subTag" : BoilerPlateItem.text("B")])]), "super":BoilerPlateItem.text("D")]
	let rendered = plate.render(with:substitutions)
	XCTAssertEqual(rendered, "A0:AD1:BDE")
	}
	*/
	
	func testArrayDelimiter() {
		let plate = BoilerPlate(template: "A{{#tagName|,}}{{subTag}}{{super}}{{/tagName}}E")
		let substitutions:[String:BoilerPlateItem] = ["tagName":.array([.dict(["subTag" : "A"]), .dict(["subTag" : "B"])]), "super":"D"]
		let rendered = plate.render(with:substitutions)
		XCTAssertEqual(rendered, "AAD,BDE")
	}
	
	
	func testBoil() {
		let plate = BoilerPlate(template: "A{{#tagName|,}}{{subTag}}{{super}}{{/tagName}}E")
		let substitutions = ["tagName":Boil([Boil(["subTag" : Boil("A")]), Boil(["subTag" : Boil("B"), "trial":Boil(true)])]), "super":Boil("D")]
		let rendered = plate.render(with:substitutions)
		XCTAssertEqual(rendered, "AAD,BDE")
	}
	
	
	func testArrayFalse() {
		let plate = BoilerPlate(template: "A{{!tagName}}  There is no content.  {{/tagName}}E")
		let substitutions:[String:BoilerPlateItem] = ["tagName":[], "super":"D"]
		let rendered = plate.render(with:substitutions)
		XCTAssertEqual(rendered, "A  There is no content.  E")
	}
	
	
	func testDictMissingEntry() {
		let plate = BoilerPlate(template: "A{{!missingTagName}}  The content was missing, but super is {{super}}.  {{/missingTagName}}E")
		let substitutions:[String:BoilerPlateItem] = ["tagName":[], "super":"D"]
		let rendered = plate.render(with:substitutions)
		XCTAssertEqual(rendered, "A  The content was missing, but super is D.  E")
	}
	
	func testIgnoreAComment() {
		let plate = BoilerPlate(template: "A{{//tagName}}E")
		let substitutions:[String:BoilerPlateItem] = ["tagName":[], "super":"D"]
		let rendered = plate.render(with:substitutions)
		XCTAssertEqual(rendered, "AE")
	}
	
	
	//testing template libraries
	
	func testLibrary() {
		let library = BoilerPlateLibrary()
		let masterPlate = BoilerPlate(template: "{{^sub}}")
		library.addBoilerPlate(masterPlate, forKey:"master")
		let subPlate = BoilerPlate(template: "{{A}}")
		library.addBoilerPlate(subPlate, forKey:"sub")
		
		let substitutions = ["A":Boil("result")]
		let rendered = masterPlate.render(with:substitutions)
		XCTAssertEqual(rendered, "result")
	}
	
	func testLibraryRegression() {
		let library = BoilerPlateLibrary()
		let masterPlate = BoilerPlate(template: "{{^sub}}A")
		library.addBoilerPlate(masterPlate, forKey:"master")
		let subPlate = BoilerPlate(template: "{{A}}")
		library.addBoilerPlate(subPlate, forKey:"sub")
		
		let substitutions = ["A":Boil("result")]
		let rendered = masterPlate.render(with:substitutions)
		XCTAssertEqual(rendered, "resultA")
	}
	
	func testLibraryIndirection() {
		let library = BoilerPlateLibrary(templates: ["master":"{{^[templateKeyName]}}",
		                                             "A":"B", "B":"b template"])
		let masterPlate = library.boilerPlates.read(work: { $0["master"] })!
		let substitutions = ["templateKeyName":Boil("B")]
		let rendered = masterPlate.render(with:substitutions)
		XCTAssertEqual(rendered, "b template")
	}
	
	
	func testLibraryDictionaryInit() {
		let library = BoilerPlateLibrary(templates:[
			"master":"{{^sub}}"
			,"sub":"{{A}}"
			])
		let substitutions = ["A":Boil("result")]
		let rendered = library.boilerPlates.read { $0["master"] }!.render(with:substitutions)
		XCTAssertEqual(rendered, "result")
	}
	
	
	//TODO: scope replacement
	
}
