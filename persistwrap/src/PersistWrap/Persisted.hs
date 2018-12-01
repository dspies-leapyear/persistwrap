{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -Wno-redundant-constraints #-}

module PersistWrap.Persisted
    ( MapsTo
    , Persisted
    , deleteX
    , getX
    , getXs
    , insertX
    , modifyX
    , stateX
    ) where

import Data.Promotion.Prelude (type (==))
import GHC.TypeLits (KnownSymbol, Symbol)

import PersistWrap.Itemized
import PersistWrap.Persistable (Persistable)
import qualified PersistWrap.Persistable as E
import PersistWrap.Structure (EntityPart)
import PersistWrap.Table (ForeignKey)

class Persistable schemaName x m => Persisted schemaName x m | schemaName m -> x

getXs :: Persisted schemaName x m => m [(ForeignKey m schemaName, x)]
getXs = E.getXs
getX :: Persisted schemaName x m => ForeignKey m schemaName -> m (Maybe x)
getX = E.getX
insertX :: Persisted schemaName x m => x -> m (ForeignKey m schemaName)
insertX = E.insertX
deleteX :: forall schemaName x m . Persisted schemaName x m => ForeignKey m schemaName -> m Bool
deleteX = E.deleteX @_ @x
stateX :: Persisted schemaName x m => ForeignKey m schemaName -> (x -> (b, x)) -> m (Maybe b)
stateX = E.stateX
modifyX :: Persisted schemaName x m => ForeignKey m schemaName -> (x -> x) -> m Bool
modifyX = E.modifyX

instance
  ( EntityPart (ForeignKey m) x
  , Persistable schemaName x m
  , KnownSymbol schemaName
  , MapsTo schemaName x items
  ) => Persisted schemaName x (Itemized items m)

class MapsTo (schemaName :: Symbol) x (items :: [(Symbol, *)]) | schemaName items -> x
instance MapsToH (schemaName == headName) schemaName x ('(headName, headX) ': rest)
  => MapsTo schemaName x ('(headName, headX) ': rest)
class MapsToH (current :: Bool) (schemaName :: Symbol) x (items :: [(Symbol, *)])
  | schemaName items -> x
instance MapsTo schemaName x rest => MapsToH 'False schemaName x (head ': rest)
instance x ~ headX => MapsToH 'True schemaName x ('(headName, headX) ': rest)
