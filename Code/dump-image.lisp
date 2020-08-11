(in-package :prov)

(defun startup ()
  (setf lparallel:*kernel* (lparallel:make-kernel 6))
  (clon:make-context)
  (cond
    ((null (clon:remainder))
     (clon:help))
    (t
     (destructuring-bind (re &rest pathnames)
         (clon:remainder)
       (scan-pathnames re (mapc #'pathname pathnames)))
     (loop until (done?)
           do (sleep 0.0001))
     (uiop:quit))))

(defun dump (&optional (pathname #p"prov"))
  (clon:dump pathname startup))
