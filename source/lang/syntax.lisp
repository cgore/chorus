#|
  This file is a part of the Chorus project.
  Copyright (c) 2012-2017 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus/lang/syntax
  (:use :cl
        :chorus/lang/data
        :chorus/lang/type)
  (:export ;; Symbol macro
           :symbol-macro-p
           ;; Macro
           :macro-p
           :macro-operator
           :macro-operands
           ;; Literal
           :literal-p
           :bool-literal-p
           :int-literal-p
           :float-literal-p
           :double-literal-p
           ;; CUDA dimension
           :cuda-dimension-p
           :grid-dim-p
           :block-dim-p
           :block-idx-p
           :thread-idx-p
           :grid-dim-x :grid-dim-y :grid-dim-z
           :block-dim-x :block-dim-y :block-dim-z
           :block-idx-x :block-idx-y :block-idx-z
           :thread-idx-x :thread-idx-y :thread-idx-z
           :cluster-dim-x :cluster-dim-y :cluster-dim-z
           :cluster-idx-x :cluster-idx-y :cluster-idx-z
           :block-in-cluster-x :block-in-cluster-y :block-in-cluster-z
           :cluster-dim-p
           :cluster-idx-p
           :block-in-cluster-p
           ;; Reference
           :reference-p
           ;; Reference - Variable
           :variable-reference-p
           ;; Reference - Structure
           :structure-reference-p
           :structure-reference-accessor
           :structure-reference-expr
           ;; Reference - Array
           :array-reference-p
           :array-reference-expr
           :array-reference-indices
           ;; Inline-if
           :inline-if-p
           :inline-if-test-expression
           :inline-if-then-expression
           :inline-if-else-expression
           ;; Vector constructor
           :constructor-p
           :constructor-operator
           :constructor-operands
           ;; Arithmetic
           :arithmetic-p
           :arithmetic-operator
           :arithmetic-operands
           ;; Function application
           :function-p
           :function-operator
           :function-operands
           ;; If statement
           :if-p
           :if-test-expression
           :if-then-statement
           :if-else-statement
           ;; Let statement
           :let-p
           :let-bindings
           :let-statements
           ;; Let statement - binding
           :let-binding-p
           :let-binding-var
           :let-binding-expr
           ;; Symbol-macrolet statement
           :symbol-macrolet-p
           :symbol-macrolet-bindings
           :symbol-macrolet-statements
           ;; Symbol-macrolet statement - binding
           :symbol-macrolet-binding-p
           :symbol-macrolet-binding-symbol
           :symbol-macrolet-binding-expansion
           ;; Macrolet statement
           :macrolet-p
           :macrolet-bindings
           :macrolet-statements
           ;; Macrolet statement - binding
           :macrolet-binding-p
           :macrolet-binding-symbol
           :macrolet-binding-arguments
           :macrolet-binding-body 
           ;; Do statement
           :do-p
           :do-bindings
           :do-end-test
           :do-statements
           ;; Do statement - binding
           :do-binding-p
           :do-binding-var
           :do-binding-init
           :do-binding-step
           ;; With-shared-memory statement
           :with-shared-memory
           :with-shared-memory-p
           :with-shared-memory-specs
           :with-shared-memory-statements
           ;; With-shared-memory statement - spec
           :with-shared-memory-spec-p
           :with-shared-memory-spec-var
           :with-shared-memory-spec-type
           :with-shared-memory-spec-dimensions
           ;; Set statement
           :set
           :set-p
           :set-reference
           :set-expression
           ;; Progn statement
           :progn-p
           :progn-statements
           ;; Return statement
           :return-p
           :return-expr
           ;; Argument
           :argument
           :argument-p
           :argument-var
           :argument-type
           :argument-restrict-p
           ;; Control and launch
           :while
           :while-p
           :while-test-expression
           :while-statements
           :for
           :for-p
           :for-var
           :for-init
           :for-test
           :for-step
           :for-statements
           :continue
           :continue-p
           :break-p
           :switch
           :switch-p
           :switch-expression
           :switch-clauses
           :printf
           :printf-p
           :cuda-asm
           :cuda-asm-p
           :with-dynamic-shared-memory
           :with-dynamic-shared-memory-p
           :with-dynamic-shared-memory-specs
           :with-dynamic-shared-memory-statements
           :declare-p
           :launch-bounds
           :launch-bounds-values
           :symbol-named-p))
(in-package :chorus/lang/syntax)


(defun symbol-named-p (object name)
  (and (symbolp object)
       (string= (symbol-name object) name)))

(defun operator-named-p (form name)
  (and (consp form)
       (symbol-named-p (car form) name)))


;;;
;;; Symbol macro
;;;

(defun symbol-macro-p (form)
  (chorus-symbol-p form))


;;;
;;; Macro
;;;

(defun macro-p (form)
  (cl-pattern:match form
    ((name . _) (chorus-symbol-p name))
    (_ nil)))

(defun macro-operator (form)
  (unless (macro-p form)
    (error "The value ~S is an invalid form." form))
  (car form))

(defun macro-operands (form)
  (unless (macro-p form)
    (error "The value ~S is an invalid form." form))
  (cdr form))


;;;
;;; Literal
;;;

(defun literal-p (form)
  (or (bool-literal-p form)
      (int-literal-p form)
      (float-literal-p form)
      (double-literal-p form)))

(defun bool-literal-p (form)
  (chorus-bool-p form))

(defun int-literal-p (form)
  (chorus-int-p form))

(defun float-literal-p (form)
  (chorus-float-p form))

(defun double-literal-p (form)
  (chorus-double-p form))


;;;
;;; CUDA dimension
;;;

(defun cuda-dimension-p (form)
  (or (grid-dim-p form)
      (block-dim-p form)
      (block-idx-p form)
      (thread-idx-p form)
      (cluster-dim-p form)
      (cluster-idx-p form)
      (block-in-cluster-p form)))

(defun grid-dim-p (form)
  (and (member form '(grid-dim-x grid-dim-y grid-dim-z))
       t))

(defun block-dim-p (form)
  (and (member form '(block-dim-x block-dim-y block-dim-z))
       t))

(defun block-idx-p (form)
  (and (member form '(block-idx-x block-idx-y block-idx-z))
       t))

(defun thread-idx-p (form)
  (and (member form '(thread-idx-x thread-idx-y thread-idx-z))
       t))

(defun cluster-dim-p (form)
  (and (member form '(cluster-dim-x cluster-dim-y cluster-dim-z))
       t))

(defun cluster-idx-p (form)
  (and (member form '(cluster-idx-x cluster-idx-y cluster-idx-z))
       t))

(defun block-in-cluster-p (form)
  (and (member form '(block-in-cluster-x block-in-cluster-y
                      block-in-cluster-z))
       t))


;;;
;;; Reference
;;;

(defun reference-p (form)
  (or (variable-reference-p form)
      (structure-reference-p form)
      (array-reference-p form)))


;;;
;;; Reference - Variable
;;;

(defun variable-reference-p (form)
  (chorus-symbol-p form))


;;;
;;; Reference - Structure
;;;

(defun structure-reference-p (form)
  (cl-pattern:match form
    ((accessor _) (structure-accessor-p accessor))
    (_ nil)))

(defun structure-reference-accessor (form)
  (unless (structure-reference-p form)
    (error "The form ~S is invalid." form))
  (car form))

(defun structure-reference-expr (form)
  (unless (structure-reference-p form)
    (error "The form ~S is invalid." form))
  (cadr form))


;;;
;;; Reference - Array
;;;

(defun array-reference-p (form)
  (cl-pattern:match form
    (('aref . _) t)
    (_ nil)))

(defun array-reference-expr (form)
  (cl-pattern:match form
    (('aref expr _ . _) expr)
    (('aref . _) (error "The expression ~S is malformed." form))
    (_ (error "The value ~S is an invalid expression." form))))

(defun array-reference-indices (form)
  (cl-pattern:match form
    (('aref _ . indices) (or indices
                             (error "The expression ~S is malformed." form)))
    (('aref) (error "The expression ~S is malformed." form))
    (_ (error "The value ~S is an invalid expression." form))))


;;;
;;; Inline-if
;;;

(defun inline-if-p (form)
  (cl-pattern:match form
    (('if . _) t)
    (_ nil)))

(defun inline-if-test-expression (form)
  (cl-pattern:match form
    (('if test-expr _ _) test-expr)
    (('if . _) (error "The expression ~S is malformed." form))
    (_ (error "The value ~S is an invalid expression." form))))

(defun inline-if-then-expression (form)
  (cl-pattern:match form
    (('if _ then-expr _) then-expr)
    (('if . _) (error "The expression ~S is malformed." form))
    (_ (error "The value ~S is an invalid expression." form))))

(defun inline-if-else-expression (form)
  (cl-pattern:match form
    (('if _ _ else-expr) else-expr)
    (('if . _) (error "The expression ~S is malformed." form))
    (_ (error "The value ~S is an invalid expression." form))))


;;;
;;; Vector constructor
;;;

(defparameter +constructor-operators+
  '(float3 float4 double3 double4 int2 int4 uint2 uint4 half2))

(defun constructor-p (form)
  (cl-pattern:match form
    ((name . _) (and (member name +constructor-operators+)
                     t))
    (_ nil)))

(defun constructor-operator (form)
  (unless (constructor-p form)
    (error "The form ~S is invalid." form))
  (car form))

(defun constructor-operands (form)
  (unless (constructor-p form)
    (error "The form ~S is invalid." form))
  (cdr form))


;;;
;;; Arithmetic
;;;

(defparameter +aritmetic-operators+
  '(+ - * /))

(defun arithmetic-p (form)
  (cl-pattern:match form
    ((name . _) (and (member name +aritmetic-operators+)
                     t))
    (_ nil)))

(defun arithmetic-operator (form)
  (unless (arithmetic-p form)
    (error "The form ~S is invalid." form))
  (car form))

(defun arithmetic-operands (form)
  (unless (arithmetic-p form)
    (error "The form ~S is invalid." form))
  (cdr form))


;;;
;;; Function appication
;;;

(defun function-p (form)
  (cl-pattern:match form
    ((name . _) (chorus-symbol-p name))
    (_ nil)))

(defun function-operator (form)
  (unless (function-p form)
    (error "The form ~S is invalid." form))
  (car form))

(defun function-operands (form)
  (unless (function-p form)
    (error "The form ~S is invalid." form))
  (cdr form))


;;;
;;; If statement
;;;

(defun if-p (form)
  (inline-if-p form))

(defun if-test-expression (form)
  (cl-pattern:match form
    (('if _ _ _ _ . _) (error "The statement ~S is malformed." form))
    (('if test-expr _ . _) test-expr)
    (('if . _) (error "The statement ~S is malformed." form))
    (_ (error "The value ~S is an invalid statement." form))))

(defun if-then-statement (form)
  (cl-pattern:match form
    (('if _ _ _ _ . _) (error "The statement ~S is malformed." form))
    (('if _ then-stmt . _) then-stmt)
    (('if . _) (error "The statement ~S is malformed." form))
    (_ (error "The value ~S is an invalid statement." form))))

(defun if-else-statement (form)
  (cl-pattern:match form
    (('if _ _ _ _ . _) (error "The statement ~S is malformed." form))
    (('if _ _ else-stmt) else-stmt)
    (('if _ _) nil)
    (('if . _) (error "The statement ~S is malformed." form))
    (_ (error "The value ~S is an invalid statement." form))))


;;;
;;; Let statement
;;;

(defun let-p (form)
  (cl-pattern:match form
    (('let . _) t)
    (_ nil)))

(defun let-bindings (form)
  (cl-pattern:match form
    (('let bindings . _)
     (if (every #'let-binding-p bindings)
         bindings
         (error "The statement ~S is malformed." form)))
    (('let . _) (error "The statement ~S is malformed." form))
    (_ (error "The value ~S is an invalid statement." form))))

(defun let-statements (form)
  (cl-pattern:match form
    (('let _ . statements) statements)
    (('let . _) (error "The statement ~S is malformed." form))
    (_ (error "The value ~S is an invalid statement." form))))


;;;
;;; Let statement - binding
;;;

(defun let-binding-p (object)
  (cl-pattern:match object
    ((var _) (chorus-symbol-p var))
    (_ nil)))

(defun let-binding-var (binding)
  (unless (let-binding-p binding)
    (error "The value ~S is an invalid binding." binding))
  (car binding))

(defun let-binding-expr (binding)
  (unless (let-binding-p binding)
    (error "The value ~S is an invalid binding." binding))
  (cadr binding))


;;;
;;; Symbol-macrolet statement
;;;

(defun symbol-macrolet-p (form)
  (cl-pattern:match form
    (('symbol-macrolet . _) t)
    (_ nil)))

(defun symbol-macrolet-bindings (form)
  (cl-pattern:match form
    (('symbol-macrolet bindings . _)
     (if (every #'symbol-macrolet-binding-p bindings)
         bindings
         (error "The statement ~S is malformed." form)))
    (('symbol-macrolet . _) (error "The statement ~S is malformed." form))
    (_ (error "The value ~S is an invalid statement." form))))

(defun symbol-macrolet-statements (form)
  (cl-pattern:match form
    (('symbol-macrolet _ . statements) statements)
    (('symbol-macrolet . _) (error "The statement ~S is malformed." form))
    (_ (error "The value ~S is an invalid statement." form))))


;;;
;;; Symbol-macrolet statement - binding
;;;

(defun symbol-macrolet-binding-p (object)
  (let-binding-p object))

(defun symbol-macrolet-binding-symbol (binding)
  (let-binding-var binding))

(defun symbol-macrolet-binding-expansion (binding)
  (let-binding-expr binding))


;;;
;;; Macrolet statement
;;;

(defun macrolet-p (form)
  (cl-pattern:match form
    (('macrolet . _) t)
    (_ nil)))

(defun macrolet-bindings (form)
  (cl-pattern:match form
    (('macrolet bindings . _)
     (if (every #'macrolet-binding-p bindings)
         bindings
         (error "The statement ~S is malformed." form)))
    (('macrolet . _) (error "The statement ~S is malformed." form))
    (_ (error "The value ~S is an invalid statement." form))))

(defun macrolet-statements (form)
  (cl-pattern:match form
    (('macrolet _ . statements) statements)
    (('macrolet . _) (error "The statement ~S is malformed." form))
    (_ (error "The value ~S is an invalid statement." form))))


;;;
;;; Macrolet statement - binding
;;;

(defun macrolet-binding-p (object)
  (cl-pattern:match object
    ((name bindings . _)
     (and (chorus-symbol-p name)
          (alexandria:proper-list-p bindings)
          (mapcar #'chorus-symbol-p bindings)))
    (_ nil)))

(defun macrolet-binding-symbol (binding)
  (unless (macrolet-binding-p binding)
    (error "The value ~S is an invalid binding." binding))
  (car binding))

(defun macrolet-binding-arguments (binding)
  (unless (macrolet-binding-p binding)
    (error "The value ~S is an invalid binding." binding))
  (cadr binding))

(defun macrolet-binding-body (binding)
  (unless (macrolet-binding-p binding)
    (error "The value ~S is an invalid binding." binding))
  (cddr binding))


;;;
;;; Do statement
;;;

(defun do-p (form)
  (cl-pattern:match form
    (('do . _) t)
    (_ nil)))

(defun do-bindings (form)
  (cl-pattern:match form
    (('do bindings _ . _)
     (if (every #'do-binding-p bindings)
         bindings
         (error "The statement ~S is malformed." form)))
    (('do . _) (error "The statement ~S is malformed." form))
    (_ (error "The value ~S is an invalid statement." form))))

(defun do-end-test (form)
  (cl-pattern:match form
    (('do _ (end-test) . _) end-test)
    (('do . _) (error "The statement ~S is malformed." form))
    (_ (error "The value ~S is an invalid statement." form))))

(defun do-statements (form)
  (cl-pattern:match form
    (('do _ _ . statements) statements)
    (('do . _) (error "The statement ~S is malformed." form))
    (_ (error "The value ~S is an invalid statement." form))))


;;;
;;; Do statement - binding
;;;

(defun do-binding-p (object)
  (cl-pattern:match object
    ((var _) (chorus-symbol-p var))
    ((var _ _) (chorus-symbol-p var))
    (_ nil)))

(defun do-binding-var (binding)
  (unless (do-binding-p binding)
    (error "The value ~S is an invalid binding." binding))
  (car binding))

(defun do-binding-init (binding)
  (unless (do-binding-p binding)
    (error "The value ~S is an invalid binding." binding))
  (cadr binding))

(defun do-binding-step (binding)
  (unless (do-binding-p binding)
    (error "The value ~S is an invalid binding." binding))
  (caddr binding))


;;;
;;; With-shared-memory statement
;;;

(defun with-shared-memory-p (object)
  (cl-pattern:match object
    (('with-shared-memory . _) t)
    (_ nil)))

(defun with-shared-memory-specs (form)
  (cl-pattern:match form
    (('with-shared-memory specs . _)
     (if (every #'with-shared-memory-spec-p specs)
         specs
         (error "The statement ~S is malformed." form)))
    (('with-shared-memory . _)
     (error "The statement ~S is malformed." form))
    (_ (error "The value ~S is an invalid statement." form))))

(defun with-shared-memory-statements (form)
  (cl-pattern:match form
    (('with-shared-memory _ . statements) statements)
    (('with-shared-memory . _)
     (error "The statement ~S is malformed." form))
    (_ (error "The value ~S is an invalid statement." form))))


;;;
;;; With-shared-memory statement - spec
;;;

(defun with-shared-memory-spec-p (object)
  (cl-pattern:match object
    ((var type . _) (and (chorus-symbol-p var)
                         (chorus-type-p type)))
    (_ nil)))

(defun with-shared-memory-spec-var (spec)
  (unless (with-shared-memory-spec-p spec)
    (error "The value ~S is an invalid shared memory spec." spec))
  (car spec))

(defun with-shared-memory-spec-type (spec)
  (unless (with-shared-memory-spec-p spec)
    (error "The value ~S is an invalid shared memory spec." spec))
  (cadr spec))

(defun with-shared-memory-spec-dimensions (spec)
  (unless (with-shared-memory-spec-p spec)
    (error "The value ~S is an invalid shared memory spec." spec))
  (cddr spec))


;;;
;;; Set statement
;;;

(defun set-p (object)
  (cl-pattern:match object
    (('set _ _) t)
    (_ nil)))

(defun set-reference (form)
  (cl-pattern:match form
    (('set reference _) (if (reference-p reference)
                            reference
                            (error "The statement ~S is malformed." form)))
    (('set . _) (error "The statement ~S is malformed." form))
    (_ (error "The value ~S is an invalid statement." form))))

(defun set-expression (form)
  (cl-pattern:match form
    (('set _ expr) expr)
    (('set . _) (error "The statement ~S is malformed." form))
    (_ (error "The value ~S is an invalid statement." form))))


;;;
;;; Progn statement
;;;

(defun progn-p (object)
  (cl-pattern:match object
    (('progn . _) t)
    (_ nil)))

(defun progn-statements (form)
  (cl-pattern:match form
    (('progn . statements) statements)
    (_ (error "The value ~S is an invalid statement." form))))


;;;
;;; Return statement
;;;

(defun return-p (object)
  (cl-pattern:match object
    (('return) t)
    (('return _) t)
    (_ nil)))

(defun return-expr (form)
  (cl-pattern:match form
    (('return) nil)
    (('return expr) expr)
    (('return . _) (error "The statement ~S is malformed." form))
    (_ (error "The value ~S is an invalid statement." form))))


;;;
;;; While statement
;;;

(defun while-p (form)
  (operator-named-p form "WHILE"))

(defun while-test-expression (form)
  (unless (and (while-p form) (cdr form))
    (error "The statement ~S is malformed." form))
  (cadr form))

(defun while-statements (form)
  (unless (while-p form)
    (error "The statement ~S is malformed." form))
  (cddr form))


;;;
;;; For statement
;;;
;;; (for (var init test step) body...)
;;; test is the C continuation test, unlike do's end test.

(defun for-p (form)
  (operator-named-p form "FOR"))

(defun for-binding (form)
  (unless (and (for-p form)
               (consp (cadr form))
               (= (length (cadr form)) 4)
               (chorus-symbol-p (caadr form)))
    (error "The statement ~S is malformed." form))
  (cadr form))

(defun for-var (form)
  (first (for-binding form)))

(defun for-init (form)
  (second (for-binding form)))

(defun for-test (form)
  (third (for-binding form)))

(defun for-step (form)
  (fourth (for-binding form)))

(defun for-statements (form)
  (unless (for-p form)
    (error "The statement ~S is malformed." form))
  (cddr form))


;;;
;;; Break and continue
;;;

(defun break-p (form)
  (and (operator-named-p form "BREAK")
       (null (cdr form))))

(defun continue-p (form)
  (and (operator-named-p form "CONTINUE")
       (null (cdr form))))


;;;
;;; Switch statement
;;;
;;; Each clause is (value body...). T, otherwise, and default are the
;;; default clause. The compiler inserts a break, so clauses do not fall
;;; through.

(defun switch-p (form)
  (operator-named-p form "SWITCH"))

(defun switch-expression (form)
  (unless (and (switch-p form) (cdr form))
    (error "The statement ~S is malformed." form))
  (cadr form))

(defun switch-clauses (form)
  (unless (switch-p form)
    (error "The statement ~S is malformed." form))
  (cddr form))


;;;
;;; Printf and inline PTX
;;;

(defun printf-p (form)
  (and (operator-named-p form "PRINTF")
       (stringp (cadr form))))

(defun cuda-asm-p (form)
  (and (operator-named-p form "CUDA-ASM")
       (stringp (cadr form))
       (null (cddr form))))


;;;
;;; Dynamic shared memory
;;;
;;; Specs are (var element-type). Every spec is a pointer to the same
;;; extern __shared__ base. CUDA aliases those declarations.

(defun dynamic-shared-spec-p (object)
  (and (consp object)
       (null (cddr object))
       (chorus-symbol-p (car object))
       (chorus-type-p (cadr object))))

(defun with-dynamic-shared-memory-p (object)
  (operator-named-p object "WITH-DYNAMIC-SHARED-MEMORY"))

(defun with-dynamic-shared-memory-specs (form)
  (unless (with-dynamic-shared-memory-p form)
    (error "The statement ~S is malformed." form))
  (let ((specs (cadr form)))
    (unless (and (consp specs) (every #'dynamic-shared-spec-p specs))
      (error "The statement ~S is malformed." form))
    specs))

(defun with-dynamic-shared-memory-statements (form)
  (unless (with-dynamic-shared-memory-p form)
    (error "The statement ~S is malformed." form))
  (cddr form))


;;;
;;; Launch bounds
;;;
;;; A leading (declare (launch-bounds n ...)) is stripped from the kernel
;;; body and emitted as __launch_bounds__.

(defun declare-p (form)
  (operator-named-p form "DECLARE"))

(defun launch-bounds-values (body)
  (loop for statement in body
        while (declare-p statement)
        append (loop for clause in (rest statement)
                     when (and (consp clause)
                               (symbol-named-p (car clause) "LAUNCH-BOUNDS"))
                       append (rest clause))))


;;;
;;; Argument
;;;

(deftype argument ()
  `(satisfies argument-p))

(defun argument-p (object)
  (cl-pattern:match object
    ((var type) (and (chorus-symbol-p var)
                     (chorus-type-p type)))
    ((var type restrict)
     (and (chorus-symbol-p var)
          (chorus-type-p type)
          (symbol-named-p restrict "RESTRICT")))
    (_ nil)))

(defun argument-restrict-p (argument)
  (and (argument-p argument)
       (not (null (cddr argument)))))

(defun argument-var (argument)
  (unless (argument-p argument)
    (error "The value ~A is an invalid argument." argument))
  (car argument))

(defun argument-type (argument)
  (unless (argument-p argument)
    (error "The value ~A is an invalid argument." argument))
  (cadr argument))
