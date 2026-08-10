;;; test.el --- Test ntfy library                    -*- lexical-binding: t; -*-

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

;;; Commentary:

;;

;;; Code:


(load (expand-file-name "../ntfy.el"))

(setopt ntfy-server "http://ntfy.domain.localhost"
        ntfy-topic "macbook"
        ntfy-header "From Emacs"
        ntfy-priority 3
        ntfy-tags '("purple_circle" "loudspeaker"))

(ntfy-message "test")

(ntfy-message-with-title-and-tags "Title" "Message")

;; Test Emoji Selector
;;
;; Removes the caching to create a clean slate for testing
(progn
  ;; (profiler-start 'cpu+mem)
  (setq ntfy--emoji-json-cache nil
        ntfy--emoji-hashmap-cache nil)
  (ntfy--interactive-emoji-selector)
  ;; (profiler-stop)
  )

(memory-report-object-size ntfy--emoji-json-cache)  ;; 975461 (#o3561145, #xee265)
(memory-report-object-size ntfy--emoji-hashmap-cache)  ;; 254923 (#o761713, #x3e3cb)

(profiler-report)

;;; test.el ends here
