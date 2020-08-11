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
  (bt:with-lock-held (*counter-lock*)
    (incf *scanned-counter*)))
(defun increment-to-scan (change)
  (bt:with-lock-held (*counter-lock*)
    (incf *to-scan-counter* change)))
(defun done? ()
  (bt:with-lock-held (*counter-lock*)
    (= *scanned-counter* *to-scan-counter*)))

(defun iterate-on-pathname (channel function pathname)
  (let ((pathname* (probe-file pathname)))
    (cond
      ((null pathname*)
       (report-error "~a does not exist" pathname)
       (increment-scanned))
      ((null (pathname-name pathname*)) ; This is a directory
       (let ((files (files-in pathname*)))
         (increment-to-scan (length files))
         (dolist (file files)
           (lparallel:submit-task channel
                                  #'iterate-on-pathname
                                  channel function file)))
       (increment-scanned))
      (t                                ; This is a file
       (scan-file function pathname)
       (increment-scanned)))))

(defun compile-regular-expression (regular-expression)
  (one-more-re-nightmare:compile-regular-expression
   regular-expression
   :vector-type 'cffi:foreign-pointer
   :aref-generator (lambda (v p)
                     `(cffi:mem-aref ,v :char ,p))))

(defun scan-pathnames (regular-expression pathnames)
  (let ((channel (lparallel:make-channel))
        (regular-expression (compile-regular-expression
                             (one-more-re-nightmare:string->byte-re
                              regular-expression)))
        (pathnames (alexandria:ensure-list pathnames)))
    (setf *to-scan-counter* (length pathnames)
          *scanned-counter* 0)
    (dolist (pathname pathnames)
      (lparallel:submit-task channel
                             #'iterate-on-pathname
                             channel regular-expression pathname))))
