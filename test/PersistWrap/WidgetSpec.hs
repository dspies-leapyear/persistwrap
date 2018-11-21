{-# LANGUAGE TemplateHaskell #-}

module PersistWrap.WidgetSpec
    ( spec
    ) where

import Control.Monad (join)
import qualified Data.ByteString.Char8 as BS
import Test.Hspec

import PersistWrap.Embedding.Class.Embedded
import PersistWrap.Table (MonadDML, atomicTransaction)
import PersistWrap.Table.BackEnd.Helper
import PersistWrap.Table.BackEnd.TH (declareTables)
import qualified PersistWrap.Table.BackEnd.TVar as BackEnd

import PersistWrap.SpecUtil.Widget

-- | We're declaring a new table context which called \"TestTables\".
$(declareTables "TestTables")
-- |
-- \"TestTables\" has two primary tables in it: \"abc\" and \"widget\". \"abc\" stores `Int`s and
-- \"widget\" stores `Widget`s.
type instance Items (TestTables fk) = '[ '("abc", Int), '("widget", Widget fk)]

spec :: Spec
spec =
  describe "Widget"
    $ it "should get back what you put in"
    $ join
    -- Initializes empty tables in `STM` backend.
    $ BackEnd.withEmptyTablesItemized @TestTables widgetTest

widgetTest :: (MonadDML m, ForeignKeysShowable m) => Itemized (ItemsIn TestTables m) m Expectation
widgetTest = atomicTransaction $ do
  -- The compiler knows 3 is an `Int` because we're inserting it into the \"abc\" table.
  -- @ fk3 :: FK m "abc" @
  fk3 <- insertX @"abc" 3
  let
    -- Similarly we don't need to explicitly specify the type-parameter for w1, w2, and w3.
    w1 = Blarg (False, True, BS.pack "hello world")
    w2 = Glorp fk3
    w3 = Foo2
      [Foo { bar = 10, baz = A 3 4, qux = Just Green }, Foo { bar = 11, baz = B, qux = Nothing }]
  fkw1      <- insertX @"widget" w1
  fkw2      <- insertX @"widget" w2
  fkw3      <- insertX @"widget" w3
  resultABC <- getX fk3
  result1   <- getX fkw1
  result2   <- getX fkw2
  result3   <- getX fkw3
  return $ do
    resultABC `shouldBe` Just 3
    result1 `shouldBe` Just w1
    result2 `shouldBe` Just w2
    result3 `shouldBe` Just w3
