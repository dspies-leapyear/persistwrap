{-# LANGUAGE AllowAmbiguousTypes #-}

module Conkin.Extra.Tuple where

import Prelude hiding (unzip)

import Conkin (Tuple(..))
import Data.Function.Pointless ((.:))
import Data.Functor.Compose (Compose(Compose), getCompose)
import Data.List.NonEmpty (NonEmpty(..))
import GHC.Generics ((:*:)((:*:)))

import Conkin.Extra.Traversal (mapUncheck)

mapUncheckNonEmpty :: forall a x xs y . (forall x' . a x' -> y) -> Tuple (x ': xs) a -> NonEmpty y
mapUncheckNonEmpty fn (x0 `Cons` xs0) = fn x0 :| mapUncheck fn xs0

zipUncheck :: forall a b xs y . (forall x . a x -> b x -> y) -> Tuple xs a -> Tuple xs b -> [y]
zipUncheck fn = go
  where
    go :: forall xs' . Tuple xs' a -> Tuple xs' b -> [y]
    go Nil           Nil           = []
    go (x `Cons` xs) (y `Cons` ys) = fn x y : go xs ys

-- Returns Nothing if lengths don't match
zipWithUncheckedM
  :: forall f a xs y b
   . Applicative f
  => (forall x . a x -> y -> f (b x))
  -> Tuple xs a
  -> [y]
  -> f (Maybe (Tuple xs b))
zipWithUncheckedM fn = getCompose .: go
  where
    go :: forall xs' . Tuple xs' a -> [y] -> Compose f Maybe (Tuple xs' b)
    go Nil           []       = pure Nil
    go (x `Cons` xs) (y : ys) = Cons <$> Compose (Just <$> fn x y) <*> go xs ys
    go _             _        = Compose $ pure Nothing

tail :: Tuple (x ': xs) f -> Tuple xs f
tail (_ `Cons` xs) = xs

unzip :: Tuple xs (f :*: g) -> (Tuple xs f, Tuple xs g)
unzip = \case
  Nil                  -> (Nil, Nil)
  (x :*: y `Cons` xys) -> let (xs, ys) = unzip xys in (x `Cons` xs, y `Cons` ys)
