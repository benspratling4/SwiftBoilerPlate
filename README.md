# SwiftBoilerPlate

Create a boilerPlate with a template string.

	let boilerPlate:BoilerPlate = BoilerPlate(template:"Howdy, {{name}}!")

This is based on mustache templates, but has a more Swift syntax.

	let rendered:String = boilerPlate.render(with:["name":"World"])
	//Howdy, World!

	let plate = BoilerPlate(template: "A{{super.tag}}C")
	let rendered = plate.render(with:["super":Boil(["tag":Boil("B")])])
	//"ABC"

You still wrap tags with {{ ... }}, but white space is not allowed.

	let plate = BoilerPlate(template: "A{{#tagName}}{{subTag}}{{super}}{{/tagName}}E")
	let substitutions:[String:BoilerPlateItem] = ["tagName":.array([.dict(["subTag" : "A"]), .dict(["subTag" : "B"])]), "super":"D"]
	let rendered = plate.render(with:substitutions)
	//AADBDE

Arrays, bools, and entries still begin with a "#" and end with a "/".

	let plate = BoilerPlate(template: "A{{!tagName}}  There is no content.  {{/tagName}}E")
	let substitutions:[String:BoilerPlateItem] = ["tagName":[], "super":"D"]
	let rendered = plate.render(with:substitutions)
	//"A  There is no content.  E"


But instead of ^ for "not", use "!".

	let plate = BoilerPlate(template: "A{{//tagName}}E")
	let substitutions:[String:BoilerPlateItem] = ["tagName":[], "super":"D"]
	let rendered = plate.render(with:substitutions)
	//"AE"

Use "//" for a comment tag.

	let plate = BoilerPlate(template: "A{{#tagName|,}}{{subTag}}{{super}}{{/tagName}}E")
	let substitutions:[String:BoilerPlateItem] = ["tagName":.array([.dict(["subTag" : "A"]), .dict(["subTag" : "B"])]), "super":"D"]
	let rendered = plate.render(with:substitutions)
	//"AAD,BDE"

In an array tag, you can specify a delimiter by adding "|" followed by the delimiter.

	let library = BoilerPlateLibrary(templates:[
		"master":"{{^sub}}"
		,"sub":"{{A}}"
	])
	let substitutions = ["A":Boil("result")]
	let rendered = library.boilerPlates.read { $0["master"] }!.render(with:substitutions)
	//"result")

Use "^" to name another template in the same library.

	let library = BoilerPlateLibrary(templates: ["master":"{{^[templateKeyName]}}",
		"A":"B", "B":"b template"])
	let masterPlate = library.boilerPlates.read(work: { $0["master"] })!
	let substitutions = ["templateKeyName":Boil("B")]
	let rendered = masterPlate.render(with:substitutions)
	//"b template"


Use ^[...] to fetch the name of the template from the dictionary entry
