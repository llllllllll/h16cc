-- |
-- Module      : Main
-- Copyright   : Joe Jevnik
--
-- License     : GPL-2
-- Maintainer  : joejev@gmail.org
-- Stability   : stable
-- Portability : GHC
--
-- Argument parsing and compilation to bytecode functions.

module Main where

import Assembler.Bytecode
import Assembler.Core
import Assembler.Lexer
import Assembler.Validation

import Control.Monad                  (when,unless,void)
import Data.ByteString                (ByteString)
import qualified Data.ByteString as B (appendFile,writeFile,concat,null
                                      ,singleton,unpack)
import Data.Maybe                     (fromMaybe)
import System.Console.GetOpt          (ArgOrder(..),OptDescr(..)
                                      ,ArgDescr(..),getOpt)
import System.Directory               (doesFileExist,doesDirectoryExist)
import System.Environment             (getArgs)
import System.Exit                    (exitFailure)

-- | Assemble the source file into the output file.
assemble :: FilePath -> FilePath -> IO ()
assemble src out = do
    d <- doesFileExist src
    unless d $ putStrLn ("Cannot find source file '" ++ src ++ "', aborting!")
             >> exitFailure
    srcString <- readFile src
    v <- validateSource src srcString
    unless v exitFailure
    bs <- toByteCode src srcString
    when (B.null bs) exitFailure
    B.writeFile out bs
    B.appendFile out $ B.singleton 0xff -- OP_TERM

-- -----------------------------------------------------------------------------
-- Argument parsing

-- |Parses the command line args.
options :: [OptDescr Flag]
options =
    [ Option "v" ["version"] (NoArg Version) "Displays version information"
    , Option "h" ["help"]    (NoArg Help)    "Prints the help dialog"
    , Option "o" ["output-file"] (ReqArg OutputFile "OUTPUT-FILE")
                 "The output file name"
    ]

-- | Parses a 'FilePath' from the '-o' flag.
parseOutputFilename :: Maybe String -> Flag
parseOutputFilename = OutputFile . fromMaybe ""

-- | Parses the options.
handleOpts :: ([Flag],[String],[String]) -> IO ()
handleOpts ([Help,Version],_,_)       = putStrLn helpString
                                        >> putStrLn versionString
handleOpts ([Version,Help],_,_)       = putStrLn versionString
                                        >> putStrLn helpString
handleOpts ([Help],_,_)               = putStrLn helpString
handleOpts ([Version],_,_)            = putStrLn versionString
handleOpts (_,[],_)                   = putStrLn noArgString
handleOpts ([OutputFile out],ss,_)    = assemble (head ss) out
handleOpts ([],ss,_)                  = assemble(head ss) "a.out"

-- | The help message.
helpString :: String
helpString =
    "Usage:\n\n    h16cc [OPTION] SOURCE\n\nWhere SOURCE is the .16c \
    \source file you wish to assemble to the file: 'a.out'.\nThe 16candles \
    \assembler accecpts the following additional arguments:\n\
    \\n    -o OUTPUT-FILE   The file to name the output binary.\
    \\n    -v --version     Print version information about the this \
    \assembler.\n    -h --help        Prints this message.\n"

-- | The version message.
versionString :: String
versionString =
    "The Haskell 16candles assembler: version 0.2.0.1 (2016.01.11)\n\
    \Copyright (C) 2014 Joe Jevnik.\n\
    \This is free software; see the source for copying \
    \conditions.  There is NO\nwarranty; not even for MERCHANTABILITY\
    \ or FITNESS FOR A PARTICULAR PURPOSE."

-- | The message to display when no arguments are passed.
noArgString :: String
noArgString =
    "h16cc: no input files\nUsage: h16cc [h --help|v --version|o OUTPUT-FILE] \
    \SOURCE"

-- | Grabs the args, parses them and operates on it.
main :: IO ()
main = getArgs >>= handleOpts . getOpt Permute options
