//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:33

/*
	File: Keywords
*/
#define KW_FAIL 0 //Fatal error; stop parsing entire script.
#define KW_PASS 1 //OK
#define KW_ERR  2 //Non-fatal error, keyword couldn't be handled properly. Ignore keyword but continue on.
#define KW_WARN 3 //Warning

/*
Class: n_Keyword
Represents a special statement in the code triggered by a keyword.
*/
/n_Keyword
/n_Keyword/New(inline=0)
	src.inline=inline
	return ..()

/*
	Var: inline
	1 if the keyword is in an expression (e.g. the new keyword in many languages), 0 otherwise (such as the if and else keywords).
*/
/n_Keyword/var/inline

/*
	Proc: Parse
	Called when the parser finds a keyword in the code.

	Parameters:
	parser - The parser that created this object. You can use the parameter to manipulate the parser in order to add statements and blocks
	to its AST.
*/
/n_Keyword/proc/Parse(n_Parser/parser)

/*
	Class: nS_Keyword
	A keyword in n_Script. By default these include return, if, else, while, and def. To enable or disable a keyword, change the
	<nS_Options.keywords> list.

	Behavior:
	When a parser is expecting a new statement, and a keyword listed in <nS_Options.keywords> is found, it will call the keyword's
	<n_Keyword.Parse()> proc.
*/
//
/n_Keyword/nS_Keyword
/n_Keyword/nS_Keyword/New(inline=0)
	if(inline)
		del src

/n_Keyword/nS_Keyword/kwReturn
/n_Keyword/nS_Keyword/kwReturn/Parse(n_Parser/nS_Parser/parser)
	.=KW_PASS
	if(istype(parser.curBlock, /node/BlockDefinition/GlobalBlock)) // Exit out of the program by setting the tokens list size to the same as index.
		parser.tokens.len = parser.index
		return
	var/node/statement/ReturnStatement/stmt=new(parser.curToken)
	parser.NextToken()   //skip 'return' token
	stmt.value=parser.ParseExpression()
	parser.curBlock.statements+=stmt

/n_Keyword/nS_Keyword/kwIf
/n_Keyword/nS_Keyword/kwIf/Parse(n_Parser/nS_Parser/parser)
	.=KW_PASS
	var/node/statement/IfStatement/stmt=new(parser.curToken)
	parser.NextToken()  //skip 'if' token
	stmt.cond=parser.ParseParenExpression()
	if(!parser.CheckToken(")", /token/symbol))
		return KW_FAIL
	if(!parser.CheckToken("{", /token/symbol, skip=0)) //Token needs to be preserved for parse loop, so skip=0
		return KW_ERR
	parser.curBlock.statements+=stmt
	stmt.block=new
	parser.AddBlock(stmt.block)

/n_Keyword/nS_Keyword/kwElseIf
/n_Keyword/nS_Keyword/kwElseIf/Parse(n_Parser/nS_Parser/parser)
	.=KW_PASS
	var/list/L=parser.curBlock.statements
	var/node/statement/IfStatement/ifstmt

	if(L && L.len)
		ifstmt = L[L.len] //Get the last statement in the current block
	if(!ifstmt || !istype(ifstmt) || ifstmt.else_if)
		parser.errors += new/scriptError/ExpectedToken("if statement", parser.curToken)
		return KW_FAIL

	var/node/statement/IfStatement/ElseIf/stmt = new(parser.curToken)
	parser.NextToken()  //skip 'if' token
	stmt.cond = parser.ParseParenExpression()
	if(!parser.CheckToken(")", /token/symbol))
		return KW_FAIL
	if(!parser.CheckToken("{", /token/symbol, skip=0)) //Token needs to be preserved for parse loop, so skip=0
		return KW_ERR
	parser.curBlock.statements+=stmt
	stmt.block=new
	ifstmt.else_if = stmt
	parser.AddBlock(stmt.block)


/n_Keyword/nS_Keyword/kwElse
/n_Keyword/nS_Keyword/kwElse/Parse(n_Parser/nS_Parser/parser)
	.=KW_PASS
	var/list/L=parser.curBlock.statements
	var/node/statement/IfStatement/stmt
	if(L&&L.len) stmt=L[L.len] //Get the last statement in the current block
	if(!stmt || !istype(stmt) || stmt.else_block) //Ensure that it is an if statement
		parser.errors+=new/scriptError/ExpectedToken("if statement",parser.curToken)
		return KW_FAIL
	parser.NextToken()         //skip 'else' token
	if(!parser.CheckToken("{", /token/symbol, skip=0))
		return KW_ERR
	stmt.else_block=new()
	parser.AddBlock(stmt.else_block)

/n_Keyword/nS_Keyword/kwWhile
/n_Keyword/nS_Keyword/kwWhile/Parse(n_Parser/nS_Parser/parser)
	.=KW_PASS
	var/node/statement/WhileLoop/stmt=new(parser.curToken)
	parser.NextToken()  //skip 'while' token
	stmt.cond=parser.ParseParenExpression()
	if(!parser.CheckToken(")", /token/symbol))
		return KW_FAIL
	if(!parser.CheckToken("{", /token/symbol, skip=0))
		return KW_ERR
	parser.curBlock.statements+=stmt
	stmt.block=new
	parser.AddBlock(stmt.block)

/n_Keyword/nS_Keyword/kwFor
/n_Keyword/nS_Keyword/kwFor/Parse(n_Parser/nS_Parser/parser)
	.=KW_PASS
	var/node/statement/ForLoop/stmt = new(parser.curToken)
	parser.NextToken()
	if(!parser.CheckToken("(", /token/symbol))
		return KW_FAIL
	stmt.init = parser.ParseExpression()
	if(!parser.CheckToken(";", /token/end))
		return KW_FAIL
	stmt.test = parser.ParseExpression()
	if(!parser.CheckToken(";", /token/end))
		return KW_FAIL
	stmt.increment = parser.ParseExpression(list(")"))
	if(!parser.CheckToken(")", /token/symbol))
		return KW_FAIL
	if(!parser.CheckToken("{", /token/symbol, skip=0))
		return KW_ERR
	parser.curBlock.statements += stmt
	stmt.block = new
	parser.AddBlock(stmt.block)

/n_Keyword/nS_Keyword/kwBreak
/n_Keyword/nS_Keyword/kwBreak/Parse(n_Parser/nS_Parser/parser)
	.=KW_PASS
	if(istype(parser.curBlock, /node/BlockDefinition/GlobalBlock))
		parser.errors+=new/scriptError/BadToken(parser.curToken)
		. = KW_WARN
	var/node/statement/BreakStatement/stmt=new(parser.curToken)
	parser.NextToken()   //skip 'break' token
	parser.curBlock.statements+=stmt

/n_Keyword/nS_Keyword/kwContinue
/n_Keyword/nS_Keyword/kwContinue/Parse(n_Parser/nS_Parser/parser)
	.=KW_PASS
	if(istype(parser.curBlock, /node/BlockDefinition/GlobalBlock))
		parser.errors+=new/scriptError/BadToken(parser.curToken)
		. = KW_WARN
	var/node/statement/ContinueStatement/stmt=new(parser.curToken)
	parser.NextToken()   //skip 'break' token
	parser.curBlock.statements+=stmt

/n_Keyword/nS_Keyword/kwDef
/n_Keyword/nS_Keyword/kwDef/Parse(n_Parser/nS_Parser/parser)
	.=KW_PASS
	var/node/statement/FunctionDefinition/def=new(parser.curToken)
	parser.NextToken() //skip 'def' token
	if(!parser.options.IsValidID(parser.curToken.value))
		parser.errors+=new/scriptError/InvalidID(parser.curToken)
		return KW_FAIL
	def.func_name=parser.curToken.value
	parser.NextToken()
	if(!parser.CheckToken("(", /token/symbol))
		return KW_FAIL
	while(TRUE) //for now parameters can be separated by whitespace - they don't need a comma in between
		if(istype(parser.curToken, /token/symbol))
			switch(parser.curToken.value)
				if(",")
					parser.NextToken()
				if(")")
					break
				else
					parser.errors+=new/scriptError/BadToken(parser.curToken)
					return KW_ERR

		else if(istype(parser.curToken, /token/word))
			def.parameters+=parser.curToken.value
			parser.NextToken()
		else
			parser.errors+=new/scriptError/InvalidID(parser.curToken)
			return KW_ERR
	if(!parser.CheckToken(")", /token/symbol))
		return KW_FAIL

	if(istype(parser.curToken, /token/end)) //Function prototype
		parser.curBlock.statements+=def
	else if(parser.curToken.value=="{" && istype(parser.curToken, /token/symbol))
		def.block = new
		parser.curBlock.statements.Insert(1, def) // insert into the beginning so that all functions are defined first
		parser.curBlock.functions[def.func_name]=def
		parser.AddBlock(def.block)
	else
		parser.errors+=new/scriptError/BadToken(parser.curToken)
		return KW_FAIL

#undef KW_FAIL
#undef KW_PASS
#undef KW_ERR
#undef KW_WARN
