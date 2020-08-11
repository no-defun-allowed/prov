(in-package :prov)

(defun byte-section-to-string (pointer start end)
  (let ((byte-array (make-array (- end start)
                                :element-type '(unsigned-byte 8))))
    (loop for foreign-position from start below end
          for lisp-position from 0
          do (setf (aref byte-array lisp-position)
                   (cffi:mem-aref pointer :char foreign-position)))
    (babel:octets-to-string byte-array)))

(defun scan-file (function pathname)
  (handler-case
      (mmap:with-mmap (pointer fd length pathname)
        (funcall function pointer 0 length
                 (lambda (start end submatches)
                   (declare (ignore submatches))
                   (with-output ()
                     (format t "~&~a: ~a~%"
                             pathname
                             (byte-section-to-string pointer start end))))))
    (mmap:mmap-error ())
    (error (e)
      (report-error "While scanning ~a: ~a" pathname e))))
