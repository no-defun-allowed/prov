(defsystem :prov
  :depends-on (:one-more-re-nightmare :lparallel :mmap :babel
               :net.didierverna.clon)
  :serial t
  :components ((:file "package")
               (:file "command-line")
               (:file "iterator")
               (:file "scan")
               (:file "dump-image")))
