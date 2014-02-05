package parsers;
import java.util.Stack;
import java.util.regex.Matcher;
import java.util.regex.Pattern;




//Based on the Berkeley Grammar: http://inst.eecs.berkeley.edu/~cs164/fa11/python-grammar.html
//and 
// http://docs.python.org/release/2.5.4/ref/ref.html and http://docs.python.org/2/tutorial/
//and 
// the Python 2.4.6 grammar specification included with Python 2.4.6: Python-2.4.6/Grammar/Grammar





%%
%parser Python

%aux{
   Boolean DEBUG; 
   Integer parenLevel; //for parens, curly brackets and regular brackets 
   Stack<Integer> depths;
   public void runPostParseCode(Object root)
   {
     System.out.println();
   }
%aux}

%init{
   DEBUG = false;
   parenLevel = 0;
   depths = new Stack<Integer>();
   depths.push(0);
%init}

%lex{


//////////////////////////Disambiguation Functions


//These three disambiguate longStringComment_t from other strings.

 disambiguate comment1:(longStringComment_t,longStringFuncDocString_t)
 {:
   if(DEBUG) System.out.println("Disambiguate: " + "longStringComment_t,longStringFuncDocString_t");
   return longStringFuncDocString_t;
 :};

 disambiguate comment2:(longStringComment_t,longStringFuncDocString_t, longString_t)
 {:
   if(DEBUG) System.out.println("Disambiguate: " + "longStringComment_t,longStringFuncDocString_t, longString_t");
   return longStringFuncDocString_t;
 :};

 disambiguate comment3:(longStringComment_t, longString_t)
 {:
   if(DEBUG) System.out.println("Disambiguate: " + "longStringFuncDocString_t, longString_t");
   return longString_t;
 :};



//These 5 functions disambiguate whitespace terminals from each other

 disambiguate ignoredNewline1:(Newline_t,ignoredNewline)
 {:
   if(DEBUG) System.out.println("Disambiguate: " + "Newline_t,ignoredNewline");
   if(parenLevel > 0){
     return ignoredNewline;
   }
   else
   {
     return Newline_t;
   }
 :};

 disambiguate ignoredNewline2:(Newline_t,ignoredNewline, Dedent_t)
 {:
   if(DEBUG) System.out.println("Disambiguate: " + "Newline_t,ignoredNewline, Dedent_t");
   if(parenLevel > 0){
     return ignoredNewline;
   }
   //Given the lexeme of the terminals, need to treat all but the last "\n[\t ]*" as whitespace
   Pattern input = Pattern.compile("\n[\t ]*");
   Matcher inputPattern = input.matcher(lexeme);
   String output = "";
   while(inputPattern.find())
   {
     output = inputPattern.group();
     if(DEBUG) System.out.println("\"" + inputPattern.group() + "\"\n");
   }
   int newDepth = output.length() - 1;
   if(newDepth < depths.peek())  
   {
     return Dedent_t;
   } 
   else
   {   
     return Newline_t;
   }
 :};



 disambiguate ignoredNewline3:(ignoredNewline, Dedent_t)
 {:
   if(DEBUG) System.out.println("Disambiguate: " + "ignoredNewline, Dedent_t");
   if(parenLevel > 0){
     return ignoredNewline;
   }
   return Dedent_t;
  
 :};


 disambiguate ignoredNewline4:(ignoredNewline, Indent_t)
 {:
   if(DEBUG) System.out.println("Disambiguate: " + "ignoredNewline, Indent_t");
   if(parenLevel > 0){
     return ignoredNewline;
   }
   return Indent_t;
  
 :};


 disambiguate ignoredNewline5:(ignoredNewline, Newline_t, DedentRepair_t)
 {:
   if(DEBUG) System.out.println("Disambiguate: " + "ignoredNewline, Newline_t, DedentRepair_t");
   if(parenLevel > 0){
     return ignoredNewline;
   }
   //Given the lexeme of the terminals, need to treat all but the last "\n[\t ]*" as whitespace
   Pattern input = Pattern.compile("\n[\t ]*");
   Matcher inputPattern = input.matcher(lexeme);
   String output = "";
   while(inputPattern.find())
   {
     output = inputPattern.group();
     if(DEBUG) System.out.println("\"" + inputPattern.group() + "\"\n");
   }
   int newDepth = output.length() - 1;
   if(newDepth < depths.peek())  
   {
     return DedentRepair_t;
   } 
   else
   {  
     return Newline_t;
   }
    
 :};


////////////////////Terminals
  
 class keywds;
 class specialNumbers;


 
 terminal Indent_t ::= /(\n[ \t]*)+/ 
 {: 
   //Need to determine new indentation depth and will treat all but the last "\n[\t ]*" as whitespace
   Pattern input = Pattern.compile("\n[\t ]*");
   Matcher inputPattern = input.matcher(lexeme);
   String output = "";
   while(inputPattern.find())
   {
     output = inputPattern.group();
     if(DEBUG) System.out.println("\"" + inputPattern.group() + "\"\n");
   }
   int newDepth = output.length() - 1;
   depths.push(newDepth);   
 :} ;

 terminal Dedent_t ::= /(\n[ \t]*)+/ 
 {:    
   //Need to determine new indentation depth and will treat all but the last "\n[\t ]*" as whitespace 
   Pattern input = Pattern.compile("\n[\t ]*");
   Matcher inputPattern = input.matcher(lexeme);
   String output = "";
   while(inputPattern.find())
   {
     output = inputPattern.group();
     if(DEBUG) System.out.println("\"" + inputPattern.group() + "\"\n");
   }
   int newDepth = output.length() - 1;
   depths.pop();
   if(newDepth < depths.peek())
   {
     pushToken(Terminals.Dedent_t,output);
   } 
 :};



 terminal DedentRepair_t ::= /(\n[ \t]*)+/ 
 {:  
   pushToken(Terminals.Dedent_t,lexeme); 
 :};







 //Whitepace

 ignore terminal comment_t  ::= /#([^\r\n])*/ ;
 ignore terminal comment2_t  ::= /(\n[ \t]*)+#([^\r\n])*/ ;
 ignore terminal longStringComment_t ::= /(\n[ \t]*)*('''([^']|'[^']|''[^'])*''')|("""([^"]|"[^"]|""[^"])*""")/ ;
 ignore terminal Spaces_t ::= /[ \t]+|(\\\n)/;
 ignore terminal ignoredNewline ::= /(\n[ \t]*)+/;
 terminal Newline_t ::= /(\n[ \t]*)+/;

 //Keywords

 terminal lambdaKwd_t  ::= /lambda/ in ( keywds ) ;
 terminal classKwd_t  ::= /class/ in ( keywds ) ;
 terminal execKwd_t  ::= /exec/ in ( keywds ) ;
 terminal globalKwd_t  ::= /global/ in ( keywds ) ;
 terminal fromKwd_t  ::= /from/ in ( keywds ) ;
 terminal importKwd_t  ::= /import/ in ( keywds ) ;
 terminal continueKwd_t  ::= /continue/ in ( keywds ) ;
 terminal breakKwd_t  ::= /break/ in ( keywds ) ;
 terminal raiseKwd_t  ::= /raise/ in ( keywds ) ;
 terminal returnKwd_t ::= /return/ in ( keywds );
 terminal passKwd_t ::= /pass/ in ( keywds ) ;
 terminal delKwd_t ::= /del/ in ( keywds ) ;
 terminal yieldKwd_t ::= /yield/ in ( keywds ) ;
 terminal assertKwd_t ::= /assert/ in ( keywds ) ;
 terminal defKwd_t ::= /def/ in ( keywds ) ;
 terminal withKwd_t ::= /with/ in ( keywds ) ;
 terminal asKwd_t ::= /as/ in ( keywds ) ;
 terminal finallyKwd_t ::= /finally/ in ( keywds ) ;
 terminal exceptKwd_t ::= /except/ in ( keywds ) ;
 terminal tryKwd_t ::= /try/ in ( keywds ) ;
 terminal ifKwd_t ::= /if/ in ( keywds ) ;
 terminal elifKwd_t ::= /elif/ in ( keywds ) ;
 terminal elseKwd_t ::= /else/ in ( keywds ) ;
 terminal forKwd_t ::= /for/ in ( keywds ) ;
 terminal printKwd_t ::= /print/ in ( keywds ) ;
 terminal whileKwd_t ::= /while/ in ( keywds ) ;
 terminal orWordKwd_t ::= /or/ in ( keywds ) ;
 terminal andWordKwd_t ::= /and/ in ( keywds ) ;
 terminal notWordKwd_t ::= /not/ in ( keywds ) ;
 terminal isKwd_t ::= /is/  in ( keywds )  ;
 terminal inKwd_t ::= /in/  in ( keywds )  ;
 terminal isNotKwd_t ::= /is[\s\t ]*not/   in ( keywds ) ;
 terminal notInKwd_t ::= /not[\s\t ]*in/   in ( keywds ) ;



 //Special class of numbers with lexical precdence over identifier_t

 terminal hexInteger_t ::= /0[xX][0-9A-Fa-f]+/   in ( specialNumbers ) ;
 terminal octInteger_t ::= /0[0-7]+/   in ( specialNumbers ) ;


 //Other numbers

 terminal exponent_t ::= /[eE][\+\-]?[0-9]+/ ;
 terminal pointFloat_t ::= /(([0-9]+)?\.[0-9]+)|[0-9]+\./ ;
 terminal pointFloatExponent_t ::= /((([0-9]+)?\.[0-9]+)|[0-9]+\.)[eE][\+\-]?[0-9]+/ ;
 terminal pointIntExponent_t ::= /[0-9]+[eE][\+\-]?[0-9]+/ ;
 terminal longIntegerPart_t ::= /lL/ ;
 terminal decimalInteger_t ::= /([1-9][0-9]*)|0/ ;
 terminal decimalIntegerLong_t ::= /(([1-9][0-9]*)|0)[lL]/ ;
 terminal hexIntegerLong_t ::= /(0[xX][0-9A-Fa-f]+)[lL]/   in ( specialNumbers ) ;
 terminal octIntegeLong_t ::= /(0[0-7]+)[lL]/   in ( specialNumbers ) ;
 terminal pointFloatExponentImagNumber_t ::= /((([0-9]+)?\.[0-9]+)|[0-9]+\.)[jJ]/ ; 
 terminal decimalIntegerImagNumber_t ::= /(([1-9][0-9]*)|0)[jJ]/ ;



 //Identifiers

 terminal identifier_t ::= /[a-zA-Z_][a-zA-Z_0-9]*/ in (), < (keywds, specialNumbers), > () ;
 
 //Operators and others
 
 terminal ellipsis_t ::= /\.\.\./ ;
 terminal power_t ::= /\*\*/ ;
 terminal power2_t ::= /\*\*/ ;
 terminal tilde_t ::= /~/ ;
 terminal plus_t ::= /\+/ ;
 terminal dash_t ::= /-/ ;
 terminal Multiply_ ::= /\*/ ;
 terminal divide_t ::= /\// ;
 terminal doubleDivide_t ::= /\/\// ;
 terminal modulus_t ::= /%/ ;
 terminal colon_t ::= /:/ ;
 terminal semicolon_t ::= /;/ ;
 terminal comma_t ::= /,/ ;
 terminal openParen_t ::= /\(/  {:  parenLevel++; :};
 terminal closeParen_t ::= /\)/ {:  parenLevel--; :};
 terminal openBracket_t ::= /\[/  {:  parenLevel++; :};
 terminal closeBracket_t ::= /\]/  {:  parenLevel--; :};
 terminal less_t ::= /</  ; 
 terminal greater_t ::= />/  ;
 terminal doubleEquals_t ::= /==/  ; 
 terminal greaterEqual_t ::= />=/  ;
 terminal lessEqual_t ::= /<=/  ;
 terminal notEqual_t ::= /<>/  ;
 terminal notEqual2_t ::= /!=/  ;
 terminal xor_t ::= /^/  ;
 terminal or_t ::= /\|/ in ( keywds ) ;
 terminal and_t ::= /&/ in ( keywds ) ;
 terminal rightShift_t ::= />>/ in ( keywds ) ;
 terminal leftShift_t ::= /<</ in ( keywds ) ;
 terminal backTick_t ::= /`/ ;
 terminal openCurly_t ::= /{/ ;
 terminal closeCurly_t ::= /}/ ;
 terminal at_t ::= /@/ ;
 terminal period_t ::= /\./ ;
 terminal Asterisk_t ::= /\*/ ;
 terminal equals_t ::= /=/ ;



///////Augmented Assignments

 terminal plusEqual_t ::= /+=/ ;
 terminal minusEqual_t ::= /-=/ ;
 terminal multiplyEqual_t ::= /*=/ ;
 terminal divideEqual_t ::= /\/=/ ;
 terminal doubleDivideEqual_t ::= /\/\/=/ ;
 terminal modulusEqual_t ::= /%=/ ;
 terminal powerEqual_t ::= /\*\*=/ ;
 terminal rightShiftEqual_t ::= />>=/ ;
 terminal leftShiftEqual_t ::= /<<=/ ;
 terminal andEqual_t ::= /&=/ ;
 terminal exponentEqual_t ::= /^=/ ;
 terminal orEqual_t ::= /\|=/ ;


//////////String


terminal prefixedShortString_t ::= /(u|U)(('([^'\n]|\\.|\\O[0-7])*')|("([^"\n]|\\.|\\O[0-7])*"))/ ;
terminal prefixedRawShortString_t ::= /(r|ur|R|UR|Ur|uR)(('([^']|\\.)*')|("([^"]|\\.)*"))/ ;
terminal prefixedLongString_t ::= /(u|U)(('''([^\\]|\\.|\\O[0-7])*''')|("""([^\\]|\\.|\\O[0-7])*"""))/ ;
terminal prefixedRawLongString_t ::= /(r|ur|R|UR|Ur|uR)(('''([^\\]|\\.)*''')|("""([^\\]|\\.)*"""))/ ;
terminal shortString_t ::= /(('([^'\n]|\\.|\\O[0-7])*')|("([^"\n]|\\.|\\O[0-7])*"))|(('([^']|\\.)*')|("([^"]|\\.)*"))/ ;
terminal longString_t ::= /('''([^']|'[^']|''[^'])*''')|("""([^"]|"[^"]|""[^"])*""")/ ;
terminal longStringFuncDocString_t ::= /(\n[ \t]*)+('''([^']|'[^']|''[^'])*''')|("""([^"]|"[^"]|""[^"])*""")/ ;

%lex}

%cf{





 non terminal FileInput;
 non terminal FileContents;
 non terminal Suite;
 non terminal StmtList;
 non terminal Statements;
 non terminal Statement;
 non terminal CompoundStmt;
 non terminal SimpleStmts;
 non terminal SimpleStmt;
 non terminal ExpressionStmt;
 non terminal IfStmt;
 non terminal ElsIf;
 non terminal WhileStmt;
 non terminal ForStmt;
 non terminal TryStmt;
 non terminal WithStmt;
 non terminal Classdef;
 non terminal TargetList;
 non terminal Targets;
 non terminal Target;
 non terminal Try1Stmt;
 non terminal Try2Stmt;
 non terminal Except;
 non terminal ExceptOptions;
 non terminal ExpressionList;
 non terminal Expressions;
 non terminal Expression;
 non terminal ConditionalExpression;
 non terminal OrTest;
 non terminal AndTest;
 non terminal NotTest;
 non terminal Comparison;
 non terminal OrExpr;
 non terminal XorExpr;
 non terminal AndExpr;
 non terminal ShiftExpr; 
 non terminal AExpr;
 non terminal MExpr;
 non terminal UExpr;
 non terminal Power;
 non terminal Primary;
 non terminal Atom;
 non terminal Literal;
 non terminal Integer; 
 non terminal LongInteger;
 non terminal FloatNumber;
 non terminal ImagNumber;
 non terminal ExponentFloat; 
 non terminal AttributeRef;
 non terminal Slicing;
 non terminal ExtendedSlicing;
 non terminal SliceItem;
 non terminal SliceOptions;
 non terminal ProperSlice;
 non terminal ShortSlice;
 non terminal LongSlice;
 non terminal LowerBound;
 non terminal UpperBound;
 non terminal Stride;
 non terminal Call;
 non terminal GenExprFor;
 non terminal GenExprIter;
 non terminal GenExprIf;
 non terminal OldExpression;
 non terminal OldLambdaForm;
 non terminal LambdaForm;
 non terminal Enclosure;
 non terminal ParenthForm;
 non terminal ListDisplay;
 non terminal GeneratorExpression;
 non terminal DictDisplay;
 non terminal StringConversion;
 non terminal YieldAtom; 
 non terminal ListFor;
 non terminal OldExpressionList;
 non terminal OldExpressions;
 non terminal OldExpressionsOptionalComma;
 non terminal ListIter;
 non terminal ListIf;
 non terminal KeyDatumList;
 non terminal KeyDatums;
 non terminal KeyDatum;
 non terminal ListComprehension;
 non terminal ExpressionsNoCommaEnding;
 non terminal AssertStmt;
 non terminal AssignmentStmt;
 non terminal Items;
 non terminal YieldExpression;
 non terminal AugmentedAssignmentStmt;
 non terminal Augop;
 non terminal PassStmt;
 non terminal DelStmt;
 non terminal PrintStmt;
 non terminal ReturnStmt;
 non terminal YieldStmt;
 non terminal RaiseStmt;
 non terminal BreakStmt;
 non terminal ContinueStmt;
 non terminal ImportStmt;
 non terminal RestOfImport;
 non terminal Module;
 non terminal IdentifierAsName;
 non terminal Periods;
 non terminal IdentifiersPeriodSeperated ;
 non terminal Name;
 non terminal GlobalStmt;
 non terminal IdentifiersCommaSeperated;
 non terminal ExecStmt;
 non terminal Classname;
 non terminal Inheritance;
 non terminal CompOperator;
 non terminal Funcdef; 
 non terminal ArgumentListOptionalAsteriskExpression;
 non terminal ArgumentListOptionalPowerExpression;
 non terminal KeywordArguments;
 non terminal KeywordItem;
 non terminal ArgumentList;
 non terminal DefParameter;
 non terminal DefParameters;
 non terminal Parameter;
 non terminal SubList;
 non terminal SubListParameters;
 non terminal Decorators;
 non terminal SeveralDecorators;
 non terminal Decorator;
 non terminal Funcname;
 non terminal ParameterList;
 non terminal DottedName;
 non terminal DottedNameOptionalPart;
 non terminal DefList;
 non terminal MoreModules;
 non terminal ArgListAux;
 non terminal StringLiteral;
 non terminal StringLiteralPiece;
 

//////////////








/////////PRODUCTIONS






//////Basic Program Structure

 start with FileInput;
 
///////////////////////////////

 FileInput ::= FileContents;
 
 FileContents ::= Newline_t FileContents 
  | Statement FileContents 
  | Newline_t 
  | Statement
  ;

 


 Suite ::= StmtList Newline_t
  | StmtList DedentRepair_t
  | Indent_t Statements Dedent_t            
  ;

 Statements ::= Statement Statements 
  | Statement 
  ;
 
 Statement ::= StmtList Newline_t 
  |  StmtList DedentRepair_t                                                                                     
  |  CompoundStmt  
  ;





 StmtList ::= SimpleStmts;



/////Simple Statements



 SimpleStmts ::= SimpleStmt semicolon_t SimpleStmts  
  | SimpleStmt semicolon_t 
  | SimpleStmt 
  ;
 
 SimpleStmt ::= ExpressionStmt
  | AssertStmt
  | AssignmentStmt
  | AugmentedAssignmentStmt
  | PassStmt
  | DelStmt
  | PrintStmt
  | ReturnStmt
  | YieldStmt
  | RaiseStmt
  | BreakStmt
  | ContinueStmt
  | ImportStmt
  | GlobalStmt
  | ExecStmt
  ;

 ExpressionStmt ::= ExpressionList;

 ExecStmt ::= execKwd_t OrExpr inKwd_t Expression comma_t Expression
  | execKwd_t OrExpr inKwd_t Expression
  | execKwd_t OrExpr
  ;

 GlobalStmt ::= globalKwd_t identifier_t IdentifiersCommaSeperated;

 IdentifiersCommaSeperated ::=  comma_t identifier_t IdentifiersCommaSeperated
  |
  ;





 ImportStmt ::= importKwd_t Module asKwd_t identifier_t MoreModules
  |  importKwd_t Module  MoreModules
  |  fromKwd_t Periods RestOfImport //Relative Module
  |  fromKwd_t Periods Module RestOfImport //Relative Module
  |  fromKwd_t Module RestOfImport //Relative Module
  |  fromKwd_t Module importKwd_t Asterisk_t //Regular Module
  ;


 RestOfImport ::= importKwd_t identifier_t asKwd_t Name IdentifierAsName
  | importKwd_t identifier_t IdentifierAsName
  | importKwd_t openParen_t identifier_t asKwd_t Name IdentifierAsName closeParen_t 
  | importKwd_t identifier_t IdentifierAsName closeParen_t
  | importKwd_t identifier_t 
  ;

 MoreModules ::= comma_t Module asKwd_t identifier_t MoreModules
  | comma_t Module MoreModules
  | ;


 IdentifierAsName ::= comma_t identifier_t asKwd_t Name IdentifierAsName
  | comma_t identifier_t IdentifierAsName
  | comma_t identifier_t asKwd_t Name
  | comma_t identifier_t
  | comma_t
  ;

 Module ::= IdentifiersPeriodSeperated;
 
 IdentifiersPeriodSeperated ::= identifier_t period_t IdentifiersPeriodSeperated
  | identifier_t 
  ;

 Periods ::= period_t Periods
  | period_t ; 
 
 Name ::= identifier_t;
 

 ContinueStmt ::= continueKwd_t;

 BreakStmt ::= breakKwd_t;

 RaiseStmt ::= raiseKwd_t Expression comma_t Expression comma_t Expression
  | raiseKwd_t Expression comma_t Expression
  | raiseKwd_t Expression 
  | raiseKwd_t
  ;

 YieldStmt ::= YieldExpression;

 ReturnStmt ::= returnKwd_t ExpressionList
  | returnKwd_t;

 PrintStmt ::= printKwd_t ExpressionList
  | printKwd_t 
  | printKwd_t rightShift_t Expression comma_t ExpressionList
  | printKwd_t rightShift_t Expression 
  ;

 DelStmt ::= delKwd_t TargetList;


 PassStmt ::= passKwd_t;


 
///////Aug Assignment Statements

 AugmentedAssignmentStmt ::= Expression Augop ExpressionList
  | Expression Augop YieldExpression;

 Augop ::= plusEqual_t
  | minusEqual_t
  | multiplyEqual_t
  | divideEqual_t 
  | doubleDivideEqual_t 
  | modulusEqual_t
  | powerEqual_t
  | rightShiftEqual_t
  | leftShiftEqual_t
  | andEqual_t
  | exponentEqual_t
  | orEqual_t 
  ;

///////Assignment Statements


 AssignmentStmt ::= Items;



 Items ::= ExpressionList equals_t Items
  | ExpressionList equals_t YieldExpression
  | ExpressionList equals_t ExpressionList;



 TargetList ::= Targets;
 
 Targets ::= Target comma_t Targets 
  | Target comma_t
  | Target;

 Target ::= identifier_t
  | openParen_t ExpressionList closeParen_t
  | openBracket_t ExpressionList closeBracket_t
  | AttributeRef
//  | Subscription
  | Slicing                                                                                             
  ;


///////END Statements


/////////Expressions

 ExpressionList ::= Expressions;
 
 Expressions ::= Expression comma_t Expressions
  | Expression comma_t
  | Expression;
 
 Expression ::= ConditionalExpression //may reduce to an identifier_t in the simplest case
  | LambdaForm                                                                               
  ;

 LambdaForm ::= lambdaKwd_t ParameterList colon_t Expression
  | lambdaKwd_t colon_t Expression
  ;

 YieldExpression ::= yieldKwd_t ExpressionList
  | yieldKwd_t;

 AssertStmt ::= assertKwd_t Expression comma_t Expression
  | assertKwd_t Expression;
 
 ConditionalExpression ::= OrTest ifKwd_t OrTest elseKwd_t Expression
  | OrTest
  ; 

 OrTest ::= AndTest 
  | OrTest orWordKwd_t AndTest;

 AndTest ::= NotTest 
  | AndTest andWordKwd_t NotTest
  ; 

 NotTest ::= Comparison
  | notWordKwd_t NotTest;

 Comparison ::= OrExpr CompOperator Comparison
  | OrExpr;


 CompOperator ::= less_t
  | greater_t
  | doubleEquals_t
  | greaterEqual_t
  | lessEqual_t
  | notEqual_t
  | notEqual2_t
  | isKwd_t
  | inKwd_t
  | isNotKwd_t
  | notInKwd_t
  ;


 AndExpr ::= ShiftExpr
  | AndExpr and_t ShiftExpr;

 XorExpr ::= AndExpr 
  | XorExpr xor_t AndExpr; 
 
  non terminal OrExprs;

  OrExprs ::= OrExpr comma_t OrExprs
   | OrExpr comma_t
   | OrExpr;

 OrExpr ::= XorExpr 
  | OrExpr or_t XorExpr;

 ShiftExpr ::= AExpr
  | ShiftExpr rightShift_t AExpr
  | ShiftExpr leftShift_t AExpr;

 AExpr ::= MExpr 
  | AExpr plus_t MExpr
  | AExpr dash_t MExpr;

 MExpr ::= UExpr 
  | MExpr Multiply_ UExpr
  | MExpr divide_t UExpr 
  | MExpr doubleDivide_t UExpr 
  | MExpr modulus_t UExpr 
  ; 

 UExpr ::= Power 
  | dash_t UExpr
  | plus_t UExpr 
  | tilde_t UExpr;
  
 Power ::= Primary
  | Primary power_t UExpr;


 Primary ::= Atom
  | AttributeRef
 // | Subscription
  | Slicing
  | Call            
  ;

 Atom ::= identifier_t
  | Literal
  | Enclosure          
  ;
 

 Enclosure ::= ParenthForm 
  | ListDisplay
  | GeneratorExpression
  | DictDisplay
  | StringConversion
  | YieldAtom
  ;



 ParenthForm ::= openParen_t ExpressionList closeParen_t 
  | openParen_t closeParen_t;

 ListDisplay ::= openBracket_t ExpressionList closeBracket_t
  | openBracket_t ListComprehension closeBracket_t
  | openBracket_t closeBracket_t
  ;
 
 ListComprehension ::= Expression ListFor;

 ListFor ::= forKwd_t OrExprs inKwd_t OldExpressionList ListIter
  | forKwd_t OrExprs inKwd_t  OldExpressionList;

 OldExpressionList ::= OldExpression OldExpressions;
 
 OldExpressions ::=  comma_t OldExpression OldExpressions 
  | comma_t OldExpression OldExpressionsOptionalComma
  |;

 OldExpressionsOptionalComma ::=  comma_t;

 ListIter ::= ListFor 
  | ListIf
  ;
 
 ListIf ::= ifKwd_t OldExpression ListIter
  | ifKwd_t OldExpression
  ;

 GeneratorExpression ::= openParen_t Expression GenExprFor closeParen_t;
 
 GenExprFor ::= forKwd_t OrExprs inKwd_t OrTest GenExprIter
  |             forKwd_t OrExprs inKwd_t OrTest
  ;
 
 GenExprIter ::= GenExprFor
  | GenExprIf;

 DictDisplay ::= openCurly_t KeyDatumList closeCurly_t
  | openCurly_t closeCurly_t
  ;


 KeyDatumList ::= KeyDatums;

 KeyDatums ::= KeyDatum comma_t KeyDatums
  | KeyDatum comma_t
  | KeyDatum
  ;

 KeyDatum ::= Expression colon_t Expression;


 
 ExpressionsNoCommaEnding ::= Expression comma_t ExpressionsNoCommaEnding
  | Expression;


 StringConversion ::= backTick_t ExpressionsNoCommaEnding backTick_t;

 YieldAtom ::= openParen_t YieldExpression closeParen_t;


 AttributeRef ::= Primary period_t identifier_t;


// Subscription ::= Primary openBracket_t ExpressionList closeBracket_t;


 Slicing ::= Primary openBracket_t SliceOptions closeBracket_t;



//Slices




 SliceOptions ::= ExtendedSlicing; //ExtendedSlicing

// SimpleSlicing ::= ShortSlice;

 ExtendedSlicing ::= SliceItem 
  | SliceItem comma_t ExtendedSlicing                                                               
  | SliceItem comma_t                                                                        
  ;

 SliceItem ::= ProperSlice
  | Expression                                                                                                     
  | ellipsis_t
  ;


 ProperSlice ::= ShortSlice
  | LongSlice ;

 ShortSlice ::= LowerBound colon_t UpperBound 
  | LowerBound colon_t 
  | colon_t UpperBound 
  | colon_t
  ; 

 LongSlice ::= ShortSlice colon_t Stride 
  | ShortSlice colon_t;


 LowerBound ::= Expression;
 UpperBound ::= Expression;
 Stride ::= Expression;



 Call ::= Primary openParen_t ArgumentList closeParen_t
  | Primary openParen_t Expression GenExprFor closeParen_t
  | Primary openParen_t closeParen_t
  ;




 GenExprIf ::= ifKwd_t OldExpression GenExprIter 
  | ifKwd_t OldExpression 
  ;



 OldExpression ::= OrTest
  | OldLambdaForm
  ;

 OldLambdaForm ::= lambdaKwd_t ParameterList colon_t OldExpression                                       
  | lambdaKwd_t colon_t OldExpression
  ;

 Literal ::= StringLiteral                                                                                                
  | Integer
  | LongInteger
  | FloatNumber
  | ImagNumber
  ;



 StringLiteral ::= StringLiteralPiece
  | StringLiteralPiece StringLiteralPiece;

 StringLiteralPiece ::= prefixedShortString_t
 | shortString_t
 | prefixedLongString_t
 | longString_t
 | prefixedRawShortString_t
 | prefixedRawLongString_t
 ;
  

 Integer ::= decimalInteger_t
  | octInteger_t
  | hexInteger_t
  ;

 LongInteger ::= decimalIntegerLong_t
  | hexIntegerLong_t
  | octIntegeLong_t
  ;


 FloatNumber ::= pointFloat_t
  | ExponentFloat  
  ;

 ExponentFloat ::= pointFloatExponent_t
  | pointIntExponent_t  
  ;

 ImagNumber ::= pointFloatExponentImagNumber_t
  | decimalIntegerImagNumber_t
  ; 




////END Expressions

 

/////Compound Statements

 CompoundStmt ::= IfStmt
  | WhileStmt
  | ForStmt
  | TryStmt
  | WithStmt
  | Funcdef
  | Classdef
  ;


 IfStmt ::= ifKwd_t Expression colon_t Suite ElsIf elseKwd_t colon_t Suite    //Note: The dangling else ambiguity is solved here with indentation
  |  ifKwd_t Expression colon_t Suite ElsIf
  ;

 
 ElsIf ::= elifKwd_t Expression colon_t Suite ElsIf
  |;

 WhileStmt ::= whileKwd_t Expression colon_t Suite elseKwd_t colon_t Suite 
  |  whileKwd_t Expression colon_t Suite
  ;

 ForStmt ::= forKwd_t OrExprs inKwd_t ExpressionList colon_t Suite elseKwd_t colon_t Suite
  | forKwd_t OrExprs inKwd_t ExpressionList colon_t Suite;

 TryStmt ::= Try1Stmt
  | Try2Stmt;

 Try1Stmt ::= tryKwd_t colon_t Suite Except elseKwd_t colon_t Suite finallyKwd_t colon_t Suite
  | tryKwd_t colon_t Suite Except elseKwd_t colon_t Suite
  | tryKwd_t colon_t Suite Except finallyKwd_t colon_t Suite
  | tryKwd_t colon_t Suite Except
  ;

 Try2Stmt ::= tryKwd_t colon_t Suite finallyKwd_t colon_t Suite;

 Except ::= ExceptOptions Except
  | ExceptOptions;
 
 ExceptOptions ::= exceptKwd_t Expression comma_t Expression colon_t Suite
  | exceptKwd_t Expression colon_t Suite
  | exceptKwd_t colon_t Suite
  ;

 WithStmt ::= withKwd_t Expression asKwd_t Expression colon_t Suite
  | withKwd_t Expression colon_t Suite
  ;


 Classdef ::= classKwd_t Classname Inheritance colon_t Suite
  | classKwd_t Classname colon_t Suite
  ;

 Inheritance ::= openParen_t ExpressionList closeParen_t
  | openParen_t closeParen_t;

 Classname ::= identifier_t;

//////END Compound Statements



///////////Function Definitions


 Funcdef ::= Decorators defKwd_t Funcname openParen_t ParameterList closeParen_t colon_t Suite
  | Decorators defKwd_t Funcname openParen_t closeParen_t colon_t Suite
  | defKwd_t Funcname openParen_t ParameterList closeParen_t colon_t Suite
  | defKwd_t Funcname openParen_t closeParen_t colon_t Suite
  | Decorators defKwd_t Funcname openParen_t ParameterList closeParen_t colon_t longStringFuncDocString_t Suite
  | Decorators defKwd_t Funcname openParen_t closeParen_t colon_t longStringFuncDocString_t Suite
  | defKwd_t Funcname openParen_t ParameterList closeParen_t colon_t longStringFuncDocString_t Suite
  | defKwd_t Funcname openParen_t closeParen_t colon_t longStringFuncDocString_t Suite
  ;

 Decorators ::= SeveralDecorators;
 
 SeveralDecorators ::= Decorator Decorators
  | Decorator;

 Decorator ::=  at_t DottedName openParen_t ArgumentList closeParen_t Newline_t   
  | at_t DottedName openParen_t closeParen_t Newline_t 
  | at_t DottedName Newline_t  
  ;

 DottedName ::= identifier_t DottedNameOptionalPart;

 DottedNameOptionalPart ::=  period_t identifier_t DottedNameOptionalPart
  |;

 Funcname ::= identifier_t;



DefParameters ::= DefParameter comma_t DefParameters
  | Asterisk_t identifier_t comma_t power_t identifier_t
  | Asterisk_t identifier_t
  | power_t identifier_t 
  | DefParameter
  | DefParameter comma_t
  ;

 ParameterList ::= DefParameter comma_t DefParameters
  | DefParameter comma_t
  | DefParameter
  | Asterisk_t identifier_t comma_t power_t identifier_t
  | Asterisk_t identifier_t
  | power_t identifier_t 
  ;


 DefParameter ::= Parameter equals_t Expression
  | Parameter; 

 Parameter ::= identifier_t 
  | openParen_t SubList closeParen_t;


 SubList ::= SubListParameters;

 SubListParameters ::= Parameter comma_t SubListParameters 
  | Parameter comma_t
  | Parameter; 



 

 ArgumentList ::= Expression ArgListAux
  | KeywordArguments
  | ArgumentListOptionalAsteriskExpression
  |  Asterisk_t Expression ArgumentListOptionalPowerExpression
  |  power_t Expression
  ;
 
 ArgListAux ::= comma_t Expression ArgListAux
  |  comma_t identifier_t equals_t Expression DefList
  |  comma_t  Asterisk_t Expression ArgumentListOptionalAsteriskExpression
  |  comma_t power_t Expression
  |  comma_t
  |
  ;
 
 DefList ::= comma_t identifier_t equals_t Expression DefList
  |  comma_t  Asterisk_t Expression ArgumentListOptionalAsteriskExpression
  |  comma_t power_t Expression
  |  comma_t
  |
  ; 
 
 
  
 KeywordArguments ::= KeywordItem DefList;
 
 KeywordItem ::= identifier_t equals_t Expression;


 ArgumentListOptionalAsteriskExpression ::= comma_t Asterisk_t Expression ArgumentListOptionalPowerExpression
  | comma_t power_t Expression
  | comma_t 
  ;
 ArgumentListOptionalPowerExpression  ::= comma_t power_t Expression
  | comma_t  
  |;




///////////////////END Function Definitions



%cf}
