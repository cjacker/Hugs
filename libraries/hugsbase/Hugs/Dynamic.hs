module Hugs.Dynamic(module Data.Dynamic, coerceDynamic, runDyn, runDynInt, runDynAddr) where

import Data.Dynamic
import Hugs.Ptr

coerceDynamic :: Typeable a => Dynamic -> a
coerceDynamic d = fromDyn d def
  where def = error ("coerceDynamic: expecting " ++ show (toDyn def) ++
			" found " ++ show d)

runDyn :: Dynamic -> IO ()
runDyn = coerceDynamic

runDynInt :: Dynamic -> IO Int
runDynInt = coerceDynamic

runDynAddr :: Dynamic -> IO (Ptr ())
runDynAddr = coerceDynamic
