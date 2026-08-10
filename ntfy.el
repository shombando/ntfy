;;; ntfy.el --- publish notification using ntfy.sh   -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Shom

;; Author: Shom Bandopadhaya <shom@bandopadhaya.com>
;; Version 0.3.0
;; Keywords: lisp
;; Package-Requires: ((emacs "27.2"))
;; SPDX-License-Identifier: MIT

;; This file is not part of GNU Emacs.

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
;; Interface to use the https://ntfy.sh service (or self-hosted version) to send
;; notification from Emacs.

;; TODO: Add a list of all the possible tags that result in emojis in the header
;; TODO: The doc strings need to be done.
;; TODO: Readme needs to be crafted

;; New features to add;
;; TODO: Using dired marked, make a ntfy to send the files?.

;;; Code:
(require 'url)  ; Built-in

;;;--- Variables
(defgroup ntfy ()
  "Notification publishing in Emacs")

(defcustom ntfy-server nil
  "Set server for ntfy.el to send notifications."
  :group 'ntfy
  :type 'string)

(defcustom ntfy-topic nil
  "Set ntfy topic/channel to send notifications."
  :group 'ntfy
  :type 'string)

(defcustom ntfy-title "Emacs Notification"
  "Set the default title of the message for the notification."
  :group 'ntfy
  :type 'string)

(defcustom ntfy-tags '("purple_circle" "loudspeaker")
  "Set the emoji that'll appear before the header message.
Use comma separated string, see
https://ntfy.sh/docs/publish/#tags-emojis for details."
  :group 'ntfy
  :type '(repeat string))

(defcustom ntfy-priority 3
  "Set the message priority for the notification. This ranges from Minimum (1) to Urgent/Maximum (5)"
  :group 'ntfy
  :type '(choice (const :tag "urgent/max" 5)
                 (const :tag "high" 4)
                 (const :tag "default" 3)
                 (const :tag "low" 2)
                 (const :tag "min" 1)))

(defvar ntfy--emoji-json-cache nil
  "Cache for the ntfy emoji JSON object.")

(defvar ntfy--emoji-json-url "https://raw.githubusercontent.com/binwiederhier/ntfy/refs/heads/main/scripts/emoji.json"
  "URL the ntfy emoji JSON list.")

(defvar ntfy--emoji-hashmap-cache nil
  "Cache of mapping emoji aliases to Unicode characters.")

;;;###autoload
(defun ntfy-message (message)
  "A simple way of sending a notification message"
  (interactive "sMessage: ")
  (ntfy--publish-message message))

;;;###autoload
(defun ntfy-message-with-title (title message)
  "A simple way of sending a notification message with a title"
  (interactive "sTitle: \nsMessage: ")
  (ntfy--publish-message message title))

;;;###autoload
(defun ntfy-message-with-title-and-tags (title message)
  "A simple way of sending a notification message with a title and tag(s)"
  (interactive "sTitle: \nsMessage: ")
  (let ((tags (ntfy--interactive-emoji-selector)))
    (ntfy--publish-message message title tags)))

;;;###autoload
(defun ntfy-change-tags ()
  "Update the tags for ntfy messages interactively.

This allows you to select emojis that are valid to show in ntfy messages
and update the variable that holds them."
  (interactive)
  (let ((emojis (ntfy--interactive-emoji-selector)))
    (setq ntfy-tags (append emojis nil))))


;;;--- Internal Functions
(defun ntfy--get-emoji-json (&optional force-refresh)
  "Return the parsed ntfy emoji JSON structure, a vector of plists.

Pass FORCE-REFRESH as t to bypass the cache."
  (or (and (not force-refresh)
           ntfy--emoji-json-cache)
      (let ((url-buf (url-retrieve-synchronously ntfy--emoji-json-url)))
        (when url-buf
          (with-current-buffer url-buf
            (goto-char (point-min))
            (when (re-search-forward "\r?\n\r?\n" nil t)
              (setq ntfy--emoji-json-cache (json-parse-buffer
                                            :object-type 'plist))))
          (kill-buffer url-buf))))
  ntfy--emoji-json-cache)

(defun ntfy--create-emoji-hashmap ()
  "Create and cache a hashmap mapping emoji characters to its first alias."
  (setq ntfy--emoji-hashmap-cache (make-hash-table :test #'equal))
  (mapcar (lambda (elt)
            (puthash (plist-get elt :emoji)
                     (plist-get elt :aliases)
                     ntfy--emoji-hashmap-cache))
          (ntfy--get-emoji-json)))

(defun ntfy--interactive-emoji-selector ()
  "Interactively select multiple emojis and return them as a vector of
comma-separated tags."
  (interactive)
  ;; Create the hash if it not already created. This is cached.
  (unless ntfy--emoji-hashmap-cache
    (ntfy--create-emoji-hashmap))
  (let ((continue t)
        (emojis-selected nil))
    (while continue
      (push (elt (gethash (car (emoji--read-emoji))
                          ntfy--emoji-hashmap-cache)
                 0)
            emojis-selected)
      (setq continue (y-or-n-p "Add more Emojis?"))) ;; n -> nil quits loop
    (reverse emojis-selected)))

(defun ntfy--attach (attachment)
  "Check the options for the :attach property, and check if it is a local
or remote file.

NOTE: Currently, local files are not accepted as part of a limitation of
’publish as json’"
  (let* ((type (url-type (url-generic-parse-url attachment))))
    (cond ((member type '("http" "https")) attachment) ;; URL
          ((file-name-absolute-p attachment)  ; Local File
           (encode-coding-string (with-temp-buffer
                                   (insert-file-contents
                                    "Downloads/cute-cat.jpg")
                                   (buffer-string))
                                 'utf-8)))))

(defun ntfy--check-inputs (message &optional header tags priority)
  "Validates HEADER, MESSAGE, TAGS and Priority before sending."
  ;; TODO: Message checks?

  ;; Header cannot have a new line in it.
  (when (string-match-p "\n" header)
    (user-error "Notification header cannot contain a newline"))

  ;; Check the priority, needs to be from 1 to 5 inclusive.
  (if (or (> priority 5) (< priority 1))
      (user-error "Notification priority cannot be greater than 5 or less than 1"))

  ;; Tags are particular, with what is allowed.
  ;; Regex will only match if every character is one of the following;
  ;;  - Any lowercase letter a-z OR
  ;;  - Any lowercase letter, a comma or underscore, followed by any lowercase letter
  (dolist (tag tags)
    (message tag)
    ;; (if (string-match-p "^\\([a-z]\\|[a-z][,_][a-z]\\)+$" tag)
    (unless (string-match-p "^[a-z0-9\+\-_,]+$" tag)
      (user-error "Notification Tags cannot contain anything other than the lower case characters a-z, a comma, or an underscore"))))

(defun ntfy--publish-message (message &optional title tags priority)
  "Publish message to server with Emacs Lib URL with MESSAGE.
  Configured HEADER and TAGS are used unless specified."
  ;; Check the inputs.
  (ntfy--check-inputs message
                      (or title ntfy-title "header")
                      (or tags ntfy-tags "tags")
                      (or priority ntfy-priority 3))

  ;; If no error is thrown, send the message.
  (let ((url-request-method "POST")
        (url-request-data message)
        (url-request-extra-headers `(("Title" . ,(or title ntfy-header))
                                     ("Tags" .  ,(mapconcat 'identity (or tags ntfy-tags) ","))
                                     ("Priority" . ,(int-to-string (or priority ntfy-priority))))))
    (url-retrieve-synchronously (format "%s/%s" ntfy-server ntfy-topic))))

(provide 'ntfy)
;;; ntfy.el ends here
