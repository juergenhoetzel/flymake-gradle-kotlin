;;; flymake-gradle-kotlin.el --- A flymake handler gradle kotlin projects -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Jürgen Hötzel

;; Author: Jürgen Hötzel <juergen@hoetzel.info>
;; URL: http://github.com/juergenhoetzel/flymake-gradle-kotlin
;; Maintainer: Jürgen Hötzel
;; Keywords: tools, languages
;; Package-Requires: ((emacs "26.1"))
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


(defgroup flymake-gradle-kotlin nil "flymake-gradle-kotlin preferences." :group 'flymake-gradle-kotlin)

(defcustom flymake-gradle-kotlin-executable "gradle"
  "The gradle executable to use for syntax checking."
  :safe #'stringp
  :type 'string
  :group 'flymake-gradle-kotlin)

(defvar-local flymake-gradle-kotlin--proc nil
  "A buffer-local variable handling the gradle process for flymake.")

(defconst flymake-gradle-kotlin--error-regexp  "^\\(.\\): \\([^:]*\\): (\\([0-9]+\\), \\([0-9]+\\)): \\(.*\\)$")

(defun flymake-gradle-kotlin-backend (report-fn &rest _args)
  "Run flymake-gradle-kotlin checker.

REPORT-FN is flymake's callback function."
  (let* ((gradle-kotlin-exec (executable-find flymake-gradle-kotlin-executable))
	 (project-directory (expand-file-name
			     (or (locate-dominating-file default-directory "build.gradle")
				 (locate-dominating-file default-directory "build.gradle.kts"))))
	 (source (current-buffer))
	 diags)
    (unless gradle-kotlin-exec (error "Not found gradle-kotlin on PATH"))
    (unless project-directory (error "Not a gradle project"))
    (when (process-live-p flymake-gradle-kotlin--proc)
      (kill-process flymake-gradle-kotlin--proc))
    (if (not (buffer-modified-p))
	(save-restriction
	  (widen)
	  (setq
	   flymake-gradle-kotlin--proc
	   (make-process
            :name "flymake-gradle-kotlin" :noquery t :connection-type 'pipe
            :buffer (generate-new-buffer " *flymake-gradle-kotlin*")
            :command `(,gradle-kotlin-exec  "-p" ,project-directory "compileKotlin")
            :sentinel (lambda (proc _event)
			(when (eq 'exit (process-status proc))
			  (with-current-buffer (process-buffer proc)
			    (goto-char (point-min))
			    (while (not (eobp))
			      (when (looking-at flymake-gradle-kotlin--error-regexp)
				(let* ((lnum (string-to-number (match-string 3)))
				       (col (string-to-number (match-string 4)))
				       (severity (match-string 1))
				       (msg (match-string 5))
				       (file (match-string 2))
				       (pos (flymake-diag-region source lnum col))
				       (type (cond
					      ((string= severity "e") :error)
					      ((string= severity "w") :warning)
					      (t :note))))
				  (when (equal file (buffer-file-name source))
				    (push (flymake-make-diagnostic source (car pos) (cdr pos) type msg)
					  diags))))
			      (forward-line 1)))
			  (funcall report-fn diags)
			  (kill-buffer (process-buffer proc)))))))
      (funcall report-fn nil)
      (flymake-log :warning "Can't flycheck unsaved kotlin files"))))


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
