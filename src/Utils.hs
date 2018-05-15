{-# LANGUAGE MultiWayIf #-}
module Utils where

import System.Process
import Data.ByteString (ByteString)
import Control.Monad
import Control.Monad.Trans.Except
import Control.Monad.IO.Class
import GitHub.Data.PullRequests
import GitHub.Data.Id
import GitHub.Data.Name
import GitHub hiding (command)
import System.Exit

type Err = String
type GitHubUser = String

data Options =
    Opts { githubToken :: ByteString
         , githubUser  :: GitHubUser
         , ghCommand   :: Command
         }

data Command
        = Fork SimpleRepo
        | Pull Pull

data Pull = PRInfo SimpleRepo (Id PullRequest)
          | PRMirror PullMirror

data PullMirror = PM MirrorOptions SimpleRepo

data SimpleRepo = SimpleRepo (Name Owner) (Name Repo)

data MirrorOptions = MirrorOne (Id PullRequest)
                   | MirrorAllOpen
                   | MirrorAll

safeProcess_ :: MonadIO m => String -> [String] -> String -> (String -> Err) -> ExceptT Err m ()
safeProcess_ c as i k = void (safeProcess c as i k)
safeProcess :: MonadIO m => String -> [String] -> String -> (String -> Err) -> ExceptT Err m (String,String)
safeProcess cmd args stdin errConstr =
  do (code,out,err) <- liftIO $ readProcessWithExitCode cmd args stdin
     if | code == ExitSuccess -> pure (out,err)
        | otherwise ->
            let msg = errConstr $ unlines [ "#####  External Process Failed  #####"
                                          , unwords ( cmd : args )
                                          , "***STDOUT***", out
                                          , "***STDERR***", err  ]
            in throwE msg
