(asdf:defsystem :prov
  :depends-on (:one-more-re-nightmare :safe-queue :bordeaux-threads
               :mmap :babel :net.didierverna.clon)
  :serial t
  :components ((:file "package")
               (:file "command-line")
               (:file "iterator")
               (:file "thread-pool")
               (:file "scan")
               #+linux (:file "madvise")
               (:file "dump-image")))
