{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveGeneric #-}

module PingPong
  (      pingPongMain
  ) where

import Network.Transport.TCP (createTransport, defaultTCPParameters)
import Control.Monad (forever)
import Control.Distributed.Process
import Control.Distributed.Process.Node
import Data.Binary
import Data.Typeable
import GHC.Generics

{-|
ping pong implemented with dedicated Messages
-}

data Protocol = Ping ProcessId
             | Pong ProcessId
             | Done
  deriving (Typeable, Generic, Show)

instance Binary Protocol

ping :: Process ()
ping = do
  pingPid <- getSelfPid
  pongPid <- spawnLocal pong
  forever $ do
      _ <- send pongPid (Ping pingPid)
      _ <- liftIO $ putStrLn "ping sent"
      Pong pid <- expect
      liftIO $ putStrLn "pong received"
  
pong :: Process ()
pong = forever $ do
  myPid <- getSelfPid
  Ping pid <- expect
  _ <- liftIO $ putStrLn "ping received"
  send pid (Pong myPid)
  liftIO $ putStrLn "pong sent"

pingPongMain :: IO ()
pingPongMain = do
  Right t <- createTransport "127.0.0.1" "10501" defaultTCPParameters
  node <- newLocalNode t initRemoteTable
  runProcess node ping
