;;;
;;; Test app.amazon.pa
;;;

(use gauche.test)

(test-start "app.amazon.pa")
(use app.amazon.pa)
(test-module 'app.amazon.pa)


;; If you don't want `gosh' to exit with nonzero status even if
;; the test fails, pass #f to :exit-on-failure.
(test-end :exit-on-failure #t)
