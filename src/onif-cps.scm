(include "./onif-symbol.scm")

(define-library (onif cps)
   (import (scheme base)
           (scheme cxr)
           (srfi 125) ;SCHEME HASH
           (srfi 1);SCHEME LIST
           (onif symbol))
   (export onif-cps-conv)

   (begin

      (define (%lambda-operator? operator onif-symbol-hash)
        (cond
          ((not (onif-symbol? operator)) #f)
          ((eq? (cadr (hash-table-ref onif-symbol-hash 'lambda))
                operator))
          (else #f)))

      (define (%onif-not-have-continuation? expression onif-symbol-hash)
         (cond
           ((not (list? expression));ATOM(AND NOT NULL)
               (list expression))
           ((null? expression);NULL
               (list '()))
           ((eq? (car expression) 'quote);QUOTE
            (list expression))
           ((%lambda-operator? (car expression) onif-symbol-hash);LAMBDA
            (let ((cps-symbol (onif-symbol)))
              (list
                 (list
                   'lambda
                   (cons cps-symbol (cadr expression))
                  (%cps-conv
                    (car (cddr expression))
                    `((,cps-symbol #f))
                    onif-symbol-hash
                    )))))
           (else
             #f)))

      (define (%onif-conv-frun scm-code stack onif-symbol-hash)
         (let* ((res-top-cell (list #f '()))
                (res-cell res-top-cell))
             (let loop ((code scm-code))
                 (cond
                   ((null? code)
                    (cons
                      (car scm-code)
                      (cons
                        (if (cadar stack)
                          `(lambda (,(caar stack))
                                   ,(%cps-conv (cadar stack) (cdr stack) onif-symbol-hash))
                           (caar stack))
                          (cdr scm-code))))
                   ((%onif-not-have-continuation?
                      (car code)
                      onif-symbol-hash)
                    => (lambda (cont-val)
                          (set-cdr! res-cell (cons (car cont-val) '()))
                          (set! res-cell (cdr res-cell))
                          (loop (cdr code))))
                   (else
                     (let ((new-sym (onif-symbol)))
                       (set-cdr! res-cell (cons new-sym (cdr code)))
                       (%cps-conv
                         (car code)
                         (cons
                           (list new-sym (cdr res-top-cell) )
                           stack)
                         onif-symbol-hash)))))))

      (define (%cps-conv scm-code stack onif-symbol-hash)
        (cond
          ((%onif-not-have-continuation? scm-code onif-symbol-hash)
           => car)
          (else
            (%onif-conv-frun scm-code stack onif-symbol-hash))))

      (define (onif-cps-conv scm-code onif-symbol-hash)
        (%cps-conv scm-code '() onif-symbol-hash))
      ))
