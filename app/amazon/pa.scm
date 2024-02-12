;;;
;;; gauche_app_amazon_pa
;;;

(define-module app.amazon.pa
  (use file.util)
  (use rfc.json)
  (use rfc.http)
  (use gauche.record)
  (use app.amazon.auth)
  (export <amazon-pa-api>
          make-amazon-pa-api amazon-pa-api?
          amazon-pa-get-items))
(select-module app.amazon.pa)

(define-record-type <amazon-pa-api> %make-amazon-pa-api amazon-pa-api?
  ;; all slots are private
  %marketplace
  %partner-tag
  %access-key
  %secret-key)      ;thunk to prevent accidentally reveal it

(define (%parse-config config)
  (define (getkey name)
    (or (assq-ref config name)
        (errorf "Value for ~a is missing in config." name)))
  (values (getkey 'marketplace)
          (getkey 'partner-tag)
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
    (receive (marketplace partner-tag access-key secret-key)
        (%parse-config config)
      (%make-amazon-pa-api marketplace partner-tag access-key
                           (^ _ secret-key)))))


(define (%api-signing-key api)
  (aws4-signing-key :access-id (~ api'%access-key)
                    :secret-key ((~ api'%secret-key))
                    :region "us-west-2"
                    :service "ProductAdvertisingAPI"))

;; API
(define (amazon-pa-get-items api item-ids
                             :optional (resources '()))
  (assume-type api <amazon-pa-api>)
  (assume-type item-ids (<List> <string>))
  (assume-type resources (<List> <string>))
  (let* ([json (construct-json-string
                `(("ItemIds" . ,(list->vector item-ids))
                  ("Resources" . ,(list->vector resources))
                  ("PartnerTag" . ,(~ api'%partner-tag))
                  ("PartnerType" . "Associates")
                  ("Marketplace" . ,(~ api'%marketplace))))]
         [body (construct-json-string json)]
         [path "/paapi5/getitems"]
         [headers '(("content-type" "application/json"))])
    (http-post "webservices.amazon.co.jp" path body
               :secure #t
               :headers (aws4-add-auth-headers (%api-signing-key api)
                                               'POST
                                               #"https://webservices.amazon.co.jp/~path"
                                               headers
                                               body))))
