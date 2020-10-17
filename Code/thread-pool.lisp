(in-package :prov)

(defvar *threads* 12)
(defvar *mailbox* (safe-queue:make-mailbox))
(defvar *function*)

(defun submit-pathname (pathname)
  (safe-queue:mailbox-send-message *mailbox* pathname))

(defun worker-loop ()
  (let ((mailbox *mailbox*)
        (function *function*))
    (loop until (done?)
          do (let ((pathname (safe-queue:mailbox-receive-message mailbox :timeout 0.1)))
               (unless (null pathname)
                 (iterate-on-pathname function pathname))))
    (finish-output)))
