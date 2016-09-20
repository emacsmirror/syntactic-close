;; general-close-modes.el --- mode-specific functions -*- lexical-binding: t; -*-

;; Authored and maintained by
;; Emacs User Group Berlin <emacs-berlin@emacs-berlin.org>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:

(defvar general-close-python-keywords "\\<\\(ArithmeticError\\|AssertionError\\|AttributeError\\|BaseException\\|BufferError\\|BytesWarning\\|DeprecationWarning\\|EOFError\\|Ellipsis\\|EnvironmentError\\|Exception\\|False\\|FloatingPointError\\|FutureWarning\\|GeneratorExit\\|IOError\\|ImportError\\|ImportWarning\\|IndentationError\\|IndexError\\|KeyError\\|KeyboardInterrupt\\|LookupError\\|MemoryError\\|NameError\\|NoneNotImplementedError\\|NotImplemented\\|OSError\\|OverflowError\\|PendingDeprecationWarning\\|ReferenceError\\|RuntimeError\\|RuntimeWarning\\|StandardError\\|StopIteration\\|SyntaxError\\|SyntaxWarning\\|SystemError\\|SystemExit\\|TabError\\|True\\|TypeError\\|UnboundLocalError\\|UnicodeDecodeError\\|UnicodeEncodeError\\|UnicodeError\\|UnicodeTranslateError\\|UnicodeWarning\\|UserWarning\\|ValueError\\|Warning\\|ZeroDivisionError\\|__debug__\\|__import__\\|__name__\\|abs\\|all\\|and\\|any\\|apply\\|as\\|assert\\|basestring\\|bin\\|bool\\|break\\|buffer\\|bytearray\\|callable\\|chr\\|class\\|classmethod\\|cmp\\|coerce\\|compile\\|complex\\|continue\\|copyright\\|credits\\|def\\|del\\|delattr\\|dict\\|dir\\|divmod\\|elif\\|else\\|enumerate\\|eval\\|except\\|exec\\|execfile\\|exit\\|file\\|filter\\|float\\|for\\|format\\|from\\|getattr\\|global\\|globals\\|hasattr\\|hash\\|help\\|hex\\|id\\|if\\|import\\|in\\|input\\|int\\|intern\\|is\\|isinstance\\|issubclass\\|iter\\|lambda\\|len\\|license\\|list\\|locals\\|long\\|map\\|max\\|memoryview\\|min\\|next\\|not\\|object\\|oct\\|open\\|or\\|ord\\|pass\\|pow\\|print\\|property\\|quit\\|raise\\|range\\|raw_input\\|reduce\\|reload\\|repr\\|return\\|round\\|set\\|setattr\\|slice\\|sorted\\|staticmethod\\|str\\|sum\\|super\\|tuple\\|type\\|unichr\\|unicode\\|vars\\|while\\|with\\|xrange\\|yield\\|zip\\|\\)\\>"
  "Contents like py-font-lock-keyword")

(require 'sgml-mode)
(require 'comint)

(defvar general-close-comint-haskell-pre-right-arrow-re   "let [alpha][A-Za-z0-9_]+ +::")
;; (setq general-close-comint-haskell-pre-right-arrow-re   "let [alpha][A-Za-z0-9_]+ +::")
(defcustom general-close-comint-haskell-pre-right-arrow-re
  "let [alpha][A-Za-z0-9_]+ +::"
  "Insert \"=\" when looking back. "
  :type 'string
  :tag "general-close-comint-haskell-pre-right-arrow-re"
  :group 'general-close)

;; Ml
(defun general-close-ml ()
  (interactive "*")
  (let ((oldmode major-mode) done)
    (cond ((save-excursion
	     (and (< 0 (abs (skip-syntax-backward "w")))
		  (not (bobp))
		  ;; (syntax-after (1- (point)))
		  (or (eq ?< (char-before (point)))
		      (and (eq ?< (char-before (1- (point))))
			   (eq ?/ (char-before (point)))))))
	   (insert ">")
	   (setq done t))
	  (t (when (eq ?> (char-before (point)))(newline))
	     (sgml-mode)
	     (sgml-close-tag)
	     (funcall oldmode)
	     (font-lock-fontify-buffer)
	     (setq done t)))
    done))

(defun general-close-python-listclose (closer force pps)
  "If inside list, assume another item first. "
  (let (done)
    (cond ((and force (eq (char-before) general-close-list-separator-char))
	   (delete-char -1)
	   (insert closer)
	   (setq done t))
	  ((member (char-before) (list ?' ?\"))
	   (if force
	       (progn
		 (insert closer)
		 ;; only closing `"' or `'' was inserted here
		 (when (setq closer (general-close--fetch-delimiter-maybe (parse-partial-sexp (point-min) (point))) force)
		   (insert closer))
		 (setq done t))
	     (if (nth 3 pps)
		 (insert (char-before))
	       (insert ","))
	     (unless general-close-electric-listify-p
	       (setq done t))))
	  ((eq (char-before) general-close-list-separator-char)
	   (if general-close-electric-listify-p
	       (progn
		 (save-excursion
		   (forward-char -1)
		   (setq closer (char-before)))
		 (insert closer))
	     (delete-char -1)
	     (insert closer))
	   (setq done t))
	  (t (insert closer)
	     (setq done t)))
    done))

;; Emacs-lisp
(defun general-close-emacs-lisp-close (closer pps force)
  (let ((closer (or closer (general-close--fetch-delimiter-maybe pps force)))
	done)
    (cond
     ((and (eq 1 (nth 1 pps))
	   (save-excursion
	     (beginning-of-line)
	     (looking-at general-close-emacs-lisp-function-re)))
      (general-close-insert-with-padding-maybe "()" nil t)
      (setq done t))
     ((save-excursion
	(skip-chars-backward " \t\r\n\f")
	(looking-back general-close-emacs-lisp-block-re (line-beginning-position)))
      (general-close-insert-with-padding-maybe (char-to-string 40)))
     (t (insert closer)
	(setq done t)))
    done))

;; See also general-close--fetch-delimiter-maybe - redundancy?
(defun general-close--guess-symbol (&optional pos)
  (save-excursion
    (let ((erg (when pos
		 (progn (goto-char pos)
			(char-after)))))
      (unless erg
	(setq erg
	      (save-excursion
		(progn
		  (forward-char -1)
		  (buffer-substring-no-properties (point) (progn (skip-chars-backward "[[:alnum:]]") (point)))))))
      (when (string= "" erg)
	(setq erg (cond ((member (char-before (1- (point))) (list ?' ?\"))
			 (char-before (1- (point)))))))
      (unless
	  (or (characterp erg)(< 1 (length erg)))(string= "" erg)
	(setq erg (string-to-char erg)))
      erg)))

(defun general-close--raise-symbol-maybe (symbol)
  "Return the symbol following in asci decimal-values.

If at char `z', follow up with `a'
If arg SYMBOL is a string, return it unchanged"
  (if (stringp symbol)
      symbol
    (cond
     ((eq 122 symbol)
      ;; if at char `z', follow up with `a'
      97)
     ((eq symbol 90)
      65)
     ((and (< symbol 123)(< 96 symbol))
      (1+ symbol))
     ((and (< symbol 133)(< 64 symbol))
      (1+ symbol))
     ;; raise until number 9
     ((and (< 47 symbol)(< symbol 57))
      (1+ symbol))
     (t symbol))))

(defun general-close-python-electric-close (pps closer force)
  (let (done)
    (cond
     ((and closer (eq 2 (nth 0 pps))
	   (eq 1 (car (syntax-after (1- (point))))))
      (insert (general-close--guess-symbol))
      (setq done t))
     ((and closer (eq 2 (nth 0 pps)))
      (when (eq 2 (car (syntax-after (1- (point)))))
	(insert general-close-list-separator-char)
	(setq done t)))
     ;; simple lists
     ((eq 1 (car (syntax-after (1- (point)))))
      ;; translate a single char into its successor
      ;; if multi-char symbol, repeat
      (insert (general-close--raise-symbol-maybe (general-close--guess-symbol)))
      (setq done t))
     ((and closer
	   (eq 1 (nth 0 pps)) (not (nth 3 pps))
	   (not (eq (char-before) general-close-list-separator-char)))
      (insert general-close-list-separator-char)
      (setq done t)
      (when force
	(general-close-python-close closer pps force)))
     ((and closer
	   (not (eq (char-before) closer)))
      (insert closer)
      (setq done t)
      (when force
	(general-close-python-close nil nil force nil t)))
     (closer
      (setq done (general-close--electric pps closer force))
      (unless (eq (char-before) general-close-list-separator-char)
	(general-close-python-close closer pps force))))
    done))

;; Python
(defun general-close-python-close (&optional closer pps force delimiter done b-of-st b-of-bl)
  "Might deliver equivalent to `py-dedent'"
  (interactive "*")
  (let* ((closer (or closer
		     (general-close--fetch-delimiter-maybe (or pps (parse-partial-sexp (point-min) (point))) force)))
	 (pps (parse-partial-sexp (point-min) (point)))
	 ;; (delimiter (or delimiter (general-close-fetch-delimiter pps)))
	 (general-close-beginning-of-statement
	  (or b-of-st
	      (if (ignore-errors (functionp 'py-backward-statement))
		  'py-backward-statement
		(lambda ()(beginning-of-line)(back-to-indentation)))))
	 (general-close-beginning-of-block-re (or b-of-bl "[ 	]*\\_<\\(class\\|def\\|async def\\|async for\\|for\\|if\\|try\\|while\\|with\\|async with\\)\\_>[:( \n	]*"))
	 done)
    (when force (setq general-close-electric-listify-p nil))
    (cond
     ;; nested lists,
     ;; Inside a list-comprehension
     (general-close-electric-listify-p
      (setq done (general-close-python-electric-close pps closer force)))
     (closer
      (setq done (general-close-python-listclose closer force pps)))
     ((and (not (char-equal ?: (char-before)))
	   (save-excursion
	     (funcall general-close-beginning-of-statement)
	     (looking-at general-close-beginning-of-block-re)))
      (insert ":")
      (setq done t))
     (t (eolp)
	(ignore-errors (newline-and-indent))
	(setq done t)))
    done))

;; Ruby
(defun general-close--generic-fetch-delimiter-maybe ()
  (save-excursion
    (and (< 0 (abs (skip-syntax-backward "\\sw")))
	 (or
	  (eq 1 (car (syntax-after (1- (point)))))
	  (eq 7 (car (syntax-after (1- (point))))))
	 (char-to-string (char-before)))))

(defun general-close--ruby-insert-end ()
  (let (done)
    (unless (or (looking-back ";[ \t]*" nil))
      (unless (and (bolp)(eolp))
	(newline))
      (unless (looking-back "^[^ \t]*\\_<end" nil)
	(insert "end")
	(setq done t)
	(save-excursion
	  (back-to-indentation)
	  (indent-according-to-mode))))
    done))

(defun general-close-ruby-close (&optional closer pps)
  (let ((closer (or closer
		    (and pps (general-close--fetch-delimiter-maybe pps))
		    (general-close--generic-fetch-delimiter-maybe)))
	done)
    (if closer
	(progn
	  (insert closer)
	  (setq done t))
      (setq done (general-close--ruby-insert-end))
      done)))

(defun general-close--insert-string-concat-op-maybe ()
  (let (done)
    (save-excursion
      (skip-chars-backward " \t\r\n\f")
      (and (or (eq (char-before) ?') (eq (char-before) ?\"))
	   (progn
	     (forward-char -1)
	     (setq done (nth 3 (parse-partial-sexp (point-min) (point)))))))
    (when done
      (fixup-whitespace)
      (if (eq (char-before) ?\ )
	  (insert "++ ")
	(insert " ++ ")))
    done))

(defun general-closer-forward-sexp-maybe (pos)
  (ignore-errors (forward-sexp))
  (when (< pos (point))(point)))

(defun general-closer-uniq-varlist (&optional beg end pps)
  "Return a list of variables existing in buffer-substring. "
  (save-excursion
    (let* (sorted
	   (pos (point))
	   (beg (or beg (ignore-errors (nth 1 pps))
		    (or (nth 1 pps)
			(nth 1 (parse-partial-sexp (point-min) (point))))))
	   (end (or end
		    (save-excursion
		      (goto-char beg)
		      (or (general-closer-forward-sexp-maybe pos))
			  pos)))

	   (varlist (split-string (buffer-substring-no-properties beg end) "[[:punct:][0-9 \r\n\f\t]" t)))
      (dolist (elt varlist)
	(unless (member elt sorted)
	  (push elt sorted)))
      (setq sorted (nreverse sorted))
      sorted)))

(defun general-close-insert-var-in-listcomprh (pps closer orig &optional sorted splitpos)
  ;; which var of sorted to insert?
  (let* ((sorted sorted)
	 (splitpos (or splitpos (save-excursion (and (skip-chars-backward "^|" (line-beginning-position))(eq (char-before) ?|)(1- (point))))))
	 done vars-at-point candidate)
    (if splitpos
	(progn
	  (setq vars-at-point
		(general-closer-uniq-varlist splitpos (line-end-position) pps))
	  (setq vars-at-point (nreverse vars-at-point))
	  (setq candidate
		(if vars-at-point
		    (cond ((not (or (eq 2 (nth 1 pps))
				    (eq (length vars-at-point) (length sorted))))
			   ;; (eq (member (car vars-at-point) sorted)
			   (nth (length vars-at-point) sorted)))
		  ;; sorted))
		  (cond ((looking-back "<-[ \t]*" (line-beginning-position))
			 "[")
			((looking-back "|[ \t]*" (line-beginning-position))
			 (car sorted))
			(t "<-"))))))

    (when candidate
      (general-close-insert-with-padding-maybe candidate)
      (setq done t))
    ;; (insert closer)
    ;; (setq done t)
    done))

(defun general-close-haskell-twofold-list-cases (pps &optional closer orig)
  (let* ((sorted (save-excursion (general-closer-uniq-varlist nil nil pps)))
	 done)
    ;; [(a*b+a) |a<-[1..3],b<-[4..5]]
    (cond
     (;; after a punct-character
      (and closer general-close-electric-listify-p
	   (eq 1 (car (syntax-after (1- (point))))))
      ;; translate a single char into its successor
      ;; if multi-char symbol, repeat
      (insert (general-close--raise-symbol-maybe (general-close--guess-symbol)))
      (setq done t))
     ((and closer general-close-electric-listify-p
	   (eq 2 (car (syntax-after (1- (point)))))(not (save-excursion (progn (skip-chars-backward "[[:alnum:]]")(skip-chars-backward " \t\r\n\f")(eq (char-before) general-close-list-separator-char)))))
      (insert general-close-list-separator-char)
      (setq done t))
     ((and closer general-close-electric-listify-p
	   (not (eq 1 (car (syntax-after (1- (point)))))))
      ;; works but not needed (?)
      (save-excursion
	(goto-char (nth 1 pps))
	(setq closer (general-close--return-complement-char-maybe (char-after))))
      (insert closer)
      (setq done t))
     ((and closer general-close-electric-listify-p)
      ;; Inside a list-comprehension
      (when (eq 2 (car (syntax-after (1- (point)))))
	(insert general-close-list-separator-char)
	(setq done t)))
     (t (setq done (general-close-insert-var-in-listcomprh pps closer orig sorted))))
    done))

(defun general-close-haskell-close-in-list-comprehension (pps closer orig)
  (let ((splitpos
	 (+ (line-beginning-position)
	    ;; position in substring
	    (string-match "|" (buffer-substring-no-properties (line-beginning-position) (point)))))
	sorted done)
    (cond ((and splitpos (progn (save-excursion (skip-chars-backward " \t\r\n\f")(eq (char-before) ?\]))))
	   (skip-chars-backward " \t\r\n\f")
	   (insert general-close-list-separator-char)
	   (setq done t))
	  (t (skip-chars-backward "^)" (line-beginning-position))
	     (and (eq (char-before) ?\))(forward-char -1))
	     (setq sorted (general-closer-uniq-varlist nil (point) (parse-partial-sexp (line-beginning-position) (point))))
	     (goto-char orig)
	     (setq done
		   (general-close-insert-var-in-listcomprh pps closer orig sorted splitpos))))
    done))

(defun general-close-haskell-electric-splitter-forms (beg &optional closer pps orig)
  (let (done)
    (cond ((and (not closer)
    		(not (save-excursion (progn (skip-chars-backward " \t\r\n\f")(member (char-before) (list ?| general-close-list-separator-char))))))
    	   (cond ((looking-back "<-[ \t]*")
    		  (general-close-insert-with-padding-maybe "[")
    		  (setq done t))
    		 ((save-excursion (skip-chars-backward " \t\r\n\f") (eq (char-before) ?\]))
    		  (insert general-close-list-separator-char)
    		  (setq done t))
    		 ((nth 1 pps)
    		  (skip-chars-backward " \t\r\n\f")
    		  (insert (nth-1-pps-complement-char-maybe pps))
    		  (setq done t))
    		 (t (general-close-insert-with-padding-maybe "<-")
    		    (setq done t))))
	   (t (setq done (general-close-haskell-close-in-list-comprehension pps closer orig))))
    done))

    ;; (cond (splitter
    ;; 	   ;; after pipe fetch a var
    ;; 	   )
    ;; 	  ((and splitter (eq ?\] closer))
    ;; 	   (skip-chars-backward " \t\r\n\f")
    ;; 	   (insert closer)
    ;; 	   (setq done t))
    ;; 	  ;; in list-comprehension
    ;; 	  ;; [(a,b) |
    ;; 	  ;; not just after pipe
    ;; 	  ((and splitter (not closer)
    ;; 		(not (save-excursion (progn (skip-chars-backward " \t\r\n\f")(member (char-before) (list ?| general-close-list-separator-char))))))
    ;; 	   (cond ((looking-back "<-[ \t]*")
    ;; 		  (general-close-insert-with-padding-maybe "[")
    ;; 		  (setq done t))
    ;; 		 ((save-excursion (skip-chars-backward " \t\r\n\f") (eq (char-before) ?\]))
    ;; 		  (insert general-close-list-separator-char)
    ;; 		  (setq done t))
    ;; 		 ((nth 1 pps)
    ;; 		  (skip-chars-backward " \t\r\n\f")
    ;; 		  (insert (nth-1-pps-complement-char-maybe pps))
    ;; 		  (setq done t))
    ;; 		 (t (general-close-insert-with-padding-maybe "<-")
    ;; 		    (setq done t)))
    ;; 	   (setq done t)))



(defun general-close-haskell-electric-close (beg &optional closer pps orig)
  (let* ((splitter (and (eq 1 (count-matches "|" (line-beginning-position) (point)))))
	 (closer (or closer
		     (unless splitter
		       ;; with `|' look for arrows needed
		       (or (and pps (general-close--fetch-delimiter-maybe pps))
			   (general-close--generic-fetch-delimiter-maybe)))))
	 done sorted)
    (cond
     (splitter
      (setq done (general-close-haskell-electric-splitter-forms beg closer pps orig)))
     ((and (eq 2 (nth 0 pps))(not (eq ?\] closer)))
      (setq done (general-close-haskell-twofold-list-cases pps closer orig)))
     ((eq (char-before) general-close-list-separator-char)
      (insert (general-close--raise-symbol-maybe (general-close--guess-symbol)))
      (setq done t))
     ((setq done (general-close--repeat-type-maybe (line-beginning-position) general-close-pre-right-arrow-re)))
     ((and (eq 1 (nth 0 pps)) (eq ?\) closer))
      (insert closer)
      (setq done t))
     ((setq done (general-close--right-arrow-maybe (line-beginning-position) general-close-pre-right-arrow-re closer)))
     (closer
      (insert closer)
      (setq done t))
     ((setq done (general-close--insert-assignment-maybe (line-beginning-position) general-close-pre-assignment-re)))
     ((setq done (general-close--insert-string-concat-op-maybe))))
    done))

(defun general-close-haskell-non-electric (beg &optional closer pps orig)
  (let* ((splitter (and (eq 1 (count-matches "|" (line-beginning-position) (point)))))
	 (closer (or closer
		     (unless splitter
		       ;; with `|' look for arrows needed
		       (or (and pps (general-close--fetch-delimiter-maybe pps))
			   (general-close--generic-fetch-delimiter-maybe)))))
	 done sorted)
    (cond
     ((and (eq 2 (nth 0 pps))(not (eq ?\] closer)))
      (setq done (general-close-haskell-twofold-list-cases pps closer orig)))
     ((and splitter (eq ?\] closer))
      (skip-chars-backward " \t\r\n\f")
      (insert closer)
      (setq done t))
     ;; in list-comprehension
     ;; [(a,b) |
     ;; not just after pipe
     ((and splitter (not closer)
	   (not (save-excursion (progn (skip-chars-backward " \t\r\n\f")(member (char-before) (list ?| general-close-list-separator-char))))))
      (cond ((looking-back "<-[ \t]*")
	     (general-close-insert-with-padding-maybe "[")
	     (setq done t))
	    ((save-excursion (skip-chars-backward " \t\r\n\f") (eq (char-before) ?\]))
	     (insert general-close-list-separator-char)
	     (setq done t))
	    ((nth 1 pps)
	     (skip-chars-backward " \t\r\n\f")
	     (insert (nth-1-pps-complement-char-maybe pps))
	     (setq done t))
	    (t (general-close-insert-with-padding-maybe "<-")
	       (setq done t)))
      (setq done t))
     (splitter
      ;; after pipe fetch a var
      (setq done (general-close-haskell-close-in-list-comprehension pps closer orig)))
     ((setq done (general-close--repeat-type-maybe (line-beginning-position) general-close-pre-right-arrow-re)))
     ((and (eq 1 (nth 0 pps)) (eq ?\) closer))
      (insert closer)
      (setq done t))
     ((setq done (general-close--right-arrow-maybe (line-beginning-position) general-close-pre-right-arrow-re closer)))
     (closer
      (insert closer)
      (setq done t))
     ((setq done (general-close--insert-assignment-maybe (line-beginning-position) general-close-pre-assignment-re)))
     ((setq done (general-close--insert-string-concat-op-maybe))))
    done))

(defun general-close-haskell-close (beg &optional closer pps orig)
  (if general-close-electric-listify-p
      (general-close-haskell-electric-close beg closer pps orig)
    (general-close-haskell-non-electric beg closer pps orig)))

(defun general-close-inferior-sml-close (&optional closer pps orig)
  (cond ((looking-back comint-prompt-regexp)
	 (if general-close--current-source-buffer
	     	 (insert (concat "use \"" (buffer-name general-close--current-source-buffer) "\";"))
	 (insert "use \"\";")
	 (forward-char -2))
	 (setq done t))))

(defun general-close-sml-close (&optional closer pps orig))


;; (let ((frame (window-frame window))
;; (buffer-list frame)

;; (message "%s" (window--side-check)))))
;; Php
(defun general-close--php-check (pps &optional closer)
  (let ((closer (or closer (general-close--fetch-delimiter-maybe pps)))
	(orig (point))
	done)
    (cond ((and (eq closer ?})(general-close-empty-line-p))
	   (insert closer)
	   (setq done t)
	   (indent-according-to-mode))
	  ((eq closer ?})
	   (if (or (eq (char-before) ?\;) (eq (char-before) closer))
	       (progn
		 (newline)
		 (insert closer)
		 (indent-according-to-mode))
	     (insert ";"))
	   (setq done t))
	  ((eq closer ?\))
	   (insert closer)
	   (setq done t))
	  ;; after asignement
	  ((eq (char-before) ?\))
	   (backward-list)
	   (skip-chars-backward "^ \t\r\n\f")
	   (skip-chars-backward " \t")
	   (when (eq (char-before) ?=)
	     (goto-char orig)
	     (insert ";")
	     (setq done t))))
    (unless done (goto-char orig))
    done))

(defvar general-close-haskell-listcomprh-vars nil)

(defvar general-close-haskell-listcomprh-startpos nil)
(defvar general-close-haskell-listcomprh-counter nil)

(defun general-close-set-listcomprh-update (orig pps)
  (let (pos varlist)
    (setq general-close-haskell-listcomprh-counter 0)
    (cond ((save-excursion (and (nth 0 pps) (goto-char (nth 1 pps))(eq (char-after) ?\[))(setq pos (point)))
	   ;; (nth 1 pps) (save-excursion (goto-char (nth 2 pps))(eq (char-after) ?\()))
	   (goto-char pos)
	   (while (re-search-forward haskell-var-re orig t 1)
	     ;; (unless (member (match-string-no-properties 0) varlist)
	     (cl-pushnew (match-string-no-properties 0) varlist))
	   (goto-char orig)
	   (nreverse varlist)))))

(defun general-close--semicolon-separator-modes-dispatch (orig closer pps)
  (let ((closer (or closer (and (nth 1 pps) (nth-1-pps-complement-char-maybe pps))))
	done erg)
    (cond ((and closer (eq closer ?\))(progn (save-excursion (skip-chars-backward " \t\r\n\f")(looking-back general-close-command-operator-chars (line-beginning-position)))))
	   (setq erg (car (general-closer-uniq-varlist (nth 1 pps) orig)))
	   (cond ((and (stringp erg)(< 1 (length erg)))
		  (general-close-insert-with-padding-maybe erg)
		  (setq done t))
		 ((and (stringp erg)(eq 1 (length erg)))
		  (general-close-insert-with-padding-maybe
		   (general-close--raise-symbol-maybe (string-to-char erg)))
		  (setq done t))))
	  ((progn (save-excursion (beginning-of-line) (looking-at general-close-pre-assignment-re)))
	   (general-close-insert-with-padding-maybe "=")
	   (setq done t))
	  (t (setq general-close-command-separator-char 59)
	     (setq done (general-close--handle-separator-modes orig closer))))
    done))

;; (defun general-close--modes (beg pps orig &optional closer force)
;; (let (done)
;; (cond
;; ((member major-mode (list 'php-mode 'js-mode 'web-mode))
;; (setq done (general-close--php-check pps closer)))
;; ((eq major-mode 'python-mode)
;; (setq done (general-close-python-close closer pps force)))
;; ((eq major-mode 'emacs-lisp-mode)
;; (setq done (general-close-emacs-lisp-close closer pps force)))
;; ((eq major-mode 'ruby-mode)
;; (setq done (general-close-ruby-close closer pps)))
;; ((member major-mode general-close--ml-modes)
;; (setq done (general-close-ml)))
;; ((member major-mode (list 'haskell-interactive-mode 'inferior-haskell-mode 'haskell-mode))
;; (setq done (general-close-haskell-close beg closer pps orig))))
;; done))

(defun general-close--modes (beg pps orig &optional closer force)
  (let (done)
    (pcase major-mode
      (`inferior-sml-mode
       (setq done (general-close-inferior-sml-close closer pps force)))
      (`sml-mode
      (setq done (general-close-sml-close closer pps force)))
      (`python-mode
       (setq done (general-close-python-close closer pps force)))
      (`emacs-lisp-mode
       (setq done (general-close-emacs-lisp-close closer pps force)))
      (`ruby-mode
       (setq done (general-close-ruby-close closer pps)))
      (_
       (cond
	((member major-mode general-close--ml-modes)
	 (setq done (general-close-ml)))
	((member major-mode (list 'php-mode 'js-mode 'web-mode))
	 (setq done (general-close--php-check pps closer)))
	((member major-mode (list 'haskell-interactive-mode 'inferior-haskell-mode 'haskell-mode))
	 (setq done (general-close-haskell-close beg closer pps orig))))
       done))))

(provide 'general-close-modes)
;;; general-close-modes.el ends here
