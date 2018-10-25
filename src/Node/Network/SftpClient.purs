module Node.Network.SftpClient where

import Control.Alt (class Alt)
import Control.Applicative (class Applicative, pure)
import Control.Apply (class Apply, (*>))
import Control.Bind (class Bind, (=<<))
import Control.Category ((<<<))
import Control.Monad (class Monad)
import Control.Monad.Error.Class (class MonadError, class MonadThrow)
import Control.Monad.Reader (ReaderT, ask, lift, runReaderT)
import Control.Monad.Rec.Class (class MonadRec)
import Control.MonadPlus (class Plus)
import Data.Function (($))
import Data.Functor (class Functor)
import Data.Monoid (class Monoid)
import Data.Semigroup (class Semigroup)
import Data.Unit (Unit, unit)
import Effect.Aff (Aff, Error, bracket)
import Effect.Aff.Class (class MonadAff)
import Effect.Aff.Compat (EffectFnAff, fromEffectFnAff)
import Effect.Class (class MonadEffect)
import Node.Network.SftpClient.Internal (Config, SftpClientRef, FileInfo)
import Node.Network.SftpClient.Internal as Internal

newtype SftpSessionM a = SftpSessionM (ReaderT SftpClientRef Aff a)

derive newtype instance functorSftpSessionM ∷ Functor SftpSessionM
derive newtype instance applySftpSessionM ∷ Apply SftpSessionM
derive newtype instance applicativeSftpSessionM ∷ Applicative SftpSessionM
derive newtype instance bindSftpSessionM ∷ Bind SftpSessionM
derive newtype instance monadSftpSessionM ∷ Monad SftpSessionM
derive newtype instance semigroupSftpSessionM ∷ Semigroup a ⇒ Semigroup (SftpSessionM a)
derive newtype instance monoidSftpSessionM ∷ Monoid a ⇒ Monoid (SftpSessionM a)
derive newtype instance altSftpSessionM ∷ Alt SftpSessionM
derive newtype instance plusSftpSessionM ∷ Plus SftpSessionM
derive newtype instance monadEffectSftpSessionM ∷ MonadEffect SftpSessionM
derive newtype instance monadRecSftpSessionM ∷ MonadRec SftpSessionM
derive newtype instance monadAffSftpSessionM ∷ MonadAff SftpSessionM
derive newtype instance monadErrorSftpSessionM ∷ MonadError Error SftpSessionM
derive newtype instance monadThrowSftpSessionM ∷ MonadThrow Error SftpSessionM

unsafeFromRefFnAff ∷ ∀ a. (SftpClientRef → EffectFnAff a) → SftpSessionM a
unsafeFromRefFnAff affFn = SftpSessionM $ lift <<< fromEffectFnAff <<< affFn =<< ask

runSftpSession ∷ ∀ a. Config → SftpSessionM a → Aff a
runSftpSession config (SftpSessionM connectedSession) = bracket
  -- acquire resources
  (acquireConnection config)
  -- release resources
  releaseConnection
  -- run session
  (runReaderT connectedSession)

  where
    acquireConnection cfg =
      let ref = Internal.unsafeCreateNewClient unit
      in fromEffectFnAff (Internal.connect cfg ref) *> pure ref

    releaseConnection ref = fromEffectFnAff (Internal.end ref)

list ∷ String → SftpSessionM (Array FileInfo)
list = unsafeFromRefFnAff <<< Internal.list

rmdir ∷ { path ∷ String, recursive ∷ Boolean} → SftpSessionM Unit
rmdir = unsafeFromRefFnAff <<< Internal.rmdir

mkdir ∷ { path ∷ String, recursive ∷ Boolean}  → SftpSessionM Unit
mkdir = unsafeFromRefFnAff <<< Internal.mkdir

rename ∷ {from ∷ String, to ∷ String } → SftpSessionM Unit
rename = unsafeFromRefFnAff <<< Internal.rename

delete ∷ String → SftpSessionM Unit
delete = unsafeFromRefFnAff <<< Internal.delete

chmod ∷ {dest ∷ String, mode ∷ String } → SftpSessionM Unit
chmod = unsafeFromRefFnAff <<< Internal.chmod

fastGet ∷ {remote ∷ String, local ∷ String } → SftpSessionM Unit
fastGet = unsafeFromRefFnAff <<< Internal.fastGet

fastPut ∷ {remote ∷ String, local ∷ String } → SftpSessionM Unit
fastPut = unsafeFromRefFnAff <<< Internal.fastPut
