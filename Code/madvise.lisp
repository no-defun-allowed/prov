(in-package :prov)

(cffi:defcenum advice
  (:normal 1)
  (:random 2)
  (:sequential 3)
  (:will-need 4)
  (:dont-need 5))

(cffi:defcfun madvise :void
  (address :pointer) (length :long) (advice advice))
