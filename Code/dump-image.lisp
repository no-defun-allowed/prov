(in-package :prov)

(defun startup ()
  (clon:make-context)
  (cond
    ((null (clon:remainder))
     (clon:help))
    (t
     (destructuring-bind (re &rest pathnames)
         (clon:remainder)
       (scan-pathnames re (mapc #'pathname pathnames)))
     (uiop:quit))))

(defun dump (&optional (pathname #p"prov"))
  (clon:dump pathname startup))
