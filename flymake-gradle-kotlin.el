;;; flymake-gradle-kotlin.el --- A flymake handler gradle kotlin projects -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Jürgen Hötzel

;; Author: Jürgen Hötzel <juergen@hoetzel.info>
;; URL: http://github.com/juergenhoetzel/flymake-gradle-kotlin
;; Maintainer: Jürgen Hötzel
;; Keywords: tools, languages
;; Package-Requires: ((flymake-quickdef "1.0.0") (emacs "26.1"))
;; Version: 1.0.0

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
;; Just a quick hack to check for kotlin errors in gradle projects

;;; Code:

(require 'flymake-quickdef)

(defgroup flymake-gradle-kotlin nil "flymake-gradle-kotlin preferences." :group 'flymake-gradle-kotlin)

(defcustom flymake-gradle-kotlin-executable "gradle"
  "The gradle executable to use for syntax checking."
  :safe #'stringp
  :type 'string
  :group 'flymake-gradle-kotlin)

(flymake-quickdef-backend flymake-gradle-kotlin-backend
  :pre-let ((gradle-kotlin-exec (executable-find flymake-gradle-kotlin-executable))
	    (project-directory (expand-file-name (locate-dominating-file default-directory "build.gradle"))))
  :pre-check (unless gradle-kotlin-exec (error "Not found gradle-kotlin on PATH"))
  :write-type 'file
  :proc-form `(,gradle-kotlin-exec  "-p" ,project-directory "compileKotlin")
  :search-regexp "^\\(.\\): \\([^:]*\\): (\\([0-9]+\\), \\([0-9]+\\)): \\(.*\\)$"
  :prep-diagnostic
  (let* ((lnum (string-to-number (match-string 3)))
	 (col (string-to-number (match-string 4)))
	 (severity (match-string 1))
	 (msg (match-string 5))
	 (file (match-string 2))
	 (pos (flymake-diag-region fmqd-source lnum col))
	 (beg (car pos))
	 (end (cdr pos))
	 (type (cond
		((string= severity "e") :error)
		((string= severity "w") :warning)
		(t :note))))
    (list fmqd-source beg end type msg)))

;;;###autoload
(defun flymake-gradle-kotlin-setup ()
  "Enable flymake backend."
  (interactive)
  (add-hook 'flymake-diagnostic-functions
	    #'flymake-gradle-kotlin-backend nil t))

(provide 'flymake-gradle-kotlin)
;;; flymake-gradle-kotlin.el ends here

;; Local Variables:
;; fill-column: 80
;; End:
