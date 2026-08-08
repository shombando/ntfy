;;; ntfy-compilation.el --- ntfy outcome of compilations  -*- lexical-binding: t; -*-

;; Copyright (C) 2026  ethan

;; Author: ethan <ethan@thinkpad>
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
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Code:

(defun point-beginning-of-last-line ()
  "Get the position of the beginning of the last line"
  (goto-char (point-max))
  (if (bolp)
      (backward-char 1))
  (beginning-of-line)
  (point))

(defun ntfy-compilation-finished (buf str)
  ""
  (with-current-buffer buf
    (let ((first-line (buffer-substring (pos-bol 2)
                                        (pos-eol 2)))
          (last-line (buffer-substring (point-beginning-of-last-line)
                                       (point-max))))

      (ntfy--publish-message (format "%s\n%s" first-line last-line)
                             (format "Compilation %s" (replace-regexp-in-string "\n" "" str))
                             '("gear")))))

(define-minor-mode ntfy-compilation
  "Global ntfy compilation minor mode."
  :global t
  :init-value nil
  :lighter " ntfy"

  (if ntfy-compilation
      (add-to-list 'compilation-finish-functions 'ntfy-compilation-finished)
    (setq compilation-finish-functions (remove 'ntfy-compilation-finished compilation-finish-functions))))

(provide 'ntfy-compilation)
;;; ntfy-compilation.el ends here
