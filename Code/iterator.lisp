(in-package :prov)

(defvar *output-lock* (bt:make-lock "Output lock"))
(defmacro with-output (() &body body)
  `(bt:with-lock-held (*output-lock*)
     ,@body))

(defun report-error (format-control &rest format-args)
  (with-output ()
    (apply #'format *debug-io*
           (concatenate 'string "~&" format-control "~%")
           format-args)))

(defun files-in (directory)
  (directory (merge-pathnames (make-pathname :name :wild
                                             :type :wild)
                              directory)))

(defvar *counter-lock* (bt:make-lock "Counter lock"))
(defvar *scanned-counter* 0)
(defvar *to-scan-counter* 0)
(defun increment-scanned ()
  (incf *scanned-counter*))
(defun increment-to-scan (change)
  (incf *to-scan-counter* change))
(defun done? ()
  (bt:with-lock-held (*counter-lock*)
    (= *scanned-counter* *to-scan-counter*)))

(defun iterate-on-pathname (function pathname)
  (cond
    ((uiop:directory-exists-p pathname)
     (let ((files (files-in pathname)))
       (bt:with-lock-held (*counter-lock*)
         (increment-to-scan (length files))
         (increment-scanned))
       (mapc #'submit-pathname files)))
    ((uiop:file-exists-p pathname)
     (scan-file function pathname)
     (bt:with-lock-held (*counter-lock*)
       (increment-scanned)))
    (t
     (report-error "~a does not exist" pathname)
     (bt:with-lock-held (*counter-lock*)
       (increment-scanned)))))

(defun compile-regular-expression (regular-expression)
  (one-more-re-nightmare:compile-regular-expression
   regular-expression
   :vector-type 'cffi:foreign-pointer
   :aref-generator (lambda (v p)
                     `(cffi:mem-aref ,v :char ,p))))

(defun scan-pathnames (regular-expression pathnames)
  (setf *to-scan-counter* (length pathnames)
        *scanned-counter* 0
        *function* (compile-regular-expression
                    (one-more-re-nightmare:string->byte-re regular-expression)))
  (mapc #'submit-pathname pathnames)
  (dotimes (n *threads*)
    (bt:make-thread #'worker-loop))
  (loop until (done?)
        do (sleep 0.001)))
