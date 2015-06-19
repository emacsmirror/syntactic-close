;;; general-close-modes.el --- mode-specific functions  -*- lexical-binding: t; -*-

;; Copyright (C) 2015  Andreas Röhler

;; Author: Andreas Röhler <andreas.roehler@online.de>
;; Keywords: lisp

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

(defun gen-python-close (&optional arg)
  "Equivalent to py-dedent"
  (interactive "p*")
  (when (eolp)
    (ignore-errors (newline-and-indent)))
  (if (functionp 'py-dedent)
      (py-dedent 1)
    (python-indent-dedent-line-backspace 1)))

(defun gen--ruby-fetch-delimiter-maybe ()
  (save-excursion
    (and (< 0 (abs (skip-syntax-backward "\\sw")))
	 (eq 1 (car (syntax-after (1- (point)))))
	 (char-before))))

(defun gen--ruby-insert-end ()
  (unless (or (looking-back ";[ \t]*"))
    (unless (and (bolp)(eolp))
      (newline))
    (unless (looking-back "^[^ \t]*\\_<end")
      (insert "end")
      (save-excursion
	(back-to-indentation)
	(indent-according-to-mode)))))

(defun gen-ruby-close (&optional arg)
  "Equivalent to py-dedent"
  (interactive "*")
  (let ((orig (point))
	(erg (gen--ruby-fetch-delimiter-maybe)))
    (if erg
	(insert (char-to-string erg))
      (gen--ruby-insert-end))))

(provide 'general-close-modes)
;;; general-close-modes.el ends here
