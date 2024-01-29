;;;
;;; gauche_app_amazon_pa
;;;

(define-module app.amazon.pa
  (use file.util)
  (use rfc.http)
  (use gauche.record)
  (export <amazon-pa-api>
          make-amazon-pa-api amazon-pa-api?))
(select-module app.amazon.pa)

(define-record-type <amazon-pa-api> %make-amazon-pa-api amazon-pa-api?
  ;; all slots are private
  %partner-tag
  %access-key
  %secret-key)                          ;thunk

(define (%parse-config config)
  (define (getkey name)
    (or (assq-ref config name)
        (errorf "Value for ~a is missing in config." name)))
  (values (getkey 'partner-tag)
          (getkey 'access-key)
          (getkey 'secret-key)))

;; API
(define (make-amazon-pa-api :optional (config #f))
  (let1 config
      (or config
          (with-input-from-file (expand-path "~/.gauche-amazon-pa-api.scm")
            read
            :if-does-not-exist #f)
          (error "No configuration provided.  Give an alist to make-amazon-pa-api, \
                  or save it in ~/.gauche-amazon-pa-api.scm."))
    (receive (partner-tag access-key secret-key) (%parse-config config)
      (%make-amazon-pa-api partner-tag access-key
                           (^ _ secret-key)))))
