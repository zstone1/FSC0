module Parser
import Util.RootUtil
import Interpret.ExprPrim
import Lightyear
import Lightyear.Char
import Lightyear.Strings
%access private
%default partial

rtn : Parser ()
rtn = token "return"

parseIntLit : Parser TermPrim
parseIntLit = [| MkIntLit integer |]

parseStrLit : Parser TermPrim
parseStrLit = [| MkStrLit $ quoted '"' |]

mutual
  parseFuncApp : Parser TermPrim
  parseTerm : Parser TermPrim

  parseFuncApp = do name <- some letter <* spaces
                    args <- between (token "(") (token ")") (parseTerm `sepBy` token ",") 
                    pure $ ApplyFunc (pack name) (fromList args)

  parseTerm =  parseIntLit
           <|> parseStrLit
           <?> "Failed to parse literal"

parseRtn : Parser ExprPrim
parseRtn = rtn *> [| Return parseTerm |]

parseExecTerm : Parser ExprPrim
parseExecTerm = [|ExecTerm parseTerm |] 
         
parseExpr : Parser ExprPrim
parseExpr =  parseRtn
         <|> parseExecTerm 
         <?> "cannot determine expression"

parseBody : Parser (List ExprPrim)
parseBody = parseExpr `sepBy` semi

parsePair : Parser (String, String)
parsePair = do 
  a <- some letter
  token " "
  b <- some letter
  pure (pack a, pack b)


parseFunc : Parser FuncPrim
parseFunc = do 
  access <- some letter <* token " "
  ty <- some letter <* token " "
  name <- some letter <* spaces
  params <- between (token "(") (token ")") (parsePair `sepBy` (token ","))
  defn <- between (token "{") (token "}") parseBody
  let access' = pack access
  let ty' = pack ty
  let name' = pack name
  let params' = fromList params
  pure $ MkFuncPrim access' ty' name' params' defn

parseProgram' : Parser (ProgramPrim)
parseProgram' = do 
  funcs <- (parseFunc `sepBy` endOfLine)
  eof
  pure $ MkProgramPrim funcs

export
total --assert total because strings have finite length.
parseProgram : String -> Comp ProgramPrim
parseProgram s = assert_total $ case parse parseProgram' s of
                                   Left e => raise e
                                   Right p => pure p

