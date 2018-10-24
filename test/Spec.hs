{-# LANGUAGE TemplateHaskell #-}

import Conkin (Tuple (..))
import Control.Monad (forM_)
import Control.Monad.State (execStateT)
import qualified Control.Monad.State as State
import qualified Data.Aeson as JSON
import Data.List (find)
import Test.Hspec

import PersistWrap.Conkin.Extra.Tuple.TH (tuple)
import qualified PersistWrap.Table.BackEnd.TVar as BackEnd
import PersistWrap.Table.Class
import PersistWrap.Table.TH

newtype NoShow a = NoShow a
  deriving (Eq)
instance Show (NoShow a) where
  show = const "<no show instance>"

removeInd :: Int -> [a] -> [a]
removeInd i xs = take i xs ++ drop (i + 1) xs

sameElements :: forall a . Eq a => [a] -> [a] -> Bool
sameElements xs ys = maybe False null $ (`execStateT` ys) $ forM_ xs $ \x -> do
  ys'    <- State.get
  (i, _) <- State.lift $ find ((== x) . snd) (zip [0 ..] ys')
  State.put $ removeInd i ys'

shouldBeNSIgnoreOrder :: (HasCallStack, Eq a) => [a] -> [a] -> Expectation
shouldBeNSIgnoreOrder x y = (map NoShow x, map NoShow y) `shouldSatisfy` uncurry sameElements

main :: IO ()
main = hspec $ describe "Tables" $ it "should do row operations" $ do
  assertions :: Expectation <- BackEnd.withEmptyTableProxies $(tuple [|
        [ $(schema "tab1" ["abc" ::: Nullable Int64])
        , $(schema "tab2" [])
        , $(schema "tab3" ["hello" ::: Bool, "world" ::: JSON])
        , $(schema "connection" ["key1" ::: Key "tab1", "key3" ::: Nullable (Key "tab3")])
        ]
      |])
    $ \(STP t1 `Cons` STP t2 `Cons` STP t3 `Cons` STP t4 `Cons` Nil) -> do
        (fk1, fk3, assertions) <- atomicTransaction $ do
          k1 <- insertRow t1 $(row [| [10] |])
          let fk1 = keyToForeign k1
          _ <- insertRow t1 $(row [| [null] |])
          k2 <- insertRow t2 Nil
          _ <- insertRow t2 $(row [| [] |])
          deleted1 <- deleteRow k2
          deleted2 <- deleteRow k2
          let assertion1 = do
                deleted1 `shouldBe` True
                deleted2 `shouldBe` False
          k3 <- insertRow t3 $(row [| [False, JSON.String "jsontext"] |])
          _ <- insertRow t3 $(row [| [True, JSON.String "anotherstring"] |])
          let fk3 = keyToForeign k3
          conk <- insertRow t4 $(row [| [fk1, null] |])
          _ <- insertRow t4 $(row [| [fk1, null] |])
          modified <- modifyRow conk $ const $(row [| [fk1, fk3] |])
          let assertion2 = modified `shouldBe` True
          return (fk1, fk3, assertion1 >> assertion2)
        (t1Rows, t2Rows, t3Rows, t3False, t4Rows) <- atomicTransaction $ do
          t1Rows <- getAllEntities t1
          t2Rows <- getAllEntities t2
          t3Rows <- getAllEntities t3
          t3False <- getEntities t3 $(matcher [| [False, any] |])
          t4Rows <- getAllEntities t4
          return
            ( map entityVal t1Rows
            , map entityVal t2Rows
            , map entityVal t3Rows
            , map entityVal t3False
            , map entityVal t4Rows
            )
        return $ do
          assertions
          t1Rows `shouldBeNSIgnoreOrder` [$(row [| [10] |]), $(row [| [null] |])]
          t2Rows `shouldBeNSIgnoreOrder` [Nil]
          t3Rows `shouldBeNSIgnoreOrder`
            [ $(row [| [False, JSON.String "jsontext"] |])
            , $(row [| [True, JSON.String "anotherstring"] |])
            ]
          t3False `shouldBeNSIgnoreOrder` [$(row [| [False, JSON.String "jsontext"] |])]
          t4Rows `shouldBeNSIgnoreOrder` [$(row [| [fk1, fk3] |]), $(row [| [fk1, null] |])]
  assertions
